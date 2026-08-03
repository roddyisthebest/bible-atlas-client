import XCTest
import RxSwift
import RxRelay
import RxCocoa
@testable import BibleAtlas

final class ChatBotBottomSheetViewModelTests: XCTestCase {
    private var usecase: FakeAgentUsecase!
    private var sut: ChatBotBottomSheetViewModel!
    private var bag: DisposeBag!
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

    private func makeInput() -> ChatBotBottomSheetViewModel.Input {
        .init(viewDidLoad: .init(),
              sendTapped: .init(),
              chipTapped: .init(),
              placeSelected: .init(),
              retryTapped: .init(),
              loadMoreTriggered: .init())
    }

    private func doneEvent(answer: String = "hi",
                           placeIdMap: [String: [String]] = [:],
                           recommendedQuestions: [String] = [],
                           summary: String? = nil,
                           messages: [ChatMessage] = []) -> AgentStreamEvent {
        .done(AgentDonePayload(
            answer: answer,
            placeIdMap: placeIdMap,
            recommendedQuestions: recommendedQuestions,
            summary: summary,
            messages: messages
        ))
    }

    // MARK: - send happy path

    func test_send_appendsUserBubble_thenAssistantBubble_onDone() {
        usecase.events = [doneEvent(answer: "네 답변입니다", messages: [
            .init(role: .user, content: "안녕"),
            .init(role: .assistant, content: "네 답변입니다"),
        ])]
        let input = makeInput()
        let out = sut.transform(input: input)

        var observed: [[ChatBubble]] = []
        out.bubbles.drive(onNext: { observed.append($0) }).disposed(by: bag)

        input.sendTapped.accept("안녕")

        let exp = expectation(description: "wait stream")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        wait(for: [exp], timeout: 2.0)

        XCTAssertGreaterThanOrEqual(observed.count, 3)      // initial [], + user, + assistant
        let final = observed.last ?? []
        XCTAssertEqual(final.count, 2)
        if case .user = final[0].kind {} else { XCTFail("first should be user") }
        if case .assistant = final[1].kind {} else { XCTFail("second should be assistant") }
        XCTAssertEqual(final[1].text, "네 답변입니다")
    }

    func test_send_incrementsUsageOnDone() {
        usecase.events = [doneEvent()]
        let input = makeInput()
        _ = sut.transform(input: input)
        input.sendTapped.accept("q")

        let exp = expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        wait(for: [exp], timeout: 2.0)

        XCTAssertEqual(usecase.recordUsageCallCount, 1)
    }

    // MARK: - limit

    func test_send_emitsLimitAlert_whenRemainingIsZero() {
        usecase._remainingCount = 0
        let input = makeInput()
        let out = sut.transform(input: input)

        var alerted = false
        out.showLimitAlert.emit(onNext: { alerted = true }).disposed(by: bag)

        input.sendTapped.accept("q")
        XCTAssertTrue(alerted)
        XCTAssertEqual(usecase.streamCallCount, 0)
    }

    func test_inputEnabled_falseWhenRemainingZero() {
        // VM captures remainingCount at init, so we need a fresh SUT with usecase already at 0.
        usecase._remainingCount = 0
        sut = ChatBotBottomSheetViewModel(usecase: usecase, historyStore: historyStore)
        let input = makeInput()
        let out = sut.transform(input: input)

        var enabled: Bool?
        out.inputEnabled.drive(onNext: { enabled = $0 }).disposed(by: bag)

        XCTAssertEqual(enabled, false)
    }

    // MARK: - server failure event

    func test_send_appendsErrorBubble_onServerFailureEvent() {
        usecase.events = [.failure(message: "server said no")]
        let input = makeInput()
        let out = sut.transform(input: input)

        var latest: [ChatBubble] = []
        out.bubbles.drive(onNext: { latest = $0 }).disposed(by: bag)

        input.sendTapped.accept("q")

        let exp = expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        wait(for: [exp], timeout: 2.0)

        XCTAssertEqual(latest.count, 2)     // user + error
        if case .error(let msg) = latest[1].kind { XCTAssertEqual(msg, "server said no") }
        else { XCTFail("expected error bubble") }
    }

    // MARK: - thrown error

    func test_send_appendsErrorBubble_whenStreamThrowsMidway() {
        usecase.streamThrowsMidway = AgentStreamError.badStatus(code: 500, body: nil)
        let input = makeInput()
        let out = sut.transform(input: input)

        var latest: [ChatBubble] = []
        out.bubbles.drive(onNext: { latest = $0 }).disposed(by: bag)

        input.sendTapped.accept("q")

        let exp = expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        wait(for: [exp], timeout: 2.0)

        XCTAssertEqual(latest.count, 2)
        if case .error = latest[1].kind {} else { XCTFail("expected error bubble") }
    }

    // MARK: - chip

