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
        case .placeAgent:        return L10n.ChatBot.Progress.placeAgent
        case .bibleGeneralAgent: return L10n.ChatBot.Progress.bibleGeneral
        case .nonBibleReject:    return L10n.ChatBot.Progress.nonBibleReject
        case .rewrite:           return L10n.ChatBot.Progress.rewrite
        case .format:            return L10n.ChatBot.Progress.format
        case .none:              return L10n.ChatBot.Progress.default
        }
    }
}
