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
        appendBubble(.init(kind: .user, text: trimmed))
        progressRelay.accept(.running(label: "요청 준비 중…"))

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
                    case .done: print("[Chat] \(t) done")
                    case .failure(let m): print("[Chat] \(t) failure=\(m)")
                    }
                    #endif
                    await MainActor.run { self.handle(event) }
                    // 서버가 node + done 을 붙여 보내면 UI 가 node 라벨을 그릴 시간이 없음.
                    // node 처리 후 최소 400ms 는 보이도록 대기.
                    if case .node = event {
                        try? await Task.sleep(nanoseconds: 400_000_000)
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
            progressRelay.accept(.running(label: ChatBotProgressLabel.label(forNode: name)))
        case .done(let payload):
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
            appendBubble(.init(kind: .error(message), text: message))
            progressRelay.accept(.error(message: message))
        }
    }

    private func handleThrown(_ error: Error) {
        let message = Self.userFacingMessage(for: error)
        appendBubble(.init(kind: .error(message), text: message))
        progressRelay.accept(.error(message: message))
    }

    private func appendBubble(_ b: ChatBubble) {
        bubblesRelay.accept(bubblesRelay.value + [b])
    }

    static func userFacingMessage(for error: Error) -> String {
        if let streamError = error as? AgentStreamError {
            switch streamError {
            case .badStatus(let code, _):
                return "네트워크 에러 (코드 \(code))"
            case .invalidResponse:
                return "서버 응답 형식이 이상해요"
            case .decoding:
                return "응답을 이해할 수 없어요"
            }
        }
        return "연결이 끊어졌어요"
    }
}
