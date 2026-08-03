import Foundation
@testable import BibleAtlas

final class MockChatHistoryStore: ChatHistoryStoreProtocol {
    // 저장 상태
    var storedSummary: String?
    var storedMessages: [ChatMessage] = []
    var storedBubbles: [ChatBubble] = []          // 오래된 → 최신 순 (order asc)

    // 호출 카운터/기록
    private(set) var appendBubbleCallCount = 0
    private(set) var updateContextCallCount = 0
    private(set) var loadBubblesCalls: [(beforeOrder: Int64?, limit: Int)] = []
    private(set) var clearCallCount = 0

    // 최근 인자
    private(set) var lastAppendedBubble: ChatBubble?
    private(set) var lastUpdateContext: (summary: String?, messages: [ChatMessage])?

    func loadSummary() -> String? { storedSummary }
    func loadMessages() -> [ChatMessage] { storedMessages }

    func updateContext(summary: String?, messages: [ChatMessage]) {
        updateContextCallCount += 1
        lastUpdateContext = (summary, messages)
        storedSummary = summary
        storedMessages = messages
    }

    func loadBubbles(beforeOrder: Int64?, limit: Int) -> ChatBubblePage {
        loadBubblesCalls.append((beforeOrder, limit))
        let cutoff: Int
        if let before = beforeOrder {
            cutoff = min(Int(before), storedBubbles.count)
        } else {
            cutoff = storedBubbles.count
        }
        let start = max(0, cutoff - limit)
        let slice = Array(storedBubbles[start..<cutoff])
        let hasMore = start > 0
        let nextCursor: Int64? = hasMore ? Int64(start) : nil
        return ChatBubblePage(bubbles: slice, hasMore: hasMore, nextCursor: nextCursor)
    }

    func appendBubble(_ bubble: ChatBubble) {
        appendBubbleCallCount += 1
        lastAppendedBubble = bubble
        storedBubbles.append(bubble)
    }

    func clear() {
        clearCallCount += 1
        storedSummary = nil
        storedMessages = []
        storedBubbles = []
    }
}
