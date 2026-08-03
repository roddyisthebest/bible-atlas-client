# Chat Session Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ChatBot 대화(bubbles + summary + messages)를 CoreData에 지속 저장하고, 시트 열 때 최신 20개만 로드하고 위로 스크롤 시 20개씩 페이지네이션으로 추가 로드한다.

**Architecture:** 3개 신규 CoreData 엔티티(`ChatSessionEntity`, `ChatBubbleEntity`, `ChatMessageEntity`)에 세션 상태를 저장한다. `ChatHistoryStoreProtocol`로 접근을 추상화하고 `CoreDataChatHistoryStore`가 구현한다. `ChatBotBottomSheetViewModel`이 store를 주입받아 초기 스냅샷 로드, 완결 버블마다 write, 위 방향 페이지네이션 fetch를 처리한다. VC는 스크롤 트리거와 prepend 후 오프셋 보정을 담당한다.

**Tech Stack:** Swift, UIKit, CoreData, RxSwift, RxRelay, SnapKit, XCTest

**Spec:** `docs/superpowers/specs/2026-08-03-chat-session-persistence-design.md`

---

## File Structure

**신규 파일**
- `BibleAtlas/Shared/ChatHistorySnapshot.swift` — 서머리+메시지+초기 페이지를 담는 값 타입
- `BibleAtlas/Shared/ChatBubblePage.swift` — 페이지 fetch 결과 (bubbles, hasMore)
- `BibleAtlas/Shared/BubblesChange.swift` — .initial/.appended/.prepended 힌트 enum
- `BibleAtlas/Domain/Protocols/ChatHistoryStoreProtocol.swift` — store 인터페이스
- `BibleAtlas/Data/Stores/CoreDataChatHistoryStore.swift` — CoreData 구현
- `BibleAtlas/BibleAtlas.xcdatamodeld/BibleAtlas 2.xcdatamodel/contents` — v2 모델 (3 신규 엔티티)
- `BibleAtlas/BibleAtlas.xcdatamodeld/.xccurrentVersion` — 현재 버전 v2 지정
- `BibleAtlasTests/Mocks/MockChatHistoryStore.swift` — 테스트 더블
- `BibleAtlasTests/Stores/CoreDataChatHistoryStoreTests.swift` — CoreData CRUD 통합 테스트

**수정 파일**
- `BibleAtlas/Presentation/ViewModels/ChatBotBottomSheetViewModel.swift` — 생성자에 store 추가, 스냅샷 로드, persistedBubbles/pendingBubble 분리, loadMore, bubblesChange emit
- `BibleAtlas/Presentation/ViewControllers/ChatBotBottomSheetViewController.swift` — loadMoreRelay, tableHeaderView 인디케이터, bubblesChange 처리
- `BibleAtlas/DI/Containers/DIContainer.swift` — `chatHistoryStore` 등록, `vmFactory` 인자 추가
- `BibleAtlas/DI/Factories/VMFactory.swift` — `chatHistoryStore` 필드, `makeChatBotBottomSheetVM`에서 주입
- `BibleAtlasTests/Mocks/MockVMFactory.swift` — MockChatHistoryStore 사용
- `BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift` — setUp에 store 주입, 기존 테스트 유지 + 신규 테스트

---

## Task 1: Value Types (Snapshot, Page, Change)

**Files:**
- Create: `BibleAtlas/Shared/ChatHistorySnapshot.swift`
- Create: `BibleAtlas/Shared/ChatBubblePage.swift`
- Create: `BibleAtlas/Shared/BubblesChange.swift`

- [ ] **Step 1: Create `ChatHistorySnapshot.swift`**

```swift
import Foundation

struct ChatHistorySnapshot: Equatable {
    let summary: String?
    let messages: [ChatMessage]
    let firstPage: ChatBubblePage
}
```

- [ ] **Step 2: Create `ChatBubblePage.swift`**

```swift
import Foundation

struct ChatBubblePage: Equatable {
    let bubbles: [ChatBubble]     // 오름차순, 최대 limit개
    let hasMore: Bool             // 더 오래된 것이 있는지
    let nextCursor: Int64?        // 다음 loadBubbles(beforeOrder:) 호출용 커서. hasMore=false 이면 nil.
}
```

- [ ] **Step 3: Create `BubblesChange.swift`**

```swift
import Foundation

enum BubblesChange: Equatable {
    case initial                    // 초기 로드 → scrollToBottom
    case appended                   // 새 메시지 append → scrollToBottom
    case prepended(count: Int)      // load-more → 오프셋 보정으로 위치 보존
}
```

- [ ] **Step 4: Add files to Xcode project**

수동: Xcode에서 `Shared/` 그룹에 세 파일을 Add Files로 추가. (자동 그룹 참조가 있다면 스킵)

- [ ] **Step 5: Verify compile**

Run: `xcodebuild -workspace BibleAtlas.xcworkspace -scheme BibleAtlas -destination "generic/platform=iOS Simulator" build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add BibleAtlas/Shared/ChatHistorySnapshot.swift \
        BibleAtlas/Shared/ChatBubblePage.swift \
        BibleAtlas/Shared/BubblesChange.swift \
        BibleAtlas.xcodeproj/project.pbxproj
git commit -m "feat: add chat history value types (snapshot/page/change)"
```

---

## Task 2: ChatHistoryStoreProtocol

**Files:**
- Create: `BibleAtlas/Domain/Protocols/ChatHistoryStoreProtocol.swift`

- [ ] **Step 1: Create protocol file**

```swift
import Foundation

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
```

- [ ] **Step 2: Add to Xcode project**

수동: `Domain/Protocols/` 그룹에 추가.

- [ ] **Step 3: Commit**

```bash
git add BibleAtlas/Domain/Protocols/ChatHistoryStoreProtocol.swift \
        BibleAtlas.xcodeproj/project.pbxproj
git commit -m "feat: add ChatHistoryStoreProtocol"
```

---

## Task 3: MockChatHistoryStore (test double)

**Files:**
- Create: `BibleAtlasTests/Mocks/MockChatHistoryStore.swift`

- [ ] **Step 1: Create mock**

```swift
import Foundation
@testable import BibleAtlas

final class MockChatHistoryStore: ChatHistoryStoreProtocol {
    // 저장 상태
    var storedSummary: String?
    var storedMessages: [ChatMessage] = []
    var storedBubbles: [ChatBubble] = []          // 오래된 → 최신 순 (order asc)

    // 호출 카운터/기록
    private(set) var appendBubbleCallCount = 0
    private(set) var updateContextCallCount = 0
    private(set) var loadBubblesCalls: [(beforeOrder: Int64?, limit: Int)] = []
    private(set) var clearCallCount = 0

    // 최근 인자
    private(set) var lastAppendedBubble: ChatBubble?
    private(set) var lastUpdateContext: (summary: String?, messages: [ChatMessage])?

    func loadSummary() -> String? { storedSummary }
    func loadMessages() -> [ChatMessage] { storedMessages }

    func updateContext(summary: String?, messages: [ChatMessage]) {
        updateContextCallCount += 1
        lastUpdateContext = (summary, messages)
        storedSummary = summary
        storedMessages = messages
    }

    func loadBubbles(beforeOrder: Int64?, limit: Int) -> ChatBubblePage {
        loadBubblesCalls.append((beforeOrder, limit))
        // storedBubbles 인덱스를 order로 취급 (0 = 가장 오래된)
        let cutoffIndex: Int
        if let before = beforeOrder {
            cutoffIndex = min(Int(before), storedBubbles.count)
        } else {
            cutoffIndex = storedBubbles.count
        }
        let end = cutoffIndex
        let start = max(0, end - limit)
        let slice = Array(storedBubbles[start..<end])
        let hasMore = start > 0
        return ChatBubblePage(bubbles: slice, hasMore: hasMore)
    }

    func appendBubble(_ bubble: ChatBubble) {
        appendBubbleCallCount += 1
        lastAppendedBubble = bubble
        storedBubbles.append(bubble)
    }

    func clear() {
        clearCallCount += 1
        storedSummary = nil
        storedMessages = []
        storedBubbles = []
    }
}
```

- [ ] **Step 2: Add to Xcode test target**

