# Chat Session Persistence — Design

**Date:** 2026-08-03
**Feature:** ChatBot 대화(bubbles / server context) 디스크 지속화 + 페이지네이션

## 1. 목적

현재 `ChatBotBottomSheetViewModel`은 시트를 닫을 때 세션 상태(`summary`, `messages`, `bubbles`)를 잃는다. 사용자가 챗봇 시트를 다시 열면 빈 대화로 시작한다.

이 스펙은 대화 상태를 **디바이스 단위 CoreData**에 지속 저장해 앱 재실행 후에도 대화가 복원되도록 하고, 대화가 길어져도 초기 로드 부하가 없도록 **최신 20개만 로드 + 위로 스크롤 시 20개씩 추가 로드**하는 페이지네이션을 제공한다.

## 2. 요구사항

### 저장 대상
- `bubbles[]` — 화면 표시용 (append-only)
- `messages[]` — 서버 컨텍스트 (매 `.done` 시 서버 리턴으로 replace)
- `summary` — 서버 컨텍스트 (매 `.done` 시 서버 리턴으로 replace)

### 수명
- 디스크(CoreData). 앱 kill 후 재실행에도 유지.
- 로그인/로그아웃과 무관 — 디바이스 단위.

### 상한
- 없음. 서버가 `summary`로 압축한다. 저장/전송 정책은 별개(전송은 서버 원본 그대로).

### 리셋 UI
- 없음. 자동 보존만.

### 페이지네이션
- 초기 로드: **최신 20개**
- 트리거: tableView 최상단 100pt 이내 스크롤 시 자동
- 페이지 크기: 20
- 스크롤 위치는 prepend 후 보존

## 3. 데이터 스키마 (CoreData)

기존 `PersistenceController` 확장, 신규 3 엔티티 추가. Lightweight migration.

### ChatSessionEntity (singleton, 1 row)
| 속성 | 타입 |
|---|---|
| `summary` | String? |

### ChatBubbleEntity (N rows)
| 속성 | 타입 | 비고 |
|---|---|---|
| `id` | UUID | primary |
| `kindRaw` | String | `"user" / "assistant" / "error"` (pending은 저장 안 함) |
| `text` | String | 버블 본문 |
| `placeIdMapJson` | String? | assistant 전용, `[String:[String]]` JSON encoded |
| `recommendedQuestionsJson` | String? | assistant 전용, `[String]` JSON encoded |
| `order` | Int64 | monotonically increasing, 정렬·페이지 커서 |

### ChatMessageEntity (N rows)
| 속성 | 타입 |
|---|---|
| `roleRaw` | String (`"user"/"assistant"`) |
| `content` | String |
| `order` | Int64 |

**대안 검토**
- `placeIdMap`/`recommendedQuestions`를 별도 `AssistantMetaEntity`로 정규화 → 조회 요구 없고 optional 관계 관리 오버헤드만 발생. JSON 문자열이 심플.
- `summary` UserDefaults 저장 → 두 저장소로 분산되어 마이그레이션/리셋 일관성 저하. singleton 엔티티가 통일감 있음.

## 4. 저장소 추상화 (Store)

### 프로토콜

```swift
protocol ChatHistoryStoreProtocol {
    // Context (서버 컨텍스트)
    func loadSummary() -> String?
    func loadMessages() -> [ChatMessage]
    func updateContext(summary: String?, messages: [ChatMessage])

    // Bubbles (페이지 단위)
    func loadBubbles(beforeOrder: Int64?, limit: Int) -> ChatBubblePage
    func appendBubble(_ bubble: ChatBubble)

    // 유틸
    func clear()
}

struct ChatBubblePage {
    let bubbles: [ChatBubble]     // 오름차순, 최대 limit개
    let hasMore: Bool             // 더 오래된 게 있는지
}
```

### CoreData 구현 요점

`CoreDataChatHistoryStore`
- `loadBubbles(beforeOrder: nil, limit: 20)`:
  - fetch: `sortDescriptors=[order DESC], fetchLimit=21`
  - `hasMore = fetched.count > 20`, `bubbles = fetched.prefix(20).reversed()`
- `loadBubbles(beforeOrder: X, limit: 20)`:
  - predicate: `order < X`, 같은 sort/limit 규칙
- `appendBubble(_ bubble)`:
  - 새 order = 현재 max(order) + 1 (fetch 시 sortDescriptor `order DESC`, fetchLimit=1로 조회). 규모가 작아 인덱스 없이도 문제없음.
- `updateContext(summary:messages:)`:
  - session singleton fetch(없으면 생성) → summary 갱신
  - 기존 ChatMessageEntity 전부 delete → 새 messages insert (order = 0..N-1)
  - 하나의 `save()`로 원자 커밋

