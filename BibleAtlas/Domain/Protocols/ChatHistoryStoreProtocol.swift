import Foundation

protocol ChatHistoryStoreProtocol {
    // Context (서버 컨텍스트)
    func loadSummary() -> String?
    func loadMessages() -> [ChatMessage]
    func updateContext(summary: String?, messages: [ChatMessage])

    // Bubbles (페이지 단위)
    func loadBubbles(beforeOrder: Int64?, limit: Int) -> ChatBubblePage
    func appendBubble(_ bubble: ChatBubble)

    // 유틸
    func clear()
}
