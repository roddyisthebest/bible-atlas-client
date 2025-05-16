//
//  Place.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/3/25.
//

import Foundation

enum PlaceStereo:Decodable {
    case parent
    case child
}

struct Place:Decodable{
    var id:String;
    var name:String;
    var isModern:Bool;
    var description:String;
    var koreanDescription:String;
    var stereo:PlaceStereo;
    var verse:String;
    var likeCount:Int;
    var unknownPlacePossibility:Int?
    var types:[PlaceType]
}
