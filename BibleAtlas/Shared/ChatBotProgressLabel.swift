import Foundation

/// 서버에서 오는 노드 이름을 enum 으로 안전하게 매핑.
enum NodeName: String {
    case placeAgent
    case bibleGeneralAgent
    case nonBibleReject
    case rewrite
    case format
}

/// 서버에서 오는 도구 이름 (bible-atlas-agent 스펙).
enum ToolName: String {
    case ancientKeywordSearch     = "ancient_keyword_search"
    case searchAncientPlaces      = "search_ancient_places"
    case searchModernPlaces       = "search_modern_places"
    case searchAncientWithModern  = "search_ancient_with_modern"
    case searchModernWithAncient  = "search_modern_with_ancient"
    case journeyRouteSearch       = "journey_route_search"
    case journeyDescriptionSearch = "journey_description_search"
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

    /// 도구 이름 → 사용자용 진행 문구. 알 수 없는 도구는 기본 폴백.
    static func label(forTool name: String) -> String {
        switch ToolName(rawValue: name) {
        case .ancientKeywordSearch:     return L10n.ChatBot.Tool.ancientKeywordSearch
        case .searchAncientPlaces:      return L10n.ChatBot.Tool.searchAncientPlaces
        case .searchModernPlaces:       return L10n.ChatBot.Tool.searchModernPlaces
        case .searchAncientWithModern:  return L10n.ChatBot.Tool.searchAncientWithModern
        case .searchModernWithAncient:  return L10n.ChatBot.Tool.searchModernWithAncient
        case .journeyRouteSearch:       return L10n.ChatBot.Tool.journeyRouteSearch
        case .journeyDescriptionSearch: return L10n.ChatBot.Tool.journeyDescriptionSearch
        case .none:                     return L10n.ChatBot.Tool.default
        }
    }

    /// 모든 도구가 끝나고 다음 노드를 기다리는 동안 사용.
    static var toolWrapup: String { L10n.ChatBot.Tool.wrapup }
}
