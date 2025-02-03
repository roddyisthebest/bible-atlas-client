//
//  UserRepository.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation

public struct AuthRepository:AuthRepositoryProtocol{
    let networkManager:AuthNetworkManagerProtocol;
    
    init(networkManager: AuthNetworkManagerProtocol) {
        self.networkManager = networkManager
    }
    
    func loginUser(body: AuthPayload) async -> Result<UserResponse, NetworkError> {
        return await networkManager.loginUser(body: body)
    }
    
    func logout() async -> Result<Bool, NetworkError> {
        return await networkManager.logout()
    }
}
