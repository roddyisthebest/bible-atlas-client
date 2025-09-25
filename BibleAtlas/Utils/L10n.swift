//
//  L10n.swift
//  BibleAtlas
//
//  Created by 배성연 on 9/23/25.
//

import Foundation


extension String {
    var localized: String { NSLocalizedString(self, comment: "") }
    func localized(_ args: CVarArg...) -> String { String(format: self.localized, arguments: args) }
}

enum L10n {
    
    enum Home{
        static let searchPlaceholderKey = "Home.SearchPlaceholder"
        static let loginKey = "Home.Login"
        static let cancelKey = "Home.Cancel"
        
        static var searchPlaceholder: String { searchPlaceholderKey.localized }
        static var login: String { loginKey.localized }
        static var cancel: String { cancelKey.localized }
    }
    
    enum HomeContent{
        // Section titles
        static let collectionsKey = "HomeContent.Collections"
        static let recentKey = "HomeContent.Recent"
        static let myGuidesKey = "HomeContent.MyGuides"
        
        static var collections: String { collectionsKey.localized }
        static var recent: String { recentKey.localized }
        static var myGuides: String { myGuidesKey.localized }
        
        // Collection buttons
        static let favoritesKey = "HomeContent.Favorites"
        static let bookmarksKey = "HomeContent.Bookmarks"
        static let memosKey = "HomeContent.Memos"
        static var favorites: String { favoritesKey.localized }
        static var bookmarks: String { bookmarksKey.localized }
        static var memos: String { memosKey.localized }
        
        
        
        // Recent area
        static let moreKey = "HomeContent.More"
        static let recentEmptyKey = "HomeContent.RecentEmpty"
        static var more: String { moreKey.localized }
        static var recentEmpty: String { recentEmptyKey.localized }
        
        // Guides + menu
        static let explorePlacesKey = "HomeContent.ExplorePlaces"
        static var explorePlaces: String { explorePlacesKey.localized }
        
        static let menuTitleKey = "HomeContent.ExploreMenu.Title"
        static let menuAZKey = "HomeContent.ExploreMenu.AZ"
        static let menuByTypeKey = "HomeContent.ExploreMenu.ByType"
        static let menuByBibleKey = "HomeContent.ExploreMenu.ByBible"
        
        static var menuTitle: String { menuTitleKey.localized }
        static var menuAZ: String { menuAZKey.localized }
        static var menuByType: String { menuByTypeKey.localized }
        static var menuByBible: String { menuByBibleKey.localized }
        
        
    }
    
    
    enum SearchResult {
        static let emptyKey = "SearchResult.Empty"
        static var empty: String { emptyKey.localized }
    }
    
    enum SearchReady {
        static let popularKey = "SearchReady.Popular"
        static let popularEmptyKey = "SearchReady.PopularEmpty"
        static let recentKey = "SearchReady.Recent"
        static let moreKey = "SearchReady.More"

        static var popular: String { popularKey.localized }
        static var popularEmpty: String { popularEmptyKey.localized }
        static var recent: String { recentKey.localized }
        static var more: String { moreKey.localized }
    }
    
    enum Bibles{
        static let titleKey = "Bibles.Title"
        static let emptyKey = "Bibles.Empty"
        static let fetchErrorMessageKey = "Bibles.FetchErrorMessage"

        static var title: String { titleKey.localized }
        static var empty: String { emptyKey.localized }
        static var fetchErrorMessage: String { fetchErrorMessageKey.localized }
    }
    
    enum PlacesByBible{
        static let titleKey = "PlacesByBible.Title"
        static let emptyKey = "PlacesByBible.Empty"
        
        static func title(_ bibleBookName: String) -> String {
            titleKey.localized(bibleBookName)
        }
        
        static var empty:String {emptyKey.localized}
    }
    
    enum Common {
        static let retryKey = "Common.Retry"
        static var retry: String { retryKey.localized }
        
        
        static let defaultErrorMessageKey = "Common.DefaultErrorMessage"
        static var defaultErrorMessage: String { defaultErrorMessageKey.localized }
        
