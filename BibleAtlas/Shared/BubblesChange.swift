import Foundation

enum BubblesChange: Equatable {
    case initial                    // 초기 로드 → scrollToBottom
    case appended                   // 새 메시지 append → scrollToBottom
    case prepended(count: Int)      // load-more → 오프셋 보정으로 위치 보존
}