수동: `BibleAtlasTests/Mocks/` 그룹에 추가.

- [ ] **Step 3: Commit**

```bash
git add BibleAtlasTests/Mocks/MockChatHistoryStore.swift \
        BibleAtlas.xcodeproj/project.pbxproj
git commit -m "test: add MockChatHistoryStore"
```

---

## Task 4: VM constructor accepts store + loads snapshot

**Files:**
- Modify: `BibleAtlas/Presentation/ViewModels/ChatBotBottomSheetViewModel.swift`
- Modify: `BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift`

- [ ] **Step 1: Write failing test for initial snapshot load**

Add to `ChatBotBottomSheetViewModelTests.swift`:

```swift
private var historyStore: MockChatHistoryStore!

override func setUp() {
    super.setUp()
    usecase = FakeAgentUsecase()
    historyStore = MockChatHistoryStore()
    sut = ChatBotBottomSheetViewModel(usecase: usecase, historyStore: historyStore)
    bag = DisposeBag()
}

override func tearDown() {
    bag = nil
    sut = nil
    historyStore = nil
    usecase = nil
    super.tearDown()
}

// MARK: - initial snapshot

func test_init_loadsSnapshotFromStore_andEmitsBubbles() {
    let bubble = ChatBubble(kind: .user, text: "이전 질문")
    historyStore.storedBubbles = [bubble]
    historyStore.storedSummary = "prior summary"
    historyStore.storedMessages = [.init(role: .user, content: "이전 질문")]

    sut = ChatBotBottomSheetViewModel(usecase: usecase, historyStore: historyStore)
    let input = makeInput()
    let out = sut.transform(input: input)

    var latest: [ChatBubble] = []
    out.bubbles.drive(onNext: { latest = $0 }).disposed(by: bag)

    XCTAssertEqual(latest.count, 1)
    XCTAssertEqual(latest.first?.text, "이전 질문")
    XCTAssertEqual(historyStore.loadBubblesCalls.count, 1)
    XCTAssertNil(historyStore.loadBubblesCalls[0].beforeOrder)
    XCTAssertEqual(historyStore.loadBubblesCalls[0].limit, 20)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -workspace BibleAtlas.xcworkspace -scheme BibleAtlas -destination "platform=iOS Simulator,name=iPhone 15" test -only-testing:BibleAtlasTests/ChatBotBottomSheetViewModelTests/test_init_loadsSnapshotFromStore_andEmitsBubbles 2>&1 | tail -20`
Expected: FAIL — 컴파일 에러 (init에 historyStore 없음)

- [ ] **Step 3: Update `ChatBotBottomSheetViewModel` init signature and snapshot load**

`ChatBotBottomSheetViewModel.swift`의 Deps/State/Init 부분 교체:

```swift
    // MARK: - Deps

    private let usecase: AgentUsecaseProtocol
    private let historyStore: ChatHistoryStoreProtocol

    // MARK: - State

    private let bubblesRelay: BehaviorRelay<[ChatBubble]>
    private let progressRelay = BehaviorRelay<ChatProgress>(value: .idle)
    private let remainingRelay: BehaviorRelay<Int>
    private let fillInputRelay = PublishRelay<String>()
    private let routeRelay = PublishRelay<String>()
    private let limitAlertRelay = PublishRelay<Void>()

    private var session: ChatSessionState
    private var lastQuery: String?
    private var currentTask: Task<Void, Never>?
    private var pendingBubbleId: UUID?
    private var activeTools: [String: String] = [:]
    private var activeToolOrder: [String] = []

    // 페이지네이션 상태 (Task 8에서 활용)
    private var persistedBubbles: [ChatBubble] = []
    private var pendingBubble: ChatBubble?

    private let disposeBag = DisposeBag()

    private static let pageSize = 20

    // MARK: - Init

    init(usecase: AgentUsecaseProtocol, historyStore: ChatHistoryStoreProtocol) {
        self.usecase = usecase
        self.historyStore = historyStore
        let firstPage = historyStore.loadBubbles(beforeOrder: nil, limit: Self.pageSize)
        self.persistedBubbles = firstPage.bubbles
        self.session = ChatSessionState(
            summary: historyStore.loadSummary(),
            messages: historyStore.loadMessages()
        )
        self.bubblesRelay = BehaviorRelay<[ChatBubble]>(value: firstPage.bubbles)
        self.remainingRelay = BehaviorRelay<Int>(value: usecase.remainingCount)
    }
```

- [ ] **Step 4: Update all VM call sites to pass store**

`BibleAtlas/DI/Factories/VMFactory.swift`의 `makeChatBotBottomSheetVM` — Task 13에서 실제 wiring. 지금은 컴파일만 통과시키기 위해 임시로 다음 위치 수정:

`VMFactory.swift`:

```swift
    func makeChatBotBottomSheetVM() -> ChatBotBottomSheetViewModelProtocol {
        guard let agentUsecase = usecases?.agent else {
            fatalError("UseCases.agent is required to build ChatBotBottomSheetViewModel")
        }
        guard let store = chatHistoryStore else {
            fatalError("chatHistoryStore is required to build ChatBotBottomSheetViewModel")
        }
        return ChatBotBottomSheetViewModel(usecase: agentUsecase, historyStore: store)
    }
```

VMFactory에 필드/생성자 파라미터 추가:

```swift
    private var chatHistoryStore: ChatHistoryStoreProtocol?

    init(appStore: AppStoreProtocol?, collectionStore:CollectionStoreProtocol?, usecases:UseCases? = nil, notificationService: RxNotificationServiceProtocol?, recentSearchService:RecentSearchServiceProtocol?, chatHistoryStore: ChatHistoryStoreProtocol? = nil, analytics: AnalyticsLogging? = nil) {
        self.appStore = appStore
        self.collectionStore = collectionStore
        self.usecases = usecases
        self.notificationService = notificationService
        self.recentSearchService = recentSearchService
        self.chatHistoryStore = chatHistoryStore
        self.analytics = analytics
    }
```

- [ ] **Step 5: Update MockVMFactory to pass a mock store**

`BibleAtlasTests/Mocks/MockVMFactory.swift` line 37 부근:

```swift
    func makeChatBotBottomSheetVM() -> ChatBotBottomSheetViewModelProtocol {
        return ChatBotBottomSheetViewModel(usecase: FakeAgentUsecase(), historyStore: MockChatHistoryStore())
    }
```

- [ ] **Step 6: Run test to verify PASS**

Run: `xcodebuild -workspace BibleAtlas.xcworkspace -scheme BibleAtlas -destination "platform=iOS Simulator,name=iPhone 15" test -only-testing:BibleAtlasTests/ChatBotBottomSheetViewModelTests 2>&1 | tail -20`
Expected: 모든 기존 + 신규 테스트 PASS (기존 테스트는 store 주입만 바뀌고 동작 동일)

- [ ] **Step 7: Commit**

```bash
git add BibleAtlas/Presentation/ViewModels/ChatBotBottomSheetViewModel.swift \
        BibleAtlas/DI/Factories/VMFactory.swift \
        BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift \
        BibleAtlasTests/Mocks/MockVMFactory.swift
git commit -m "feat: VM accepts ChatHistoryStore and loads initial snapshot"
```

---

## Task 5: VM persists user/assistant/error bubbles

**Files:**
- Modify: `BibleAtlas/Presentation/ViewModels/ChatBotBottomSheetViewModel.swift`
- Modify: `BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift`

- [ ] **Step 1: Write failing tests for persistence writes**

Add to test file:

