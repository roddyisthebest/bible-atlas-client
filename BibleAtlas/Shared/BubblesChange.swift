import Foundation

/// tableView 갱신을 위한 이벤트. 새 bubbles 배열을 함께 전달해
/// VC 가 datasource(`self.bubbles`) 갱신을 performBatchUpdates block
/// 내부에서 원자적으로 처리할 수 있게 한다.
enum BubblesChange: Equatable {
    case initial(bubbles: [ChatBubble])                      // 초기 로드 → scrollToBottom
    case appended(bubbles: [ChatBubble])                     // 새 메시지 append → scrollToBottom
    case prepended(bubbles: [ChatBubble], count: Int)        // load-more → insertRows + 앵커 보정
}
