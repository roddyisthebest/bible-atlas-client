//
//  TokenProvider.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/17/25.
//

enum TokenType {
    case access
    case refresh
}

protocol TokenProviderProtocol {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    func save(accessToken: String, refreshToken: String)
    func setAccessToken(accessToken: String)
    func clear() -> Result<Bool, Error>
    var hasToken:Bool { get }
}
