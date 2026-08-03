import Foundation

struct ChatHistorySnapshot: Equatable {
    let summary: String?
    let messages: [ChatMessage]
    let firstPage: ChatBubblePage
}
