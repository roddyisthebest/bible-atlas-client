//
//  DeepLink.swift
//  BibleAtlas
//
//  Created by 배성연 on 12/24/25.
//

import Foundation

/// Domain-level representation of deep links, independent from UI types.
enum DeepLink {
    case home
    case placeDetail(id: String)
    case bibleBook(book: String)
    case bibleVerseDetail(book: String, keyword: String, placeName: String?)
    case placesByType(typeName: String)
    case placesByCharacter(name: String)
    case myPage
    case recentSearches
    case popularPlaces
    case bibles
    case placeTypes
    case placeCharacters
    case accountManagement
    case report
}
