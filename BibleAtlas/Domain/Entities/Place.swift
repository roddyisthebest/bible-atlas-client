//
//  Place.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/3/25.
//

import Foundation




enum PlaceStereo: String, Decodable {
    case parent
    case child
}

enum PlaceName: String, Decodable {
    case river
    case mountainRange = "mountain range"
    case settlement
    case campsite
    case peopleGroup = "people group"
    case region
    case mountain
    case spring
    case hill
    case bodyOfWater = "body of water"
    case road
    case canal
    case valley
    case field
    case mountainPass = "mountain pass"
    case tree
    case mountainRidge = "mountain ridge"
    case wadi
    case well
    case structure
    case naturalArea = "natural area"
    case altar
    case gate
}

struct PlaceType: Decodable {
    var id: Int
    var name: PlaceName
}

struct PlaceTypeWithPlaceCount: Decodable{
    var id: Int
    var name:PlaceName
    var placeCount: Int
}

struct Place: Decodable {
    var id: String
    var name: String
    var isModern: Bool
    var description: String
    var koreanDescription: String
    var stereo: PlaceStereo
    var verse: String
    var likeCount: Int
    var unknownPlacePossibility: Int?
    var types: [PlaceType]
}


struct PlacePrefix:Decodable {
    var prefix: String;
    var placeCount: String;
}