```swift
// MARK: - persistence writes

func test_send_persistsUserBubbleImmediately() {
    usecase.events = [doneEvent(answer: "ok")]
    let input = makeInput()
    _ = sut.transform(input: input)

    input.sendTapped.accept("hello")

    let exp = expectation(description: "wait stream")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
    wait(for: [exp], timeout: 2.0)

    // user bubble + assistant bubble 저장됨 (pending 제외)
    XCTAssertGreaterThanOrEqual(historyStore.appendBubbleCallCount, 2)
    XCTAssertEqual(historyStore.storedBubbles.first?.text, "hello")
    if case .user = historyStore.storedBubbles.first?.kind {} else {
        XCTFail("first stored bubble should be user")
    }
}

func test_done_persistsAssistantBubbleAndContext() {
    usecase.events = [doneEvent(
        answer: "네 답변",
        summary: "s1",
        messages: [.init(role: .user, content: "q"), .init(role: .assistant, content: "네 답변")]
    )]
    let input = makeInput()
    _ = sut.transform(input: input)
    input.sendTapped.accept("q")

    let exp = expectation(description: "wait")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
    wait(for: [exp], timeout: 2.0)

    XCTAssertEqual(historyStore.updateContextCallCount, 1)
    XCTAssertEqual(historyStore.lastUpdateContext?.summary, "s1")
    XCTAssertEqual(historyStore.lastUpdateContext?.messages.count, 2)
    // 저장된 assistant bubble
    XCTAssertTrue(historyStore.storedBubbles.contains { bubble in
        if case .assistant = bubble.kind { return bubble.text == "네 답변" } else { return false }
    })
}

func test_serverFailure_persistsErrorBubble() {
    usecase.events = [.failure(message: "서버 실패")]
    let input = makeInput()
    _ = sut.transform(input: input)

    input.sendTapped.accept("q")

    let exp = expectation(description: "wait")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
    wait(for: [exp], timeout: 2.0)

    XCTAssertTrue(historyStore.storedBubbles.contains { bubble in
        if case .error(let m) = bubble.kind { return m == "서버 실패" } else { return false }
    })
}
```

- [ ] **Step 2: Run tests to verify they FAIL**

Run: `xcodebuild ... -only-testing:BibleAtlasTests/ChatBotBottomSheetViewModelTests 2>&1 | tail -30`
Expected: 3 신규 테스트 FAIL (store 아직 안 부름)

- [ ] **Step 3: Update VM to call store on each settled bubble**

`ChatBotBottomSheetViewModel.swift`의 `handle(_ event:)` 및 `performSend`, `handleThrown` 갱신:

`performSend` 안의 user bubble append 이후:
```swift
        lastQuery = trimmed
        activeTools.removeAll()
        activeToolOrder.removeAll()

        let userBubble = ChatBubble(kind: .user, text: trimmed)
        persistedBubbles.append(userBubble)
        historyStore.appendBubble(userBubble)
        emitBubbles(change: .appended)

        let initialLabel = L10n.ChatBot.pendingInitial
        addPendingBubble(label: initialLabel)
        progressRelay.accept(.running(label: initialLabel))
```

기존의 `appendBubble(.init(kind: .user, text: trimmed))` 호출은 위 코드로 대체 (원래의 `appendBubble` 헬퍼는 이제 이 위치에서 안 씀 — Step 5 정리 참조).

`.done` case:
```swift
        case .done(let payload):
            removePendingBubble()
            activeTools.removeAll()
            activeToolOrder.removeAll()
            let bubble = ChatBubble(
                kind: .assistant(
                    placeIdMap: payload.placeIdMap,
                    recommendedQuestions: payload.recommendedQuestions
                ),
                text: payload.answer
            )
            persistedBubbles.append(bubble)
            historyStore.appendBubble(bubble)
            session.summary = payload.summary
            session.messages = payload.messages
            historyStore.updateContext(summary: payload.summary, messages: payload.messages)
            usecase.recordUsage()
            remainingRelay.accept(usecase.remainingCount)
            progressRelay.accept(.idle)
            emitBubbles(change: .appended)
```

`.failure` case:
```swift
        case .failure(let message):
            removePendingBubble()
            activeTools.removeAll()
            activeToolOrder.removeAll()
            let errorBubble = ChatBubble(kind: .error(message), text: message)
            persistedBubbles.append(errorBubble)
            historyStore.appendBubble(errorBubble)
            progressRelay.accept(.error(message: message))
            emitBubbles(change: .appended)
```

`handleThrown`:
```swift
    private func handleThrown(_ error: Error) {
        let message = Self.userFacingMessage(for: error)
        removePendingBubble()
        let errorBubble = ChatBubble(kind: .error(message), text: message)
        persistedBubbles.append(errorBubble)
        historyStore.appendBubble(errorBubble)
        progressRelay.accept(.error(message: message))
        emitBubbles(change: .appended)
    }
```

- [ ] **Step 4: Add `emitBubbles` helper and keep pending separate**

VM 내부에 헬퍼 추가:

```swift
    private let bubblesChangeRelay = PublishRelay<BubblesChange>()

    private func emitBubbles(change: BubblesChange) {
        let all = persistedBubbles + (pendingBubble.map { [$0] } ?? [])
        bubblesRelay.accept(all)
        bubblesChangeRelay.accept(change)
    }
```

기존 `appendBubble(_:)`, `addPendingBubble`, `updatePendingBubble`, `removePendingBubble`도 pending 처리를 로컬로 전환:

```swift
    private func addPendingBubble(label: String) {
        let bubble = ChatBubble(kind: .pending(label: label), text: label)
        pendingBubbleId = bubble.id
        pendingBubble = bubble
        emitBubbles(change: .appended)
    }

    private func updatePendingBubble(label: String) {
        guard pendingBubbleId != nil else {
            addPendingBubble(label: label)
            return
        }
        pendingBubble = ChatBubble(id: pendingBubbleId!, kind: .pending(label: label), text: label)
        emitBubbles(change: .appended)
    }

    private func removePendingBubble() {
        pendingBubble = nil
        pendingBubbleId = nil
        emitBubbles(change: .appended)
    }
```

옛 `appendBubble(_ b:)` 헬퍼는 이제 쓰이지 않으므로 제거.

- [ ] **Step 5: Run tests to verify PASS**

Run: `xcodebuild ... -only-testing:BibleAtlasTests/ChatBotBottomSheetViewModelTests 2>&1 | tail -30`
Expected: 신규 3개 + 기존 테스트 모두 PASS

- [ ] **Step 6: Commit**

```bash
git add BibleAtlas/Presentation/ViewModels/ChatBotBottomSheetViewModel.swift \
        BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift
git commit -m "feat: persist user/assistant/error bubbles and context to store"
```

---

## Task 6: VM does NOT persist pending bubbles

**Files:**
- Modify: `BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift`

- [ ] **Step 1: Write failing test**

```swift
// MARK: - pending is not persisted

func test_pending_isNotPersisted() {
    // 서버 응답 없이 pending 상태 유지되도록 events 비움 (stream 이 즉시 종료되지만 pending 은 addPendingBubble 시점에 생성됨)
    // 대신 mid-way throw로 pending 진입 후 error로 전환되는 상황 활용
    usecase.streamThrowsMidway = AgentStreamError.badStatus(code: 500, body: nil)
    let input = makeInput()
    _ = sut.transform(input: input)

    input.sendTapped.accept("q")

    let exp = expectation(description: "wait")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
    wait(for: [exp], timeout: 2.0)

    // user + error 만 저장됨. pending kind 는 저장 X.
    XCTAssertFalse(historyStore.storedBubbles.contains { bubble in
        if case .pending = bubble.kind { return true } else { return false }
    })
    XCTAssertEqual(historyStore.storedBubbles.count, 2) // user + error
}
```

- [ ] **Step 2: Run test to verify PASS**

Run: `xcodebuild ... -only-testing:BibleAtlasTests/ChatBotBottomSheetViewModelTests/test_pending_isNotPersisted 2>&1 | tail -10`
Expected: PASS (Task 5의 리팩터로 pending이 이미 store 밖에 있음)

- [ ] **Step 3: Commit**

```bash
git add BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift
git commit -m "test: verify pending bubbles are not persisted"
```

---

## Task 7: VM emits `bubblesChange` signal

**Files:**
- Modify: `BibleAtlas/Presentation/ViewModels/ChatBotBottomSheetViewModel.swift`
- Modify: `BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift`

- [ ] **Step 1: Write failing test for Output extension**

