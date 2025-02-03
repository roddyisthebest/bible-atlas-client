//
//  AccessTokenManager.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation


protocol AuthManagerProtocol {
    var accessToken: String? { get set }
}

class AuthManager: AuthManagerProtocol {
    static let shared = AuthManager()
    
    var accessToken: String? = nil
    
    private init() {}  // 싱글톤 유지
}


