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
        // 서버가 여러 JSON payload 를 하나의 event 안에 여러 data: 라인으로 보낼 때
        // SSE 스펙대로 \n 조인되면 하나의 큰 문자열이 되지만 유효 JSON 은 아닌 상태가 됨.
        // 방어: 전체 문자열 우선 시도 → 실패 시 마지막 non-empty 라인만 재시도.
        let candidates: [String] = {
            let joined = sse.data
            let lines = joined
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map(String.init)
            if lines.count <= 1 { return [joined] }
            return [joined, lines.last ?? joined]
        }()

        var lastError: Error?
        for candidate in candidates {
            guard let data = candidate.data(using: .utf8) else { continue }
            do {
                return try decodeEvent(name: sse.name, data: data)
            } catch {
                lastError = error
            }
        }

        if let error = lastError {
            #if DEBUG
            print("[AgentRepository] decoding failed event=\(sse.name) error=\(error)\n  raw: \(sse.data)")
            #endif
            throw AgentStreamError.decoding(
                eventName: sse.name,
                message: "\(error)",
                rawData: sse.data
            )
        }
        return nil
    }

    private func decodeEvent(name: String, data: Data) throws -> AgentStreamEvent? {
        switch name {
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
    }
}