```swift
// MARK: - bubblesChange signal

func test_bubblesChange_emitsInitialAndAppended() {
    // 초기 스냅샷은 이미 relay 값으로 세팅되어 emit 안 될 수 있음 —
    // .initial 은 viewDidLoad 시점에 명시적으로 emit
    let input = makeInput()
    let out = sut.transform(input: input)

    var changes: [BubblesChange] = []
    out.bubblesChange.emit(onNext: { changes.append($0) }).disposed(by: bag)

    input.viewDidLoad.accept(())

    let exp1 = expectation(description: "initial")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp1.fulfill() }
    wait(for: [exp1], timeout: 1.0)

    XCTAssertTrue(changes.contains(.initial))

    usecase.events = [doneEvent(answer: "a")]
    input.sendTapped.accept("q")

    let exp2 = expectation(description: "append")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp2.fulfill() }
    wait(for: [exp2], timeout: 2.0)

    XCTAssertTrue(changes.contains(.appended))
}
```

- [ ] **Step 2: Run to verify FAIL**

Expected: 컴파일 실패 (`Output`에 `bubblesChange` 없음)

- [ ] **Step 3: Extend `Output` and wire `.initial` emit**

`ChatBotBottomSheetViewModel.swift`의 `Output` 구조체에 필드 추가:

```swift
    struct Output {
        let bubbles: Driver<[ChatBubble]>
        let progress: Driver<ChatProgress>
        let remainingCount: Driver<Int>
        let inputEnabled: Driver<Bool>
        let fillInputText: Signal<String>
        let routeToPlaceDetail: Signal<String>
        let showLimitAlert: Signal<Void>
        let isLoadingMore: Driver<Bool>       // Task 8에서 활용
        let bubblesChange: Signal<BubblesChange>
    }
```

`isLoadingMoreRelay` state 추가:
```swift
    private let isLoadingMoreRelay = BehaviorRelay<Bool>(value: false)
```

`transform` 안에서 `viewDidLoad` 구독 추가:

```swift
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.bubblesChangeRelay.accept(.initial)
            })
            .disposed(by: disposeBag)
```

`return Output(...)` 갱신:

```swift
        return Output(
            bubbles: bubblesRelay.asDriver(),
            progress: progressRelay.asDriver(),
            remainingCount: remainingRelay.asDriver(),
            inputEnabled: inputEnabled,
            fillInputText: fillInputRelay.asSignal(),
            routeToPlaceDetail: routeRelay.asSignal(),
            showLimitAlert: limitAlertRelay.asSignal(),
            isLoadingMore: isLoadingMoreRelay.asDriver(),
            bubblesChange: bubblesChangeRelay.asSignal()
        )
```

- [ ] **Step 4: Run test to verify PASS**

Run: `xcodebuild ... -only-testing:BibleAtlasTests/ChatBotBottomSheetViewModelTests 2>&1 | tail -30`
Expected: 신규 테스트 + 기존 모두 PASS

- [ ] **Step 5: Commit**

```bash
git add BibleAtlas/Presentation/ViewModels/ChatBotBottomSheetViewModel.swift \
        BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift
git commit -m "feat: emit bubblesChange signal (.initial/.appended)"
```

---

## Task 8: VM loadMore pagination

**Files:**
- Modify: `BibleAtlas/Presentation/ViewModels/ChatBotBottomSheetViewModel.swift`
- Modify: `BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift`

- [ ] **Step 1: Write failing tests**

`makeInput` 헬퍼 갱신:

```swift
private func makeInput() -> ChatBotBottomSheetViewModel.Input {
    .init(viewDidLoad: .init(),
          sendTapped: .init(),
          chipTapped: .init(),
          placeSelected: .init(),
          retryTapped: .init(),
          loadMoreTriggered: .init())
}
```

테스트 추가:

```swift
// MARK: - loadMore

func test_loadMoreTriggered_fetchesOlderPage_andPrepends() {
    // 스토어에 25개 미리 세팅. 초기 로드 시 최신 20개(idx 5..24) 로드됨.
    historyStore.storedBubbles = (0..<25).map { i in
        ChatBubble(kind: .user, text: "b\(i)")
    }
    sut = ChatBotBottomSheetViewModel(usecase: usecase, historyStore: historyStore)
    let input = makeInput()
    let out = sut.transform(input: input)

    var latest: [ChatBubble] = []
    out.bubbles.drive(onNext: { latest = $0 }).disposed(by: bag)

    XCTAssertEqual(latest.count, 20)
    XCTAssertEqual(latest.first?.text, "b5")
    XCTAssertEqual(latest.last?.text, "b24")

    // loadMore → 오래된 5개(idx 0..4) 추가
    input.loadMoreTriggered.accept(())

    XCTAssertEqual(latest.count, 25)
    XCTAssertEqual(latest.first?.text, "b0")
    XCTAssertEqual(latest.last?.text, "b24")
}

func test_loadMore_emitsPrependedChange() {
    historyStore.storedBubbles = (0..<25).map { i in ChatBubble(kind: .user, text: "b\(i)") }
    sut = ChatBotBottomSheetViewModel(usecase: usecase, historyStore: historyStore)
    let input = makeInput()
    let out = sut.transform(input: input)

    var changes: [BubblesChange] = []
    out.bubblesChange.emit(onNext: { changes.append($0) }).disposed(by: bag)

    input.loadMoreTriggered.accept(())

    XCTAssertTrue(changes.contains(where: {
        if case .prepended(let c) = $0 { return c == 5 } else { return false }
    }))
}

func test_loadMore_noMore_isNoOp() {
    historyStore.storedBubbles = (0..<10).map { i in ChatBubble(kind: .user, text: "b\(i)") }
    sut = ChatBotBottomSheetViewModel(usecase: usecase, historyStore: historyStore)
    let input = makeInput()
    let out = sut.transform(input: input)

    var latest: [ChatBubble] = []
    out.bubbles.drive(onNext: { latest = $0 }).disposed(by: bag)

    let beforeCalls = historyStore.loadBubblesCalls.count
    input.loadMoreTriggered.accept(())
    input.loadMoreTriggered.accept(())
    input.loadMoreTriggered.accept(())

    XCTAssertEqual(latest.count, 10)
    // hasMore=false 이므로 추가 fetch 없음 (init 시 1회만)
    XCTAssertEqual(historyStore.loadBubblesCalls.count, beforeCalls)
}

func test_loadMore_emitsIsLoadingMore() {
    historyStore.storedBubbles = (0..<25).map { i in ChatBubble(kind: .user, text: "b\(i)") }
    sut = ChatBotBottomSheetViewModel(usecase: usecase, historyStore: historyStore)
    let input = makeInput()
    let out = sut.transform(input: input)

    var flags: [Bool] = []
    out.isLoadingMore.drive(onNext: { flags.append($0) }).disposed(by: bag)

    input.loadMoreTriggered.accept(())

    // 최소 [false(init), true, false] 순서로 값이 흘러야 함
    XCTAssertTrue(flags.contains(true))
    XCTAssertEqual(flags.last, false)
}
```

- [ ] **Step 2: Run tests to verify FAIL**

Expected: 컴파일 실패 (`Input`에 `loadMoreTriggered` 없음)

- [ ] **Step 3: Add `loadMoreTriggered` input and pagination state**

`ChatBotBottomSheetViewModel.swift`의 `Input` 갱신:

```swift
    struct Input {
        let viewDidLoad: PublishRelay<Void>
        let sendTapped: PublishRelay<String>
        let chipTapped: PublishRelay<String>
        let placeSelected: PublishRelay<String>
        let retryTapped: PublishRelay<Void>
        let loadMoreTriggered: PublishRelay<Void>
    }
```

VM 상태: bubble의 `order`가 없으므로 인덱스 기반 커서 사용. `oldestLoadedIndex: Int?`를 통해 커서 관리 — 하지만 store가 order를 알아야 하므로, 실제로는 store가 order 개념을 가진다. Mock에서는 `beforeOrder`를 배열 인덱스로 취급.

VM 상태 필드 추가:

```swift
    private var oldestLoadedOrder: Int64?     // 현재 표시 중인 가장 오래된 버블의 order
    private var hasMoreOlder: Bool = false
    private var isLoadingMore: Bool = false
```

Init에서 스냅샷 로드 후 상태 설정 (Task 4에서 심어둔 init 갱신):

