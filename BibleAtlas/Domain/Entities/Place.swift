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

enum PlaceTypeName: String, Decodable {
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
    case pool
    case ford
    case island
    case wall
    case archipelago
    case districtInSettlement = "district in settlement"
    case rock
    case garden
    case probabilityCenterRadial = "probability center radial"
    case cave
    case stoneHeap = "stone heap"
    case harb
    case hall
    case intersection
    case cliff
}


enum PlaceSort: String, Decodable {
    case desc = "desc"
    case asc  = "asc"
    case like = "like"
}

struct PlaceType: Decodable {
    var id: Int
    var name: PlaceTypeName
}

struct PlaceTypeWithPlaceCount: Decodable{
    var id: Int
    var name:PlaceTypeName
    var placeCount: Int
}

struct PlaceMemo:Decodable{
    let user: Int;
    let place: String;
    let text: String;
}

struct Place: Decodable {
    var id: String
    var name: String
    var isModern: Bool
    var description: String
    var koreanDescription: String
    var stereo: PlaceStereo
    var verse: String?
    var likeCount: Int
    var unknownPlacePossibility: Int?
    var types: [PlaceType]
    var childRelations: [PlaceRelation]?
    var parentRelations: [PlaceRelation]?
    var isLiked: Bool?
    var isSaved: Bool?
    var memo: PlaceMemo?
    var imageTitle:String?
    var longitude:Double?
    var latitude:Double?
}


struct PlacePrefix:Decodable {
    var prefix: String;
    var placeCount: String;
}

struct PlaceRelation:Decodable{
    var id:Int;
    var place:Place;
    var possibility:Int
}

//struct ParentPlaceRelation:Decodable{
//    var id:Int;
//    var parent:Place;
//    var possibility:Int
//}


struct TogglePlaceSaveResponse:Decodable{
    var saved:Bool
}

struct TogglePlaceLikeResponse:Decodable{
    var liked:Bool
}

struct BibleVerseResponse:Decodable{
    var text:String
}

struct PlaceMemoResponse:Decodable{
    var text:String
}

struct PlaceMemoDeleteResponse:Decodable{
    var memo:String
}

struct PlaceProposalResponse:Decodable{
    var createdAt:String
    var id: Int
    var type: Int
    var comment: String
}

enum BibleVersion: String, Decodable {
    case kor
    case niv
    case bbe
    case asv
}



struct GeoJsonFeatureProperties: Codable {
    let id: String?
    let role: String?
}

struct MyCollectionPlaceIds:Decodable{
    let liked: [String]
    let bookmarked: [String]
    let memoed:[String]
}


