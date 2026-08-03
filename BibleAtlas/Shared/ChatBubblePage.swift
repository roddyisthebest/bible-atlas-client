import Foundation

struct ChatBubblePage: Equatable {
    let bubbles: [ChatBubble]     // 오름차순, 최대 limit개
    let hasMore: Bool             // 더 오래된 것이 있는지
    let nextCursor: Int64?        // 다음 loadBubbles(beforeOrder:) 호출용 커서. hasMore=false 이면 nil.
}
