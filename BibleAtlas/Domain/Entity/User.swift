//
//  User.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation

enum UserGrade:String, Decodable {
    case king = "king"
    case normal = "normal"
}


struct User:Decodable, Hashable{
    var id:Int
    var name:String
    var imageURL:String
    var grade:UserGrade
}


struct UserResponse: Decodable {
    let user: User
    let authData: AuthData
}
