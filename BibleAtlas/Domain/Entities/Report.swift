//
//  Report.swift
//  BibleAtlas
//
//  Created by 배성연 on 11/15/25.
//

import Foundation

enum ReportType: String, Codable {
    case bugReport = "BUG_REPORT"
    case featureRequest = "FEATURE_REQUEST"
    case uiUxIssue = "UI_UX_ISSUE"
    case performanceIssue = "PERFORMANCE_ISSUE"
    case dataError = "DATA_ERROR"
    case loginIssue = "LOGIN_ISSUE"
    case searchIssue = "SEARCH_ISSUE"
    case mapIssue = "MAP_ISSUE"
    case generalFeedback = "GENERAL_FEEDBACK"
    case other = "OTHER"
}

struct Report:Decodable{
    var type:ReportType
    var comment:String
    var creator: User?
    
    var createdAt: String
    var updatedAt: String
    var deletedAt: String?
    
    var version: Int
    var id: Int
}



extension ReportType {
    var localizedTitle: String {
        switch self {
        case .bugReport:        return L10n.Report.Types.bugReport
        case .featureRequest:   return L10n.Report.Types.featureRequest
        case .uiUxIssue:        return L10n.Report.Types.uiUxIssue
        case .performanceIssue: return L10n.Report.Types.performanceIssue
        case .dataError:        return L10n.Report.Types.dataError
        case .loginIssue:       return L10n.Report.Types.loginIssue
        case .searchIssue:      return L10n.Report.Types.searchIssue
        case .mapIssue:         return L10n.Report.Types.mapIssue
        case .generalFeedback:  return L10n.Report.Types.generalFeedback
        case .other:            return L10n.Report.Types.other
        }
    }
}