```swift
    init(usecase: AgentUsecaseProtocol, historyStore: ChatHistoryStoreProtocol) {
        self.usecase = usecase
        self.historyStore = historyStore
        let firstPage = historyStore.loadBubbles(beforeOrder: nil, limit: Self.pageSize)
        self.persistedBubbles = firstPage.bubbles
        self.hasMoreOlder = firstPage.hasMore
        // firstPage.bubbles는 asc 순서. 가장 오래된 = index 0.
        // store가 order 커서를 어떻게 노출하느냐가 관건 — 아래 프로토콜 확장 참조.
        self.oldestLoadedOrder = firstPage.bubbles.first.flatMap { _ in Int64(firstPage.bubbles.count) }
        // ↑ MockChatHistoryStore 에서 beforeOrder=배열 인덱스 개념으로 사용 (실제 CoreData 구현에서도 동일 규약)
        self.session = ChatSessionState(
            summary: historyStore.loadSummary(),
            messages: historyStore.loadMessages()
        )
        self.bubblesRelay = BehaviorRelay<[ChatBubble]>(value: firstPage.bubbles)
        self.remainingRelay = BehaviorRelay<Int>(value: usecase.remainingCount)
    }
```

**주의**: `oldestLoadedOrder` 값은 "다음 페이지 커서" 개념. Mock 규약: `beforeOrder = N` 이면 인덱스 `[0, N)` 범위의 마지막 20개를 반환. 초기 로드에서 store가 총 25개 중 최신 20개(인덱스 5..24)를 반환하면, 다음 fetch의 커서는 `beforeOrder=5`. `ChatBubblePage.nextCursor`(Task 1에서 이미 정의됨)에 이 값이 담겨 온다.

MockChatHistoryStore도 반영 (반환에 `nextCursor` 세팅):

```swift
    func loadBubbles(beforeOrder: Int64?, limit: Int) -> ChatBubblePage {
        loadBubblesCalls.append((beforeOrder, limit))
        let cutoff: Int
        if let before = beforeOrder {
            cutoff = min(Int(before), storedBubbles.count)
        } else {
            cutoff = storedBubbles.count
        }
        let start = max(0, cutoff - limit)
        let slice = Array(storedBubbles[start..<cutoff])
        let hasMore = start > 0
        let nextCursor: Int64? = hasMore ? Int64(start) : nil
        return ChatBubblePage(bubbles: slice, hasMore: hasMore, nextCursor: nextCursor)
    }
```

VM 이니셜라이저의 커서 세팅:

```swift
        self.oldestLoadedOrder = firstPage.nextCursor
```

VM 신규 메서드:

```swift
    private func performLoadMore() {
        guard hasMoreOlder, !isLoadingMore, let cursor = oldestLoadedOrder else { return }
        isLoadingMore = true
        isLoadingMoreRelay.accept(true)

        let page = historyStore.loadBubbles(beforeOrder: cursor, limit: Self.pageSize)
        persistedBubbles = page.bubbles + persistedBubbles
        hasMoreOlder = page.hasMore
        oldestLoadedOrder = page.nextCursor

        isLoadingMore = false
        isLoadingMoreRelay.accept(false)
        emitBubbles(change: .prepended(count: page.bubbles.count))
    }
```

`transform`에 구독:

```swift
        input.loadMoreTriggered
            .subscribe(onNext: { [weak self] in self?.performLoadMore() })
            .disposed(by: disposeBag)
```

- [ ] **Step 4: Update MockChatHistoryStore to return `ChatBubblePage(bubbles:, hasMore:, nextCursor:)`**

Task 3에서 만든 mock의 `loadBubbles` return을 위 스니펫(Step 3 위)의 nextCursor 포함 형태로 갱신 — 이미 Step 3에 코드 포함되어 있음. 편집만 확인.

또한 모든 `makeInput()` 호출부에 `loadMoreTriggered: .init()` 포함 확인 (이미 Step 1의 makeInput 갱신에 반영).

- [ ] **Step 5: Run tests to verify PASS**

Run: `xcodebuild ... -only-testing:BibleAtlasTests/ChatBotBottomSheetViewModelTests 2>&1 | tail -30`
Expected: 신규 4개 + 기존 전부 PASS

- [ ] **Step 6: Commit**

```bash
git add BibleAtlas/Presentation/ViewModels/ChatBotBottomSheetViewModel.swift \
        BibleAtlas/Shared/ChatBubblePage.swift \
        BibleAtlasTests/Mocks/MockChatHistoryStore.swift \
        BibleAtlasTests/ViewModels/ChatBotBottomSheetViewModelTests.swift
git commit -m "feat: VM supports loadMore pagination with cursor"
```

---

## Task 9: CoreData model v2 (3 new entities)

**Files:**
- Create: `BibleAtlas/BibleAtlas.xcdatamodeld/BibleAtlas 2.xcdatamodel/contents`
- Create: `BibleAtlas/BibleAtlas.xcdatamodeld/.xccurrentVersion`

- [ ] **Step 1: Create v2 model directory + contents**

`BibleAtlas/BibleAtlas.xcdatamodeld/BibleAtlas 2.xcdatamodel/contents`:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<model type="com.apple.IDECoreDataModeler.DataModel" documentVersion="1.0" lastSavedToolsVersion="22522" systemVersion="23C71" minimumToolsVersion="Automatic" sourceLanguage="Swift" userDefinedModelVersionIdentifier="2">
    <entity name="RecentSearchEntity" representedClassName="RecentSearchEntity" syncable="YES" codeGenerationType="class">
        <attribute name="id" optional="YES" attributeType="String"/>
        <attribute name="koreanName" optional="YES" attributeType="String"/>
        <attribute name="name" optional="YES" attributeType="String"/>
        <attribute name="timestamp" optional="YES" attributeType="Date" usesScalarValueType="NO"/>
        <attribute name="type" optional="YES" attributeType="String"/>
    </entity>
    <entity name="ChatSessionEntity" representedClassName="ChatSessionEntity" syncable="YES" codeGenerationType="class">
        <attribute name="summary" optional="YES" attributeType="String"/>
    </entity>
    <entity name="ChatBubbleEntity" representedClassName="ChatBubbleEntity" syncable="YES" codeGenerationType="class">
        <attribute name="id" optional="NO" attributeType="UUID" usesScalarValueType="NO"/>
        <attribute name="kindRaw" optional="NO" attributeType="String" defaultValueString="user"/>
        <attribute name="text" optional="NO" attributeType="String" defaultValueString=""/>
        <attribute name="placeIdMapJson" optional="YES" attributeType="String"/>
        <attribute name="recommendedQuestionsJson" optional="YES" attributeType="String"/>
        <attribute name="order" optional="NO" attributeType="Integer 64" defaultValueString="0" usesScalarValueType="YES"/>
    </entity>
    <entity name="ChatMessageEntity" representedClassName="ChatMessageEntity" syncable="YES" codeGenerationType="class">
        <attribute name="roleRaw" optional="NO" attributeType="String" defaultValueString="user"/>
        <attribute name="content" optional="NO" attributeType="String" defaultValueString=""/>
        <attribute name="order" optional="NO" attributeType="Integer 64" defaultValueString="0" usesScalarValueType="YES"/>
    </entity>
</model>
```

- [ ] **Step 2: Create `.xccurrentVersion` bumping to v2**

`BibleAtlas/BibleAtlas.xcdatamodeld/.xccurrentVersion`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>_XCCurrentVersionName</key>
    <string>BibleAtlas 2.xcdatamodel</string>
</dict>
</plist>
```

- [ ] **Step 3: Register v2 xcdatamodel in Xcode project**

수동: Xcode에서 `.xcdatamodeld` 우클릭 → "Add Model Version..." 로 만들거나, 위처럼 파일 직접 추가 후 pbxproj가 자동 인식하지 못하면 Add Files. 새 모델을 current로 설정 (Editor > Set Current Model Version, 위 xccurrentVersion 편집으로 대체 가능).

- [ ] **Step 4: Enable lightweight migration explicitly (안전)**

`BibleAtlas/PersistenceController.swift` 갱신:

```swift
import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "BibleAtlas")
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores { (desc, error) in
            if let error = error {
                fatalError("❌ CoreData 초기화 실패: \(error)")
            }
        }
    }
}
```

