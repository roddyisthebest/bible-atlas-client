import XCTest
@testable import BibleAtlas

final class AgentUsecaseTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "AgentUsecaseTests.suite"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeSUT(repo: AgentRepositoryProtocol = FakeAgentRepository()) -> AgentUsecase {
        AgentUsecase(repository: repo, counter: ChatUsageCounter(defaults: defaults))
    }

    private func req() -> AgentStreamRequest {
        AgentStreamRequest(query: "q", summary: nil, messages: [])
    }

    func test_remainingCount_initiallyEqualsLimit() {
        XCTAssertEqual(makeSUT().remainingCount, AgentUsecase.limit)
    }

    func test_stream_delegatesToRepository_whenBelowLimit() async throws {
        let repo = FakeAgentRepository()
        repo.events = []
        let sut = makeSUT(repo: repo)
        let stream = try sut.stream(request: req())
        for try await _ in stream {}
        XCTAssertEqual(repo.streamCallCount, 1)
    }

    func test_stream_throwsLimitExceeded_whenCounterAtLimit() {
        for _ in 0..<AgentUsecase.limit { ChatUsageCounter(defaults: defaults).increment() }
        let sut = makeSUT()
        XCTAssertThrowsError(try sut.stream(request: req())) { error in
            XCTAssertEqual(error as? AgentUsecaseError, .limitExceeded)
        }
    }

    func test_recordUsage_incrementsCounter() {
        let sut = makeSUT()
        XCTAssertEqual(sut.remainingCount, AgentUsecase.limit)
        sut.recordUsage()
        XCTAssertEqual(sut.remainingCount, AgentUsecase.limit - 1)
    }

    func test_stream_doesNotAutomaticallyIncrementCounter() async throws {
        let repo = FakeAgentRepository()
        repo.events = [.done(.init(answer: "a", placeIdMap: [:], recommendedQuestions: [], summary: nil, messages: []))]
        let sut = makeSUT(repo: repo)
        let stream = try sut.stream(request: req())
        for try await _ in stream {}
        // recordUsage() 는 VM 이 명시적으로 호출. usecase 는 자동 증가 안 함.
        XCTAssertEqual(sut.remainingCount, AgentUsecase.limit)
    }
}
