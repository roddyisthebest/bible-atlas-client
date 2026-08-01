import Foundation

struct ChatSessionState: Equatable {
    var summary: String?
    var messages: [ChatMessage]

    init(summary: String? = nil, messages: [ChatMessage] = []) {
        self.summary = summary
        self.messages = messages
    }
}
