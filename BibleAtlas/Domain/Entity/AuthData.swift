//
//  AuthData.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation

struct AuthData:Decodable, Hashable{
    let refreshToken:String;
    let accessToken:String;
}

struct AuthPayload:Encodable{
    let userId:String;
    let password:String
}
