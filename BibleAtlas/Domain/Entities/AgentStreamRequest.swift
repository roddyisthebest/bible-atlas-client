import Foundation

struct AgentStreamRequest: Encodable {
    let query: String
    let summary: String?
    let messages: [ChatMessage]
}
