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
                    outer: for try await sse in client.stream(request: request) {
                        let mapped = try mapEvents(sse)
                        for event in mapped {
                            continuation.yield(event)
                            if case .done = event { break outer }
                            if case .failure = event { break outer }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private struct ToolDto: Decodable {
        let id: String
        let name: String
        let phase: ToolPhase
    }

    /// 하나의 SSE 이벤트가 여러 JSON payload 를 담고 있을 수 있음 (서버가 여러 data: 라인을 사용).
    /// 각 라인을 개별 이벤트로 해석해서 순서대로 반환한다.
    /// - 정상 케이스 (라인 하나): sse.name 기준으로 매핑.
    /// - 다중 라인: 각 JSON 의 형태로 event 종류를 추론 (node/done/error).
    private func mapEvents(_ sse: SSEEvent) throws -> [AgentStreamEvent] {
        let lines = sse.data
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)

        if lines.count <= 1 {
            guard let data = sse.data.data(using: .utf8) else { return [] }
            do {
                if let event = try decodeEvent(name: sse.name, data: data) {
                    return [event]
                }
                return []
            } catch {
                #if DEBUG
                print("[AgentRepository] decoding failed event=\(sse.name) error=\(error)\n  raw: \(sse.data)")
                #endif
                throw AgentStreamError.decoding(
                    eventName: sse.name,
                    message: "\(error)",
                    rawData: sse.data
                )
            }
        }

        // 다중 라인: JSON shape 로 type 추론. 알 수 없는 라인은 조용히 무시.
        var out: [AgentStreamEvent] = []
        for line in lines {
            guard let data = line.data(using: .utf8) else { continue }
            if let inferred = inferEvent(from: data) {
                out.append(inferred)
            }
        }
        if out.isEmpty {
            #if DEBUG
            print("[AgentRepository] multi-line event yielded no recognizable payload. raw: \(sse.data)")
            #endif
            throw AgentStreamError.decoding(
                eventName: sse.name,
                message: "no recognizable JSON payload in multi-line event",
                rawData: sse.data
            )
        }
        return out
    }

    private func decodeEvent(name: String, data: Data) throws -> AgentStreamEvent? {
        switch name {
        case "node":
            struct Dto: Decodable { let node: String }
            return .node(name: try decoder.decode(Dto.self, from: data).node)
        case "tool":
            let dto = try decoder.decode(ToolDto.self, from: data)
            return .tool(id: dto.id, name: dto.name, phase: dto.phase)
        case "done":
            return .done(try decoder.decode(AgentDonePayload.self, from: data))
        case "error":
            struct Dto: Decodable { let detail: String }
            return .failure(message: try decoder.decode(Dto.self, from: data).detail)
        default:
            return nil
        }
    }

    /// JSON 형태를 보고 이벤트 종류 추론. 우선순위: done → tool → node → error.
    private func inferEvent(from data: Data) -> AgentStreamEvent? {
        if let payload = try? decoder.decode(AgentDonePayload.self, from: data) {
            return .done(payload)
        }
        if let dto = try? decoder.decode(ToolDto.self, from: data) {
            return .tool(id: dto.id, name: dto.name, phase: dto.phase)
        }
        struct NodeDto: Decodable { let node: String }
        if let dto = try? decoder.decode(NodeDto.self, from: data) {
            return .node(name: dto.node)
        }
        struct ErrorDto: Decodable { let detail: String }
        if let dto = try? decoder.decode(ErrorDto.self, from: data) {
            return .failure(message: dto.detail)
        }
        return nil
    }
}
