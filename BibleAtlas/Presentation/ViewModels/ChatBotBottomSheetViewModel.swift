import Foundation
import RxSwift
import RxRelay
import RxCocoa

protocol ChatBotBottomSheetViewModelProtocol {
    func transform(input: ChatBotBottomSheetViewModel.Input) -> ChatBotBottomSheetViewModel.Output
}

final class ChatBotBottomSheetViewModel: ChatBotBottomSheetViewModelProtocol {

    // MARK: - I/O

    struct Input {
        let viewDidLoad: PublishRelay<Void>
        let sendTapped: PublishRelay<String>
        let chipTapped: PublishRelay<String>
        let placeSelected: PublishRelay<String>      // 이미 해결된 placeId
        let retryTapped: PublishRelay<Void>
        let loadMoreTriggered: PublishRelay<Void>
    }

    struct Output {
        let bubbles: Driver<[ChatBubble]>
        let progress: Driver<ChatProgress>
        let remainingCount: Driver<Int>
        let inputEnabled: Driver<Bool>
        let fillInputText: Signal<String>
        let routeToPlaceDetail: Signal<String>
        let showLimitAlert: Signal<Void>
        let isLoadingMore: Driver<Bool>       // Task 8에서 실제 갱신
        let bubblesChange: Signal<BubblesChange>
    }

    enum ChatProgress: Equatable {
        case idle
        case running(label: String)
        case error(message: String)
    }

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
    private let isLoadingMoreRelay = BehaviorRelay<Bool>(value: false)

    private var session: ChatSessionState
    private var lastQuery: String?
    private var currentTask: Task<Void, Never>?
    private var pendingBubbleId: UUID?
    /// 동시 실행 중인 tool 추적. key: call id, value: tool name. 최근에 시작된 도구를 진행 라벨로 노출.
    private var activeTools: [String: String] = [:]
    /// activeTools 에 들어간 순서 유지 (뒤에 있는 것이 최근). removeValue 로는 순서 알 수 없어 별도 관리.
    private var activeToolOrder: [String] = []

    // 페이지네이션 상태 (Task 8에서 활용)
    private var persistedBubbles: [ChatBubble] = []
    private var pendingBubble: ChatBubble?
    private var oldestLoadedOrder: Int64?     // 다음 페이지 커서
    private var hasMoreOlder: Bool = false
    private var isLoadingMore: Bool = false

    private let disposeBag = DisposeBag()

    private static let pageSize = 20

    // MARK: - Init

    init(usecase: AgentUsecaseProtocol, historyStore: ChatHistoryStoreProtocol) {
        self.usecase = usecase
        self.historyStore = historyStore
        let firstPage = historyStore.loadBubbles(beforeOrder: nil, limit: Self.pageSize)
        self.persistedBubbles = firstPage.bubbles
        self.hasMoreOlder = firstPage.hasMore
        self.oldestLoadedOrder = firstPage.nextCursor
        self.session = ChatSessionState(
            summary: historyStore.loadSummary(),
            messages: historyStore.loadMessages()
        )
        self.bubblesRelay = BehaviorRelay<[ChatBubble]>(value: firstPage.bubbles)
        self.remainingRelay = BehaviorRelay<Int>(value: usecase.remainingCount)
    }

    deinit {
        currentTask?.cancel()
    }

    // MARK: - Transform

