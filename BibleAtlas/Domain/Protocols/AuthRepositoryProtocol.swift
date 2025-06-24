//
//  UserRepositoryProtocol.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation

protocol AuthRepositoryProtocol {
    func loginUser(body:AuthPayload) async -> Result<UserResponse,NetworkError>
    
    func loginGoogleUser(idToken: String) async -> Result<UserResponse,NetworkError>
    
}