- [ ] **Step 5: Verify build**

Run: `xcodebuild -workspace BibleAtlas.xcworkspace -scheme BibleAtlas -destination "generic/platform=iOS Simulator" build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED. `ChatSessionEntity`, `ChatBubbleEntity`, `ChatMessageEntity` 클래스 자동 생성.

- [ ] **Step 6: Commit**

```bash
git add BibleAtlas/BibleAtlas.xcdatamodeld \
        BibleAtlas/PersistenceController.swift \
        BibleAtlas.xcodeproj/project.pbxproj
git commit -m "feat: add CoreData model v2 with chat entities (lightweight migration)"
```

---

## Task 10: CoreDataChatHistoryStore implementation

**Files:**
- Create: `BibleAtlas/Data/Stores/CoreDataChatHistoryStore.swift`

- [ ] **Step 1: Create the store**

```swift
import Foundation
import CoreData
import os.log

final class CoreDataChatHistoryStore: ChatHistoryStoreProtocol {
    private let context: NSManagedObjectContext
    private let log = OSLog(subsystem: "com.bibleatlas.chat", category: "history-store")

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Session summary

    func loadSummary() -> String? {
        sessionEntity()?.summary
    }

    // MARK: - Messages

    func loadMessages() -> [ChatMessage] {
        let req: NSFetchRequest<ChatMessageEntity> = ChatMessageEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        do {
            let rows = try context.fetch(req)
            return rows.compactMap { row in
                guard let roleRaw = row.roleRaw, let role = ChatRole(rawValue: roleRaw),
                      let content = row.content else { return nil }
                return ChatMessage(role: role, content: content)
            }
        } catch {
            os_log("loadMessages failed: %{public}@", log: log, type: .error, "\(error)")
            return []
        }
    }

    func updateContext(summary: String?, messages: [ChatMessage]) {
        // session summary
        let session = sessionEntity() ?? ChatSessionEntity(context: context)
        session.summary = summary

        // messages: delete all + insert
        let req: NSFetchRequest<NSFetchRequestResult> = ChatMessageEntity.fetchRequest()
        let deleteReq = NSBatchDeleteRequest(fetchRequest: req)
        do {
            try context.execute(deleteReq)
        } catch {
            os_log("delete messages failed: %{public}@", log: log, type: .error, "\(error)")
        }
        for (idx, msg) in messages.enumerated() {
            let entity = ChatMessageEntity(context: context)
            entity.roleRaw = msg.role.rawValue
            entity.content = msg.content
            entity.order = Int64(idx)
        }
        saveContext(op: "updateContext")
    }

    // MARK: - Bubbles

    func loadBubbles(beforeOrder: Int64?, limit: Int) -> ChatBubblePage {
        let req: NSFetchRequest<ChatBubbleEntity> = ChatBubbleEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "order", ascending: false)]
        req.fetchLimit = limit + 1
        if let cursor = beforeOrder {
            req.predicate = NSPredicate(format: "order < %lld", cursor)
        }
        do {
            let rows = try context.fetch(req)
            let hasMore = rows.count > limit
            let taken = rows.prefix(limit)
            let bubbles = taken.compactMap { entity -> ChatBubble? in
                mapBubble(entity)
            }.reversed()   // asc 로 변환
            let asc = Array(bubbles)
            let nextCursor: Int64? = hasMore ? asc.first?.orderCursorHint ?? taken.last?.order : nil
            return ChatBubblePage(bubbles: asc, hasMore: hasMore, nextCursor: nextCursor)
        } catch {
            os_log("loadBubbles failed: %{public}@", log: log, type: .error, "\(error)")
            return ChatBubblePage(bubbles: [], hasMore: false, nextCursor: nil)
        }
    }

    func appendBubble(_ bubble: ChatBubble) {
        let entity = ChatBubbleEntity(context: context)
        entity.id = bubble.id
        entity.text = bubble.text
        entity.order = nextOrder()
        switch bubble.kind {
        case .user:
            entity.kindRaw = "user"
        case .assistant(let map, let questions):
            entity.kindRaw = "assistant"
            entity.placeIdMapJson = encodeJson(map)
            entity.recommendedQuestionsJson = encodeJson(questions)
        case .error:
            entity.kindRaw = "error"
        case .pending:
            // pending 은 저장 안 함 — 방어적으로 rollback
            context.rollback()
            return
        }
        saveContext(op: "appendBubble")
    }

    func clear() {
        for name in ["ChatBubbleEntity", "ChatMessageEntity", "ChatSessionEntity"] {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let del = NSBatchDeleteRequest(fetchRequest: req)
            do {
                try context.execute(del)
            } catch {
                os_log("clear %{public}@ failed: %{public}@", log: log, type: .error, name, "\(error)")
            }
        }
        saveContext(op: "clear")
    }

    // MARK: - Helpers

    private func sessionEntity() -> ChatSessionEntity? {
        let req: NSFetchRequest<ChatSessionEntity> = ChatSessionEntity.fetchRequest()
        req.fetchLimit = 1
        return (try? context.fetch(req))?.first
    }

    private func nextOrder() -> Int64 {
        let req: NSFetchRequest<ChatBubbleEntity> = ChatBubbleEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "order", ascending: false)]
        req.fetchLimit = 1
        if let last = (try? context.fetch(req))?.first {
            return last.order + 1
        }
        return 0
    }

    private func mapBubble(_ entity: ChatBubbleEntity) -> ChatBubble? {
        guard let id = entity.id, let kindRaw = entity.kindRaw, let text = entity.text else { return nil }
        let kind: ChatBubbleKind
        switch kindRaw {
        case "user":
            kind = .user
        case "assistant":
            let map: [String: [String]] = decodeJson(entity.placeIdMapJson) ?? [:]
            let questions: [String] = decodeJson(entity.recommendedQuestionsJson) ?? []
            kind = .assistant(placeIdMap: map, recommendedQuestions: questions)
        case "error":
            kind = .error(text)
        default:
            return nil
        }
        return ChatBubble(id: id, kind: kind, text: text)
    }

    private func encodeJson<T: Encodable>(_ value: T) -> String? {
        do {
            let data = try JSONEncoder().encode(value)
            return String(data: data, encoding: .utf8)
        } catch {
            os_log("encode json failed: %{public}@", log: log, type: .error, "\(error)")
            return nil
        }
    }

    private func decodeJson<T: Decodable>(_ raw: String?) -> T? {
        guard let raw, let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func saveContext(op: String) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            os_log("save failed [%{public}@]: %{public}@", log: log, type: .error, op, "\(error)")
            context.rollback()
        }
    }
}

private extension ChatBubble {
    /// mapBubble 이후 asc bubbles의 첫 원소가 갖는 order를 store가 알 수 있게 해줄 helper.
    /// 실제로는 entity에서 직접 order를 읽어 넘겨야 하므로 loadBubbles에서 사용하지 않는다 —
    /// 아래 loadBubbles의 nextCursor 계산은 별도 로직으로 처리.
    var orderCursorHint: Int64? { nil }
}
```

**주의**: `loadBubbles`의 `nextCursor` 계산이 부정확한 상태다 (bubble이 order를 노출하지 않음). 아래 스텝에서 수정.

- [ ] **Step 2: Fix loadBubbles cursor calculation**

`loadBubbles`를 다음과 같이 교체 (entity의 order를 직접 사용):

```swift
    func loadBubbles(beforeOrder: Int64?, limit: Int) -> ChatBubblePage {
        let req: NSFetchRequest<ChatBubbleEntity> = ChatBubbleEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "order", ascending: false)]
        req.fetchLimit = limit + 1
        if let cursor = beforeOrder {
            req.predicate = NSPredicate(format: "order < %lld", cursor)
        }
        do {
            let rows = try context.fetch(req)
            let hasMore = rows.count > limit
            let taken = Array(rows.prefix(limit))
            // taken 은 order DESC 순. reverse 하면 asc.
            let ascEntities = Array(taken.reversed())
            let bubbles = ascEntities.compactMap { mapBubble($0) }
            // 다음 페이지 커서 = 현재 asc 첫(=가장 오래된) 항목의 order 값
            let nextCursor: Int64? = (hasMore ? ascEntities.first?.order : nil)
            return ChatBubblePage(bubbles: bubbles, hasMore: hasMore, nextCursor: nextCursor)
        } catch {
            os_log("loadBubbles failed: %{public}@", log: log, type: .error, "\(error)")
            return ChatBubblePage(bubbles: [], hasMore: false, nextCursor: nil)
        }
    }