### DI 배치
- `DIContainer`에 `lazy var chatHistoryStore: ChatHistoryStoreProtocol = CoreDataChatHistoryStore(controller: persistenceController)`
- `VMFactory.makeChatBotBottomSheetVM()`에서 store를 VM 생성자에 주입

## 5. VM 통합

### 생성자

```swift
init(usecase: AgentUsecaseProtocol, historyStore: ChatHistoryStoreProtocol) {
    self.usecase = usecase
    self.historyStore = historyStore
    let firstPage = historyStore.loadBubbles(beforeOrder: nil, limit: 20)
    self.persistedBubbles = firstPage.bubbles
    self.oldestLoadedOrder = firstPage.bubbles.first?.order
    self.hasMoreOlder = firstPage.hasMore
    self.session = ChatSessionState(
        summary: historyStore.loadSummary(),
        messages: historyStore.loadMessages()
    )
    self.bubblesRelay = BehaviorRelay<[ChatBubble]>(value: firstPage.bubbles)
    self.remainingRelay = BehaviorRelay<Int>(value: usecase.remainingCount)
}
```

### 표시 규칙: pending은 store 밖

- 내부 상태: `persistedBubbles: [ChatBubble]`, `pendingBubble: ChatBubble?`
- 방출: `persistedBubbles + (pendingBubble.map{[$0]} ?? [])`
- pending은 **저장하지 않음**. VM 로컬 상태로만 유지.

### 새로운 I/O

```swift
struct Input {
    // 기존
    let viewDidLoad: PublishRelay<Void>
    let sendTapped: PublishRelay<String>
    let chipTapped: PublishRelay<String>
    let placeSelected: PublishRelay<String>
    let retryTapped: PublishRelay<Void>
    // 신규
    let loadMoreTriggered: PublishRelay<Void>
}

struct Output {
    // 기존
    let bubbles: Driver<[ChatBubble]>
    let progress: Driver<ChatProgress>
    let remainingCount: Driver<Int>
    let inputEnabled: Driver<Bool>
    let fillInputText: Signal<String>
    let routeToPlaceDetail: Signal<String>
    let showLimitAlert: Signal<Void>
    // 신규
    let isLoadingMore: Driver<Bool>
    let bubblesChange: Signal<BubblesChange>
}

enum BubblesChange {
    case initial                    // 초기 로드 → scrollToBottom
    case appended                   // 새 메시지 → scrollToBottom
    case prepended(count: Int)      // load-more → 스크롤 위치 보존
}
```

### 쓰기 트리거

| 이벤트 | 호출 |
|---|---|
| user 버블 append | `persistedBubbles.append` + `store.appendBubble` + emit `.appended` |
| assistant `.done` | `persistedBubbles.append` + `store.appendBubble` + `store.updateContext(summary, messages)` + `session` 갱신 + emit `.appended` |
| error 버블 append (`.failure` 또는 catch) | `persistedBubbles.append` + `store.appendBubble` + emit `.appended` |
| pending 생성/업데이트/제거 | store 호출 없음. `pendingBubble` 상태만 변경 후 emit (변경 종류는 `.appended`로 취급하되 store write X) |

**주의**: pending 관련 emit은 `.appended` 재활용 (스크롤 정책 관점에서 동일 — 새 것이 아래에 추가되면 스크롤 다운). store write와 emit이 분리되어야 함.

### loadMore 처리

```swift
input.loadMoreTriggered
    .subscribe(onNext: { [weak self] in self?.performLoadMore() })
    .disposed(by: disposeBag)

private func performLoadMore() {
    guard hasMoreOlder, !isLoadingMore, let cursor = oldestLoadedOrder else { return }
    isLoadingMore = true
    isLoadingMoreRelay.accept(true)

    let page = historyStore.loadBubbles(beforeOrder: cursor, limit: 20)
    persistedBubbles = page.bubbles + persistedBubbles
    oldestLoadedOrder = page.bubbles.first?.order ?? oldestLoadedOrder
    hasMoreOlder = page.hasMore

    isLoadingMore = false
    isLoadingMoreRelay.accept(false)
    emitBubbles(change: .prepended(count: page.bubbles.count))
}
```

## 6. VC 통합

### 스크롤 트리거

```swift
private let loadMoreRelay = PublishRelay<Void>()

func scrollViewDidScroll(_ scrollView: UIScrollView) {
    setScrollToBottomButtonVisible(!isTableAtBottom())
    if scrollView.contentOffset.y < 100 { loadMoreRelay.accept(()) }
}
```
- VM에서 `hasMoreOlder`/`isLoadingMore` guard 처리하므로 매 프레임 accept 안전.

### 상단 로딩 인디케이터

- `tableView.tableHeaderView = UIActivityIndicatorView`(높이 44). `isLoadingMore` Driver 바인딩으로 start/stop + isHidden 토글.

### 스크롤 위치 보존

