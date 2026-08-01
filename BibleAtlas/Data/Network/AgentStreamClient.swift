import Foundation

protocol AgentStreamClientProtocol {
    func stream(request: AgentStreamRequest) -> AsyncThrowingStream<SSEEvent, Error>
}

enum AgentStreamError: Error, Equatable {
    case badStatus(code: Int, body: String?)
    case invalidResponse
    case decoding(eventName: String, message: String)

    static func == (lhs: AgentStreamError, rhs: AgentStreamError) -> Bool {
        switch (lhs, rhs) {
        case let (.badStatus(a, ab), .badStatus(b, bb)): return a == b && ab == bb
        case (.invalidResponse, .invalidResponse): return true
        case let (.decoding(an, am), .decoding(bn, bm)): return an == bn && am == bm
        default: return false
        }
    }
}

final class AgentStreamClient: AgentStreamClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let apiKeyProvider: () -> String

    init(baseURL: URL,
         apiKeyProvider: @escaping () -> String,
         session: URLSession = .shared) {
        self.session = session
        self.baseURL = baseURL
        self.apiKeyProvider = apiKeyProvider
    }

    /// POST /stream 로 SSE 스트리밍. AsyncThrowingStream 으로 SSEEvent 순차 방출.
    /// Task 취소 시 스트림도 종료 → 서버 연결 close.
    func stream(request: AgentStreamRequest) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let urlRequest = try buildURLRequest(request)
                    let (bytes, response) = try await session.bytes(for: urlRequest)

                    guard let http = response as? HTTPURLResponse else {
                        throw AgentStreamError.invalidResponse
                    }
                    guard (200..<300).contains(http.statusCode) else {
                        throw AgentStreamError.badStatus(code: http.statusCode, body: nil)
                    }

                    let parser = SSELineParser()
                    for try await line in bytes.lines {
                        try Task.checkCancellation()
                        if let event = parser.consume(line: line) {
                            continuation.yield(event)
                        }
                    }
                    if let final = parser.flush() { continuation.yield(final) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func buildURLRequest(_ req: AgentStreamRequest) throws -> URLRequest {
        var r = URLRequest(url: baseURL.appendingPathComponent("stream"))
        r.httpMethod = "POST"
        r.setValue(apiKeyProvider(), forHTTPHeaderField: "X-API-Key")
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        r.timeoutInterval = 60      // idle timeout
        r.httpBody = try JSONEncoder().encode(req)
        return r
    }
}
