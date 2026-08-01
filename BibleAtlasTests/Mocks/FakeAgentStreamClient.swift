import Foundation
@testable import BibleAtlas

/// 테스트용 fake. 미리 정한 SSEEvent 배열을 순차 방출 (또는 error throw).
final class FakeAgentStreamClient: AgentStreamClientProtocol {
    enum Behavior {
        case events([SSEEvent])           // 이 배열을 순서대로 yield 후 finish
        case throwsError(Error)           // 즉시 throw
    }

    var behavior: Behavior = .events([])
    private(set) var receivedRequests: [AgentStreamRequest] = []

    func stream(request: AgentStreamRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        receivedRequests.append(request)
        let behavior = self.behavior
        return AsyncThrowingStream { continuation in
            Task {
                switch behavior {
                case .events(let events):
                    for e in events {
                        continuation.yield(e)
                    }
                    continuation.finish()
                case .throwsError(let error):
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
