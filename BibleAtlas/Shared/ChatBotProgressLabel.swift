import Foundation

/// 서버에서 오는 노드 이름을 enum 으로 안전하게 매핑.
enum NodeName: String {
    case placeAgent
    case bibleGeneralAgent
    case nonBibleReject
    case rewrite
    case format
}

enum ChatBotProgressLabel {
    /// 노드 이름 → 사용자용 진행 문구. 알 수 없는 이름은 기본값.
    static func label(forNode name: String) -> String {
        switch NodeName(rawValue: name) {
        case .placeAgent:        return "성경 지명·여정을 찾는 중…"
        case .bibleGeneralAgent: return "성경 내용을 정리하는 중…"
        case .nonBibleReject:    return "질문을 확인하는 중…"
        case .rewrite:           return "답변을 보완하는 중…"
        case .format:            return "답변을 정리하는 중…"
        case .none:              return "처리 중…"
        }
    }
}
