//
//  User.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation

enum UserRole:Int, Decodable {
    case SUPER
    case POWER_EXPERT
    case EXPERT
    case USER
}

struct User:Decodable, Hashable{
    var createdAt: String?
    var updatedAt: String?
    var deletedAt: String?
    var version: Int?
    var id:Int
    var name:String?
    var email:String?
    var role:UserRole
    var avatar:String
}


struct UserResponse: Decodable {
    let user: User
    let authData: AuthData
    let recovered: Bool
}



struct RelatedUserInfo:Decodable{
    let isLiked: Bool
    let isSaved: Bool
    let memo: PlaceMemo?
    
}