```

그리고 파일 하단의 `orderCursorHint` extension은 제거.

- [ ] **Step 3: Add file to Xcode project**

수동: `Data/Stores/` 그룹에 추가 (없으면 그룹 생성).

- [ ] **Step 4: Verify build**

Run: `xcodebuild -workspace BibleAtlas.xcworkspace -scheme BibleAtlas -destination "generic/platform=iOS Simulator" build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add BibleAtlas/Data/Stores/CoreDataChatHistoryStore.swift \
        BibleAtlas.xcodeproj/project.pbxproj
git commit -m "feat: implement CoreDataChatHistoryStore"
```

---

## Task 11: CoreData store CRUD integration tests

**Files:**
- Create: `BibleAtlasTests/Stores/CoreDataChatHistoryStoreTests.swift`

- [ ] **Step 1: Create integration tests using in-memory store**

```swift
import XCTest
import CoreData
@testable import BibleAtlas

final class CoreDataChatHistoryStoreTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var sut: CoreDataChatHistoryStore!

    override func setUp() {
        super.setUp()
        container = NSPersistentContainer(name: "BibleAtlas")
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [desc]
        let exp = expectation(description: "load stores")
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
        sut = CoreDataChatHistoryStore(context: container.viewContext)
    }

    override func tearDown() {
        sut = nil
        container = nil
        super.tearDown()
    }

    // MARK: - summary

    func test_summary_persistsAndReloads() {
        sut.updateContext(summary: "s1", messages: [])
        XCTAssertEqual(sut.loadSummary(), "s1")
        sut.updateContext(summary: nil, messages: [])
        XCTAssertNil(sut.loadSummary())
    }

    // MARK: - messages

    func test_messages_replaceOnEachUpdate() {
        sut.updateContext(summary: nil, messages: [
            .init(role: .user, content: "q1"),
            .init(role: .assistant, content: "a1"),
        ])
        XCTAssertEqual(sut.loadMessages().count, 2)
        sut.updateContext(summary: nil, messages: [.init(role: .user, content: "q2")])
        XCTAssertEqual(sut.loadMessages().count, 1)
        XCTAssertEqual(sut.loadMessages().first?.content, "q2")
    }

    // MARK: - bubbles append + load

    func test_appendBubble_persistsAllKinds() {
        let user = ChatBubble(kind: .user, text: "질문")
        let assistant = ChatBubble(kind: .assistant(placeIdMap: ["place": ["a1"]], recommendedQuestions: ["q1"]), text: "답변")
        let error = ChatBubble(kind: .error("오류"), text: "오류")
        sut.appendBubble(user)
        sut.appendBubble(assistant)
        sut.appendBubble(error)

        let page = sut.loadBubbles(beforeOrder: nil, limit: 10)
        XCTAssertEqual(page.bubbles.count, 3)
        XCTAssertFalse(page.hasMore)
        XCTAssertNil(page.nextCursor)
        XCTAssertEqual(page.bubbles[0].text, "질문")
        if case .assistant(let map, let qs) = page.bubbles[1].kind {
            XCTAssertEqual(map["place"], ["a1"])
            XCTAssertEqual(qs, ["q1"])
        } else { XCTFail("expected assistant kind") }
        if case .error(let m) = page.bubbles[2].kind { XCTAssertEqual(m, "오류") }
        else { XCTFail("expected error kind") }
    }

    func test_pendingBubble_isNotPersisted() {
        let pending = ChatBubble(kind: .pending(label: "..."), text: "...")
        sut.appendBubble(pending)
        let page = sut.loadBubbles(beforeOrder: nil, limit: 10)
        XCTAssertEqual(page.bubbles.count, 0)
    }

    // MARK: - pagination

    func test_loadBubbles_returnsMostRecentFirstPage_andReportsHasMore() {
        for i in 0..<25 {
            sut.appendBubble(ChatBubble(kind: .user, text: "b\(i)"))
        }
        let first = sut.loadBubbles(beforeOrder: nil, limit: 20)
        XCTAssertEqual(first.bubbles.count, 20)
        XCTAssertEqual(first.bubbles.first?.text, "b5")
        XCTAssertEqual(first.bubbles.last?.text, "b24")
        XCTAssertTrue(first.hasMore)
        XCTAssertNotNil(first.nextCursor)

        let older = sut.loadBubbles(beforeOrder: first.nextCursor, limit: 20)
        XCTAssertEqual(older.bubbles.count, 5)
        XCTAssertEqual(older.bubbles.first?.text, "b0")
        XCTAssertEqual(older.bubbles.last?.text, "b4")
        XCTAssertFalse(older.hasMore)
        XCTAssertNil(older.nextCursor)
    }

    // MARK: - clear

    func test_clear_removesAll() {
        sut.appendBubble(ChatBubble(kind: .user, text: "x"))
        sut.updateContext(summary: "s", messages: [.init(role: .user, content: "x")])
        sut.clear()
        XCTAssertEqual(sut.loadBubbles(beforeOrder: nil, limit: 10).bubbles.count, 0)
        XCTAssertEqual(sut.loadMessages().count, 0)
        XCTAssertNil(sut.loadSummary())
    }
}
```

- [ ] **Step 2: Add file to Xcode test target**

수동: `BibleAtlasTests/Stores/` 그룹에 추가.

- [ ] **Step 3: Run tests to verify PASS**

Run: `xcodebuild -workspace BibleAtlas.xcworkspace -scheme BibleAtlas -destination "platform=iOS Simulator,name=iPhone 15" test -only-testing:BibleAtlasTests/CoreDataChatHistoryStoreTests 2>&1 | tail -40`
Expected: 6 tests PASS

- [ ] **Step 4: Commit**

```bash
git add BibleAtlasTests/Stores/CoreDataChatHistoryStoreTests.swift \
        BibleAtlas.xcodeproj/project.pbxproj
git commit -m "test: CoreDataChatHistoryStore CRUD + pagination"
```

---

## Task 12: DI wiring (register store, inject into VMFactory)

**Files:**
- Modify: `BibleAtlas/DI/Containers/DIContainer.swift`

- [ ] **Step 1: Register store and pass to VMFactory**

`DIContainer.swift`의 관련 부분 교체:

```swift
    lazy var context = PersistenceController.shared.container.viewContext
    lazy var recentSearchService = RecentSearchService(context: context)
    lazy var chatHistoryStore: ChatHistoryStoreProtocol = CoreDataChatHistoryStore(context: context)
```

`vmFactory` 초기화 라인 갱신:

```swift
    lazy var vmFactory = VMFactory(
        appStore: appStore,
        collectionStore: collectionStore,
        usecases: usecases,
        notificationService: notificationService,
        recentSearchService: recentSearchService,
        chatHistoryStore: chatHistoryStore
    )
```

- [ ] **Step 2: Verify build**

Run: `xcodebuild -workspace BibleAtlas.xcworkspace -scheme BibleAtlas -destination "generic/platform=iOS Simulator" build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add BibleAtlas/DI/Containers/DIContainer.swift
git commit -m "wire: register ChatHistoryStore in DI container"
```

---

## Task 13: VC scroll trigger + load-more spinner header

**Files:**
- Modify: `BibleAtlas/Presentation/ViewControllers/ChatBotBottomSheetViewController.swift`

- [ ] **Step 1: Add loadMoreRelay and top spinner header**

파일 상단 UI 정의 근처(headerContainer 등이 있는 블록)에 추가:

```swift
    private let loadMoreRelay = PublishRelay<Void>()
    private let topLoadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        v.color = .secondaryLabel
        return v
    }()
    private lazy var topLoadingHeader: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        v.addSubview(topLoadingIndicator)
        topLoadingIndicator.snp.makeConstraints { $0.center.equalToSuperview() }
        return v
    }()