        static var closeKey = "Common.Close"
        static var close: String { closeKey.localized }
        
        // Count (stringsdict로 복수형 처리)
        static func placesCount(_ n: Int) -> String {
            // "Home.PlacesCount" = "%d places" | "장소 %d개" 등
            "Common.PlacesCount".localized(n)
        }
    
    }
    
    enum PlaceDetail {
            // Keys
        static let backKey = "PlaceDetail.Back"
        static let placeTypeKey = "PlaceDetail.PlaceType"
        static let ancientKey = "PlaceDetail.Ancient"
        static let modernKey = "PlaceDetail.Modern"

        static let descriptionKey = "PlaceDetail.Description"
        static let relatedPlacesKey = "PlaceDetail.RelatedPlaces"
        static let relatedPlacesEmptyKey = "PlaceDetail.RelatedPlacesEmpty"
        static let relatedVersesKey = "PlaceDetail.RelatedVerses"
        static let relatedVersesEmptyKey = "PlaceDetail.RelatedVersesEmpty"

        static let reportIssueKey = "PlaceDetail.ReportIssue"
        static let addMemoKey = "PlaceDetail.AddMemo"
        static let requestEditKey = "PlaceDetail.RequestEdit"

        static let reportMenuTitleKey = "PlaceDetail.ReportMenuTitle"
        static let reportSpamKey = "PlaceDetail.Report.Spam"
        static let reportInappropriateKey = "PlaceDetail.Report.Inappropriate"
        static let reportFalseInfoKey = "PlaceDetail.Report.FalseInfo"
        static let reportOtherKey = "PlaceDetail.Report.Other"

        static let okKey = "PlaceDetail.OK"
        static let likesFmtKey = "PlaceDetail.LikesFmt" // "%d Likes"

            // Values
        static var back: String { backKey.localized }
        static var placeType: String { placeTypeKey.localized }
        static var ancient: String { ancientKey.localized }
        static var modern: String { modernKey.localized }

        static var description: String { descriptionKey.localized }
        static var relatedPlaces: String { relatedPlacesKey.localized }
        static var relatedPlacesEmpty: String { relatedPlacesEmptyKey.localized }
        static var relatedVerses: String { relatedVersesKey.localized }
        static var relatedVersesEmpty: String { relatedVersesEmptyKey.localized }

        static var reportIssue: String { reportIssueKey.localized }
        static var addMemo: String { addMemoKey.localized }
        static var requestEdit: String { requestEditKey.localized }

        static var reportMenuTitle: String { reportMenuTitleKey.localized }
        static var reportSpam: String { reportSpamKey.localized }
        static var reportInappropriate: String { reportInappropriateKey.localized }
        static var reportFalseInfo: String { reportFalseInfoKey.localized }
        static var reportOther: String { reportOtherKey.localized }

        static var ok: String { okKey.localized }

        static func likes(_ n: Int) -> String { likesFmtKey.localized(n) }
        }
    
    
    enum PlaceTypes {
        // Keys
        static let titleKey = "PlaceTypes.Title"   // 타입명이 아직 없을 때
        static let emptyKey = "PlaceTypes.Empty"                   // 목록 비었을 때

        // Values
        static var title: String { titleKey.localized }
        static var empty: String { emptyKey.localized }
    }
    
    enum PlaceCharacters{
        // Keys
        static let titleKey = "PlaceCharacters.Title"   // 타입명이 아직 없을 때
        static let emptyKey = "PlaceCharacters.Empty"                   // 목록 비었을 때

        // Values
        static var title: String { titleKey.localized }
        static var empty: String { emptyKey.localized }
    }
    
    enum PlacesByCharacter {
        // Keys
        static let titleKey = "PlacesByCharacter.Title"
        static let emptyKey = "PlacesByCharacter.Empty"

        
        // Values
        static func title(_ char: String) -> String { titleKey.localized(char) }
        static var empty: String { emptyKey.localized }
        
    }
}