    func transform(input: Input) -> Output {
        input.sendTapped
            .subscribe(onNext: { [weak self] query in
                self?.performSend(query: query)
            })
            .disposed(by: disposeBag)

        input.chipTapped
            .subscribe(onNext: { [weak self] text in
                guard let self = self else { return }
                // 사용 한도 소진 시엔 텍스트 채우기 대신 limit alert 로 즉시 안내.
                guard self.usecase.remainingCount > 0 else {
                    self.limitAlertRelay.accept(())
                    return
                }
                self.fillInputRelay.accept(text)
            })
            .disposed(by: disposeBag)

        input.placeSelected
            .subscribe(onNext: { [weak self] placeId in
                self?.routeRelay.accept(placeId)
            })
            .disposed(by: disposeBag)

        input.retryTapped
            .subscribe(onNext: { [weak self] in
                guard let last = self?.lastQuery else { return }
                self?.performSend(query: last)
            })
            .disposed(by: disposeBag)

        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.bubblesChangeRelay.accept(.initial(bubbles: self.currentBubbles))
            })
            .disposed(by: disposeBag)

        input.loadMoreTriggered
            .subscribe(onNext: { [weak self] in self?.performLoadMore() })
            .disposed(by: disposeBag)

        let inputEnabled = Driver.combineLatest(
            remainingRelay.asDriver(),
            progressRelay.asDriver()
        ) { remaining, progress -> Bool in
            guard remaining > 0 else { return false }
            if case .running = progress { return false }
            return true
        }

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
    }

    // MARK: - Pagination

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
        emitBubbles { .prepended(bubbles: $0, count: page.bubbles.count) }
    }

    // MARK: - Send / stream

    private func performSend(query: String) {
        guard usecase.remainingCount > 0 else {
            limitAlertRelay.accept(())
            return
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        lastQuery = trimmed
        activeTools.removeAll()
        activeToolOrder.removeAll()

        let userBubble = ChatBubble(kind: .user, text: trimmed)
        persistedBubbles.append(userBubble)
        historyStore.appendBubble(userBubble)
        emitBubbles { .appended(bubbles: $0) }

        let initialLabel = L10n.ChatBot.pendingInitial
        addPendingBubble(label: initialLabel)
        progressRelay.accept(.running(label: initialLabel))

        let request = AgentStreamRequest(
            query: trimmed,
            summary: session.summary,
            messages: session.messages
        )

        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let stream = try self.usecase.stream(request: request)
                for try await event in stream {
                    if Task.isCancelled { return }
                    #if DEBUG
                    let t = Date().timeIntervalSince1970
                    switch event {
                    case .node(let n): print("[Chat] \(t) node=\(n)")
                    case .tool(let id, let n, let p): print("[Chat] \(t) tool=\(n) phase=\(p.rawValue) id=\(id)")
                    case .done: print("[Chat] \(t) done")
                    case .failure(let m): print("[Chat] \(t) failure=\(m)")
                    }
                    #endif
                    await MainActor.run { self.handle(event) }
                    // node 라벨은 최소 700ms 는 보이도록 대기 (사람 눈으로 읽을 시간).
                    // 다음 이벤트가 sleep 중 도착해도 stream 이 buffering 하므로 손실 없음.
                    if case .node = event {
                        try? await Task.sleep(nanoseconds: 700_000_000)
                    }
                }
            } catch AgentUsecaseError.limitExceeded {
                await MainActor.run { self.limitAlertRelay.accept(()) }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run { self.handleThrown(error) }
            }
        }
    }

    private func handle(_ event: AgentStreamEvent) {
        switch event {
        case .node(let name):
            // tool 이벤트가 진행 중이면 tool 라벨이 더 세밀하므로 node 로 덮어쓰지 않음.
            guard activeTools.isEmpty else { return }
            let label = ChatBotProgressLabel.label(forNode: name)
            updatePendingBubble(label: label)
            progressRelay.accept(.running(label: label))
        case .tool(let id, let name, let phase):
            switch phase {
            case .start:
                if activeTools[id] == nil { activeToolOrder.append(id) }
                activeTools[id] = name
                let label = ChatBotProgressLabel.label(forTool: name)
                updatePendingBubble(label: label)
                progressRelay.accept(.running(label: label))
            case .done:
                activeTools.removeValue(forKey: id)
                activeToolOrder.removeAll { $0 == id }
                if activeTools.isEmpty {
                    let label = ChatBotProgressLabel.toolWrapup
                    updatePendingBubble(label: label)
                    progressRelay.accept(.running(label: label))
                } else if let latestId = activeToolOrder.last, let latestName = activeTools[latestId] {
                    let label = ChatBotProgressLabel.label(forTool: latestName)
                    updatePendingBubble(label: label)
                    progressRelay.accept(.running(label: label))
                }
            }
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
            emitBubbles { .appended(bubbles: $0) }
        case .failure(let message):
            removePendingBubble()
            activeTools.removeAll()
            activeToolOrder.removeAll()
            let errorBubble = ChatBubble(kind: .error(message), text: message)
            persistedBubbles.append(errorBubble)
            historyStore.appendBubble(errorBubble)
            progressRelay.accept(.error(message: message))
            emitBubbles { .appended(bubbles: $0) }
        }
    }

    private func handleThrown(_ error: Error) {
        let message = Self.userFacingMessage(for: error)
        removePendingBubble()
        let errorBubble = ChatBubble(kind: .error(message), text: message)
        persistedBubbles.append(errorBubble)
        historyStore.appendBubble(errorBubble)
        progressRelay.accept(.error(message: message))
        emitBubbles { .appended(bubbles: $0) }
    }

    private let bubblesChangeRelay = PublishRelay<BubblesChange>()

    /// 현재 화면에 표시되어야 할 전체 배열 (persisted + pending).
    private var currentBubbles: [ChatBubble] {
        persistedBubbles + (pendingBubble.map { [$0] } ?? [])
    }

    /// makeChange 로 새 배열을 담은 BubblesChange 를 생성해 emit.
    /// bubblesRelay 는 관찰용 상태(예: isEmpty 체크)로만 소비되고,
    /// datasource 동기화는 반드시 bubblesChange 소비자 쪽에서 처리해야 함.
    private func emitBubbles(_ makeChange: ([ChatBubble]) -> BubblesChange) {
        let all = currentBubbles
        bubblesRelay.accept(all)
        bubblesChangeRelay.accept(makeChange(all))
    }

    private func addPendingBubble(label: String) {
        let bubble = ChatBubble(kind: .pending(label: label), text: label)
        pendingBubbleId = bubble.id
        pendingBubble = bubble
        emitBubbles { .appended(bubbles: $0) }
    }

    private func updatePendingBubble(label: String) {
        guard pendingBubbleId != nil else {
            addPendingBubble(label: label)
            return
        }
        pendingBubble = ChatBubble(id: pendingBubbleId!, kind: .pending(label: label), text: label)
        emitBubbles { .appended(bubbles: $0) }
    }

    private func removePendingBubble() {
        pendingBubble = nil
        pendingBubbleId = nil
        emitBubbles { .appended(bubbles: $0) }
    }

    static func userFacingMessage(for error: Error) -> String {
        if let streamError = error as? AgentStreamError {
            switch streamError {
            case .badStatus(let code, _):
                return L10n.ChatBot.Error.network(code)
            case .invalidResponse:
                return L10n.ChatBot.Error.invalidResponse
            case .decoding:
                return L10n.ChatBot.Error.decoding
            }
        }
        return L10n.ChatBot.Error.connectionLost
    }
}
