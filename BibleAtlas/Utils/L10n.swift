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
    
}


