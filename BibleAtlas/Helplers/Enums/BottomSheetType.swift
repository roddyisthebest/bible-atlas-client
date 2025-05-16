//
//  BottomSheetType.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

import Foundation
import MapKit

enum BottomSheetType {
    case home
    case login
    case myCollection(MyCollectionType)
    case placeDetail(String)
    case memo(String)
    case placeModification(String)
    case placeTypes
    case placeCharacters
    case placesByType(Int)
    case placesByCharacter(String)
}

enum MyCollectionType {
    case favorite
    case save
    case memo
}
