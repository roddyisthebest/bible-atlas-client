//
//  DeepLinkToBottomSheetMapper.swift
//  BibleAtlas
//
//  Created by 배성연 on 12/24/25.
//

import Foundation
// Layer: Presentation > Routing

protocol DeepLinkToBottomSheetMapper {
    func map(_ link: DeepLink) -> BottomSheetType?
}

final class DefaultDeepLinkToBottomSheetMapper: DeepLinkToBottomSheetMapper {
    func map(_ link: DeepLink) -> BottomSheetType? {
        switch link {
        case .home:
            return .home
        case .placeDetail(let id):
            return .placeDetail(id)
        case .bibleBook(let bookString):
            guard let book = BibleBook(rawValue: bookString) else { return nil }
            return .placesByBible(book)
        case .bibleVerseDetail(let bookString, let keyword, let placeName):
            guard let book = BibleBook(rawValue: bookString) else { return nil }
            return .bibleVerseDetail(book, keyword, placeName)
        case .placesByType(let typeNameString):
            guard let type = PlaceTypeName(rawValue: typeNameString) else { return nil }
            return .placesByType(type)
        case .placesByCharacter(let name):
            return .placesByCharacter(name)
        case .myPage:
            return .myPage
        case .recentSearches:
            return .recentSearches
        case .popularPlaces:
            return .popularPlaces
        case .bibles:
            return .bibles
        case .placeTypes:
            return .placeTypes
        case .placeCharacters:
            return .placeCharacters
        case .accountManagement:
            return .accountManagement
        case .report:
            return .report
        }
    }
}

