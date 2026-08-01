import Foundation
@testable import BibleAtlas

final class FakeAgentRepository: AgentRepositoryProtocol {
    var events: [AgentStreamEvent] = []
    var errorToThrow: Error?
    private(set) var streamCallCount = 0
    private(set) var receivedRequests: [AgentStreamRequest] = []

    func stream(request: AgentStreamRequest) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        streamCallCount += 1
        receivedRequests.append(request)
        let events = self.events
        let error = self.errorToThrow
        return AsyncThrowingStream { continuation in
            Task {
                if let error {
                    continuation.finish(throwing: error)
                    return
                }
                for e in events { continuation.yield(e) }
                continuation.finish()
            }
        }
    }
}