```swift
output.bubblesChange
    .emit(onNext: { [weak self] change in
        guard let self = self else { return }
        switch change {
        case .initial, .appended:
            self.tableView.reloadData()
            self.scrollToBottom()
        case .prepended(let count):
            let before = self.tableView.contentSize.height
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            let after = self.tableView.contentSize.height
            let delta = after - before
            self.tableView.setContentOffset(
                CGPoint(x: 0, y: self.tableView.contentOffset.y + delta),
                animated: false
            )
        }
    })
    .disposed(by: disposeBag)
```

- 필요시 `performBatchUpdates(insertRows(0..<count))`로 최적화 가능. 우선 단순 reload + offset 보정.

## 7. 마이그레이션

- 신규 3 엔티티만 추가, 기존 엔티티 변경 없음 → `Lightweight Migration`.
- `.xcdatamodeld`에 새 모델 버전(v2) 추가하고 `NSPersistentContainer`의 자동 마이그레이션 옵션(`shouldMigrateStoreAutomatically`, `shouldInferMappingModelAutomatically` 기본값 true) 활용.
- 기존 설치 사용자: 신규 엔티티는 빈 상태 → snapshot empty → 기존과 동일한 UX.

## 8. 엣지케이스

| 케이스 | 처리 |
|---|---|
| 저장 중 앱 강제 종료 | CoreData `save()`는 원자적. 다음 실행 시 마지막 커밋 상태로 복구 |
| pending 도중 종료 | pending은 저장 안 됨 → 재실행 시 사용자 버블만 남고 assistant 응답 없음. 사용자가 재질문 필요 (허용 가능한 손실) |
| load-more 중 새 메시지 도착 | append(tail)와 prepend(head)는 서로 별개 경로. persistedBubbles 배열 조작만 동시성 없음 (모두 main queue) |
| 최상단 도달 후 계속 스크롤 | `hasMoreOlder=false` guard로 no-op |
| 저장된 bubbles < 20개 | 초기 페이지에 다 들어옴, `hasMoreOlder=false`. load-more no-op |
| 첫 실행(빈 히스토리) | page.bubbles = [], summary=nil, messages=[]. 기존 empty state UX |
| CoreData decode/schema 파손 | Store 내부 catch → empty 반환 + os_log. 앱 크래시 X |

## 9. 스레딩

- 모든 store 호출은 VM 안 `MainActor.run` 컨텍스트에서만 발생 → CoreData `viewContext`(main queue) 그대로 사용.
- 히스토리 규모 작아 백그라운드 컨텍스트 오버킬. 실측 후 필요시 background context 도입 검토(현 스펙 아님).

## 10. 범위에서 제외 (YAGNI)

- 리셋 UI
- per-user 저장 분리
- 상한/eviction
- 대화 검색·필터
- 여러 대화방(threads)
- pending 상태 재개
- iCloud 동기화

## 11. 성공 기준

1. 챗봇 시트를 열어 대화 몇 번 → 시트 닫고 다시 열기 → 이전 버블 그대로 보임
2. 앱 완전 종료 후 재실행 → 챗봇 시트 열기 → 이전 대화 복원
3. 재질문 시 `AgentStreamRequest`에 이전 `summary`/`messages`가 담겨 전송
4. 저장된 대화가 20개 초과 시 초기엔 최신 20개만 보이고, 위로 스크롤 시 자동으로 20개씩 추가 로드
5. load-more 후에도 사용자 스크롤 위치 유지 (새로 prepend된 콘텐츠만큼 offset 보정)
6. 저장/복원 실패해도 앱 크래시 X, 최악의 경우 빈 채팅으로 시작
7. 기존 챗봇 UX(스트리밍/pending/키보드/place 이동) 회귀 없음
8. 단위 테스트: VM + Mock store 4개 시나리오(초기 로드, append, done 시 context 갱신, load-more), Store CRUD 통합 테스트

## 12. 변경 파일

**신규**
- `Domain/Protocols/ChatHistoryStoreProtocol.swift`
- `Data/Stores/CoreDataChatHistoryStore.swift`
- `Shared/ChatBubblePage.swift`
- `Shared/BubblesChange.swift`
- `.xcdatamodeld` v2 (ChatSessionEntity, ChatBubbleEntity, ChatMessageEntity)

**수정**
- `DI/Containers/DIContainer.swift` — store 등록
- `DI/Factories/VMFactory.swift` — store 주입
- `Presentation/ViewModels/ChatBotBottomSheetViewModel.swift` — store 통합, pending 분리, loadMore, bubblesChange emit
- `Presentation/ViewControllers/ChatBotBottomSheetViewController.swift` — 스크롤 트리거, tableHeaderView 인디케이터, prepend offset 보정

**테스트**
- `BibleAtlasTests/Stores/MockChatHistoryStore.swift` (신규)
- `BibleAtlasTests/Stores/CoreDataChatHistoryStoreTests.swift` (신규)
- `BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift` (보강)
