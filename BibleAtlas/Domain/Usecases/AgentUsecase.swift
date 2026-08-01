import Foundation

enum AgentUsecaseError: Error, Equatable {
    case limitExceeded
}

protocol AgentUsecaseProtocol {
    /// 100회 초과 시 즉시 .limitExceeded throw. 그 외에는 repository 로 위임.
    func stream(request: AgentStreamRequest) throws -> AsyncThrowingStream<AgentStreamEvent, Error>
    var remainingCount: Int { get }
    func recordUsage()
}

final class AgentUsecase: AgentUsecaseProtocol {
    static let limit: Int = 100

    private let repository: AgentRepositoryProtocol
    private let counter: ChatUsageCounter

    init(repository: AgentRepositoryProtocol, counter: ChatUsageCounter) {
        self.repository = repository
        self.counter = counter
    }

    var remainingCount: Int {
        max(0, Self.limit - counter.currentCount)
    }

    func stream(request: AgentStreamRequest) throws -> AsyncThrowingStream<AgentStreamEvent, Error> {
        guard remainingCount > 0 else { throw AgentUsecaseError.limitExceeded }
        return repository.stream(request: request)
    }

    func recordUsage() {
        counter.increment()
    }
}