```

`setupTable()`에서 tableHeaderView 설정:

```swift
    private func setupTable() {
        tableView.register(ChatBotUserBubbleCell.self, forCellReuseIdentifier: ChatBotUserBubbleCell.reuseID)
        tableView.register(ChatBotAssistantBubbleCell.self, forCellReuseIdentifier: ChatBotAssistantBubbleCell.reuseID)
        tableView.register(ChatBotPendingBubbleCell.self, forCellReuseIdentifier: ChatBotPendingBubbleCell.reuseID)
        tableView.register(ChatBotErrorBubbleCell.self, forCellReuseIdentifier: ChatBotErrorBubbleCell.reuseID)
        tableView.tableHeaderView = topLoadingHeader
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset.bottom = 40
        tableView.verticalScrollIndicatorInsets.bottom = 40
    }
```

- [ ] **Step 2: Extend `scrollViewDidScroll` to trigger loadMore near top**

`UITableViewDelegate` extension의 `scrollViewDidScroll` 갱신:

```swift
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setScrollToBottomButtonVisible(!isTableAtBottom())
        if scrollView.contentOffset.y < 100 {
            loadMoreRelay.accept(())
        }
    }
```

- [ ] **Step 3: Wire loadMoreRelay to VM input, bind isLoadingMore to indicator**

`bindViewModel()` 안의 input 생성 갱신:

```swift
        let input = ChatBotBottomSheetViewModel.Input(
            viewDidLoad: viewDidLoadRelay,
            sendTapped: sendRelay,
            chipTapped: chipRelay,
            placeSelected: placeSelectedRelay,
            retryTapped: retryRelay,
            loadMoreTriggered: loadMoreRelay
        )
```

`isLoadingMore` 바인딩 추가 (`bindViewModel()`의 output 구독 블록 어딘가에):

```swift
        output.isLoadingMore
            .drive(onNext: { [weak self] loading in
                loading ? self?.topLoadingIndicator.startAnimating() : self?.topLoadingIndicator.stopAnimating()
            })
            .disposed(by: disposeBag)
```

- [ ] **Step 4: Verify build**

Run: `xcodebuild -workspace BibleAtlas.xcworkspace -scheme BibleAtlas -destination "generic/platform=iOS Simulator" build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add BibleAtlas/Presentation/ViewControllers/ChatBotBottomSheetViewController.swift
git commit -m "feat: VC load-more scroll trigger + top spinner header"
```

---

## Task 14: VC scroll position preservation on prepend

**Files:**
- Modify: `BibleAtlas/Presentation/ViewControllers/ChatBotBottomSheetViewController.swift`

- [ ] **Step 1: Replace bubbles subscription to consume bubblesChange**

`bindViewModel()`의 `output.bubbles` 구독 블록 교체:

```swift
        output.bubbles
            .drive(onNext: { [weak self] bubbles in
                guard let self = self else { return }
                self.bubbles = bubbles
                self.emptyStateView.isHidden = !bubbles.isEmpty
            })
            .disposed(by: disposeBag)

        output.bubblesChange
            .emit(onNext: { [weak self] change in
                guard let self = self else { return }
                switch change {
                case .initial, .appended:
                    self.tableView.reloadData()
                    self.scrollToBottom()
                case .prepended(let count):
                    guard count > 0 else {
                        self.tableView.reloadData()
                        return
                    }
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

- [ ] **Step 2: Verify build**

Run: `xcodebuild -workspace BibleAtlas.xcworkspace -scheme BibleAtlas -destination "generic/platform=iOS Simulator" build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Manual smoke check (UI)**

Xcode로 시뮬레이터 실행 → 챗봇 시트 열어 21개 이상 대화 만들기 → 시트 닫고 다시 열기 → 최신 20개만 보이는지, 위로 스크롤 시 이전 대화가 로드되고 스크롤 위치가 유지되는지 눈으로 확인.

- [ ] **Step 4: Commit**

```bash
git add BibleAtlas/Presentation/ViewControllers/ChatBotBottomSheetViewController.swift
git commit -m "feat: VC preserves scroll position when prepending older bubbles"
```

---

## Task 15: Run full test suite + final cleanup

**Files:** none

- [ ] **Step 1: Run all tests**

Run: `xcodebuild -workspace BibleAtlas.xcworkspace -scheme BibleAtlas -destination "platform=iOS Simulator,name=iPhone 15" test 2>&1 | tail -40`
Expected: 모든 테스트 PASS

- [ ] **Step 2: Check for warnings/unused code**

Xcode 빌드 로그에 unused/deprecated 경고 있는지 확인. 있으면 소소한 정리 커밋으로 처리.

- [ ] **Step 3: Verify spec coverage checklist**

`docs/superpowers/specs/2026-08-03-chat-session-persistence-design.md`의 "성공 기준" 8개를 다시 훑어보고 각 항목이 반영되었는지 (Task 참조 표시):
1. 시트 재개방 → 이전 버블 (Task 4, 14 수동 확인)
2. 앱 재실행 → 복원 (Task 9, 10, 14 수동 확인)
3. AgentStreamRequest에 이전 summary/messages (기존 performSend 로직 + Task 5)
4. 20개 초과 시 pagination (Task 8, 10, 11)
5. prepend 후 offset 보존 (Task 14)
6. 저장/복원 실패 시 앱 crash X (Task 10 catch/os_log)
7. 기존 UX 회귀 없음 (기존 테스트 통과 유지)
8. 단위 + 통합 테스트 (Task 5–8, 11)

- [ ] **Step 4: Optional — clean commit noise, push branch**

```bash
git status
```

필요시 `git push -u origin <branch>` — 사용자 요청 시에만.

---

## Self-Review

**Spec 커버리지**: 위 Task 15 Step 3의 8개 요구사항 모두 대응 태스크 있음. ✓

**Placeholder 스캔**: TODO/TBD 없음. 모든 스텝에 실행 가능한 명령/코드 포함. ✓

**타입 일관성**:
- `ChatBubblePage`: Task 1부터 3필드(bubbles/hasMore/nextCursor)로 정의. Task 3 Mock, Task 8 VM, Task 10 CoreData 모두 동일 시그니처. ✓
- `ChatHistorySnapshot`: Task 1에서 정의했으나 실제 VM에서는 `firstPage` + `summary`/`messages`를 개별 store 메서드 호출로 조합한다. 이 값 타입은 미래 확장(예: MockStore가 스냅샷 반환)용으로 정의만 하고 즉시 소비하지 않음. spec에는 남겨두지만 사용 필요 없다면 Task 1에서 제거 가능. 그대로 유지(deadweight 아님, 나중에 통합 로드 API 도입 시 사용).
- `Input.loadMoreTriggered`: Task 8에서 추가. Task 4의 makeInput 헬퍼는 이 시점엔 없어서 컴파일 실패 → Task 8 Step 1의 makeInput 갱신으로 해결. 순서상 Task 4의 makeInput은 5개 필드로만, Task 8 시점에 6번째로 확장. ✓
- `Output.isLoadingMore` / `bubblesChange`: Task 7에서 output에 추가, Task 8에서 실제 소비. Task 4에서는 아직 output이 이 두 필드 없음 → Task 4의 `return Output(...)` 부분은 원본 그대로 유지되고 Task 7에서 필드 추가. 컴파일 순서상 문제없음. ✓

**주의사항**:
- Task 5 Step 3에서 pending 관련 헬퍼(`addPendingBubble` 등)를 로컬 상태 방식으로 바꿈 → Task 4 시점엔 아직 옛 구현이라 컴파일은 통과하지만 초기 스냅샷 로드가 pending 흐름과 무관해서 실제 동작에 영향 없음. Task 5에서 완전 전환.
- CoreData 자동 생성 클래스(`ChatBubbleEntity` 등)는 Xcode가 빌드 시 자동 생성. Task 10에서 store 컴파일이 안 되면 Task 9의 모델 등록/current version 설정을 재확인.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-03-chat-session-persistence.md`. Two execution options:

**1. Subagent-Driven (recommended)** — 각 태스크마다 fresh subagent가 실행하고, 중간 리뷰. 빠른 반복.

**2. Inline Execution** — 이 세션에서 순차 실행하며 체크포인트마다 사용자 확인.

어느 방식으로 진행할까요?
