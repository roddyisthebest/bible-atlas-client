import Foundation
@testable import BibleAtlas

final class FakeAgentUsecase: AgentUsecaseProtocol {
    var events: [AgentStreamEvent] = []
    var streamThrowsBeforeStart: Error?      // AgentUsecaseError.limitExceeded 등
    var streamThrowsMidway: Error?           // 스트림 도중 throw
    var _remainingCount: Int = 100
    private(set) var streamCallCount = 0
    private(set) var recordUsageCallCount = 0
    private(set) var receivedRequests: [AgentStreamRequest] = []

    var remainingCount: Int { _remainingCount }

    func stream(request: AgentStreamRequest) throws -> AsyncThrowingStream<AgentStreamEvent, Error> {
        streamCallCount += 1
        receivedRequests.append(request)
        if let e = streamThrowsBeforeStart { throw e }
        let events = self.events
        let midError = self.streamThrowsMidway
        return AsyncThrowingStream { continuation in
            Task {
                for e in events {
                    continuation.yield(e)
                }
                if let midError { continuation.finish(throwing: midError); return }
                continuation.finish()
            }
        }
    }

    func recordUsage() {
        recordUsageCallCount += 1
        _remainingCount -= 1
    }
}
