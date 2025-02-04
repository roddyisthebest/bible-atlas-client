//
//  AuthUseCase.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation


protocol AuthUsecaseProtocol{
    func loginUser(body:AuthPayload) async -> Result<UserResponse,NetworkError>
    func logout() async -> Result<Bool,NetworkError>
}


public struct AuthUsecase:AuthUsecaseProtocol{
    
    private let repository:AuthRepositoryProtocol;
    
    
    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }
    func loginUser(body: AuthPayload) async -> Result<UserResponse, NetworkError> {
        return await repository.loginUser(body: body)
    }
    
    func logout() async -> Result<Bool, NetworkError> {
        return await repository.logout();
    }
}
