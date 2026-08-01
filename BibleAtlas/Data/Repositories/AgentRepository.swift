import Foundation

final class AgentRepository: AgentRepositoryProtocol {
    private let client: AgentStreamClientProtocol
    private let decoder = JSONDecoder()

    init(client: AgentStreamClientProtocol) {
        self.client = client
    }

    func stream(request: AgentStreamRequest) -> AsyncThrowingStream<AgentStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await sse in client.stream(request: request) {
                        guard let mapped = try mapEvent(sse) else { continue }
                        continuation.yield(mapped)
                        if case .done = mapped { break }
                        if case .failure = mapped { break }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func mapEvent(_ sse: SSEEvent) throws -> AgentStreamEvent? {
        guard let data = sse.data.data(using: .utf8) else { return nil }
        do {
            switch sse.name {
            case "node":
                struct Dto: Decodable { let node: String }
                return .node(name: try decoder.decode(Dto.self, from: data).node)
            case "done":
                return .done(try decoder.decode(AgentDonePayload.self, from: data))
            case "error":
                struct Dto: Decodable { let detail: String }
                return .failure(message: try decoder.decode(Dto.self, from: data).detail)
            default:
                return nil
            }
        } catch {
            throw AgentStreamError.decoding(
                eventName: sse.name,
                message: (error as NSError).localizedDescription
            )
        }
    }
}
