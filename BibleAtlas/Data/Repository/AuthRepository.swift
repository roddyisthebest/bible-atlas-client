//
//  UserRepository.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation

public struct AuthRepository:AuthRepositoryProtocol{
    let authApiService:AuthApiServiceProtocol;
    
    func loginUser(body: AuthPayload) async -> Result<UserResponse, NetworkError> {
        return await authApiService.loginUser(body: body)
    }
    
    func logout() async -> Result<Bool, NetworkError> {
        return await authApiService.logout()
    }
}
