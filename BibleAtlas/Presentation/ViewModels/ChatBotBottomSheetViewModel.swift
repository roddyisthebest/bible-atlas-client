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
    }

    struct Output {
        let bubbles: Driver<[ChatBubble]>
        let progress: Driver<ChatProgress>
        let remainingCount: Driver<Int>
        let inputEnabled: Driver<Bool>
        let fillInputText: Signal<String>
        let routeToPlaceDetail: Signal<String>
        let showLimitAlert: Signal<Void>
    }

    enum ChatProgress: Equatable {
        case idle
        case running(label: String)
        case error(message: String)
    }

    // MARK: - Deps

    private let usecase: AgentUsecaseProtocol

    // MARK: - State

    private let bubblesRelay = BehaviorRelay<[ChatBubble]>(value: [])
    private let progressRelay = BehaviorRelay<ChatProgress>(value: .idle)
    private let remainingRelay: BehaviorRelay<Int>
    private let fillInputRelay = PublishRelay<String>()
    private let routeRelay = PublishRelay<String>()
    private let limitAlertRelay = PublishRelay<Void>()

    private var session = ChatSessionState()
    private var lastQuery: String?
    private var currentTask: Task<Void, Never>?
    private var pendingBubbleId: UUID?
    /// 동시 실행 중인 tool 추적. key: call id, value: tool name. 최근에 시작된 도구를 진행 라벨로 노출.
    private var activeTools: [String: String] = [:]
    /// activeTools 에 들어간 순서 유지 (뒤에 있는 것이 최근). removeValue 로는 순서 알 수 없어 별도 관리.
    private var activeToolOrder: [String] = []

    private let disposeBag = DisposeBag()

    // MARK: - Init

    init(usecase: AgentUsecaseProtocol) {
        self.usecase = usecase
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
                self?.fillInputRelay.accept(text)
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
            showLimitAlert: limitAlertRelay.asSignal()
        )
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
        appendBubble(.init(kind: .user, text: trimmed))
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
            appendBubble(bubble)
            session.summary = payload.summary
            session.messages = payload.messages
            usecase.recordUsage()
            remainingRelay.accept(usecase.remainingCount)
            progressRelay.accept(.idle)
        case .failure(let message):
            removePendingBubble()
            activeTools.removeAll()
            activeToolOrder.removeAll()
            appendBubble(.init(kind: .error(message), text: message))
            progressRelay.accept(.error(message: message))
        }
    }

    private func handleThrown(_ error: Error) {
        let message = Self.userFacingMessage(for: error)
        removePendingBubble()
        appendBubble(.init(kind: .error(message), text: message))
        progressRelay.accept(.error(message: message))
    }

    private func appendBubble(_ b: ChatBubble) {
        bubblesRelay.accept(bubblesRelay.value + [b])
    }

    private func addPendingBubble(label: String) {
        let id = UUID()
        pendingBubbleId = id
        appendBubble(.init(id: id, kind: .pending(label: label), text: label))
    }

    private func updatePendingBubble(label: String) {
        guard let id = pendingBubbleId else {
            addPendingBubble(label: label)
            return
        }
        var current = bubblesRelay.value
        guard let idx = current.firstIndex(where: { $0.id == id }) else { return }
        current[idx] = ChatBubble(id: id, kind: .pending(label: label), text: label)
        bubblesRelay.accept(current)
    }

    private func removePendingBubble() {
        guard let id = pendingBubbleId else { return }
        var current = bubblesRelay.value
        if let idx = current.firstIndex(where: { $0.id == id }) {
            current.remove(at: idx)
            bubblesRelay.accept(current)
        }
        pendingBubbleId = nil
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