    func test_chipTapped_emitsFillInputText() {
        let input = makeInput()
        let out = sut.transform(input: input)

        var filled: String?
        out.fillInputText.emit(onNext: { filled = $0 }).disposed(by: bag)

        input.chipTapped.accept("추천 질문 1")
        XCTAssertEqual(filled, "추천 질문 1")
    }

    func test_chipTapped_emitsLimitAlert_whenRemainingIsZero_andDoesNotFillInput() {
        usecase._remainingCount = 0
        let input = makeInput()
        let out = sut.transform(input: input)

        var filled: String?
        var alerted = false
        out.fillInputText.emit(onNext: { filled = $0 }).disposed(by: bag)
        out.showLimitAlert.emit(onNext: { alerted = true }).disposed(by: bag)

        input.chipTapped.accept("추천 질문")

        XCTAssertTrue(alerted)
        XCTAssertNil(filled)
    }

    // MARK: - place tap

    func test_placeSelected_emitsRouteToPlaceDetail() {
        let input = makeInput()
        let out = sut.transform(input: input)

        var routed: String?
        out.routeToPlaceDetail.emit(onNext: { routed = $0 }).disposed(by: bag)

        input.placeSelected.accept("PLACE_ID_ABC")
        XCTAssertEqual(routed, "PLACE_ID_ABC")
    }

    // MARK: - retry

    func test_retryTapped_reusesLastQuery() {
        usecase.events = [doneEvent()]
        let input = makeInput()
        _ = sut.transform(input: input)

        input.sendTapped.accept("first-query")

        let exp1 = expectation(description: "wait first")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exp1.fulfill() }
        wait(for: [exp1], timeout: 2.0)

        input.retryTapped.accept(())

        let exp2 = expectation(description: "wait retry")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { exp2.fulfill() }
        wait(for: [exp2], timeout: 2.0)

        XCTAssertEqual(usecase.streamCallCount, 2)
        XCTAssertEqual(usecase.receivedRequests.last?.query, "first-query")
    }

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

    // MARK: - bubblesChange signal

    func test_bubblesChange_emitsInitialAndAppended() {
        let input = makeInput()
        let out = sut.transform(input: input)

        var changes: [BubblesChange] = []
        out.bubblesChange.emit(onNext: { changes.append($0) }).disposed(by: bag)

        input.viewDidLoad.accept(())

        let exp1 = expectation(description: "initial")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp1.fulfill() }
        wait(for: [exp1], timeout: 1.0)

        XCTAssertTrue(changes.contains(where: {
            if case .initial = $0 { return true } else { return false }
        }))

        usecase.events = [doneEvent(answer: "a")]
        input.sendTapped.accept("q")

        let exp2 = expectation(description: "append")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp2.fulfill() }
        wait(for: [exp2], timeout: 2.0)

        XCTAssertTrue(changes.contains(where: {
            if case .appended = $0 { return true } else { return false }
        }))
    }

    // MARK: - pending is not persisted

    func test_pending_isNotPersisted() {
        // mid-way throw로 pending 진입 후 error로 전환되는 상황
        usecase.streamThrowsMidway = AgentStreamError.badStatus(code: 500, body: nil)
        let input = makeInput()
        _ = sut.transform(input: input)

        input.sendTapped.accept("q")

        let exp = expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        wait(for: [exp], timeout: 2.0)

        // pending kind 는 저장 X.
        XCTAssertFalse(historyStore.storedBubbles.contains { bubble in
            if case .pending = bubble.kind { return true } else { return false }
        })
        XCTAssertEqual(historyStore.storedBubbles.count, 2) // user + error
    }

    // MARK: - initial snapshot

    func test_init_loadsSnapshotFromStore_andEmitsBubbles() {
        let freshStore = MockChatHistoryStore()
        let bubble = ChatBubble(kind: .user, text: "이전 질문")
        freshStore.storedBubbles = [bubble]
        freshStore.storedSummary = "prior summary"
        freshStore.storedMessages = [.init(role: .user, content: "이전 질문")]

        sut = ChatBotBottomSheetViewModel(usecase: usecase, historyStore: freshStore)
        let input = makeInput()
        let out = sut.transform(input: input)

        var latest: [ChatBubble] = []
        out.bubbles.drive(onNext: { latest = $0 }).disposed(by: bag)

        XCTAssertEqual(latest.count, 1)
        XCTAssertEqual(latest.first?.text, "이전 질문")
        XCTAssertEqual(freshStore.loadBubblesCalls.count, 1)
        XCTAssertNil(freshStore.loadBubblesCalls[0].beforeOrder)
        XCTAssertEqual(freshStore.loadBubblesCalls[0].limit, 20)
    }

    // MARK: - loadMore

    func test_loadMoreTriggered_fetchesOlderPage_andPrepends() {
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
            if case .prepended(_, let c) = $0 { return c == 5 } else { return false }
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

        XCTAssertTrue(flags.contains(true))
        XCTAssertEqual(flags.last, false)
    }
}
