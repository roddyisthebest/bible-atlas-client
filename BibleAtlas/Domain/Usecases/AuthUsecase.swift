//
//  AuthUseCase.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation


protocol AuthUsecaseProtocol{
    func loginUser(body:AuthPayload) async -> Result<UserResponse,NetworkError>
    func logout() -> Result<Bool, Error>
    
    func loginGoogleUser(idToken: String) async -> Result<UserResponse,NetworkError>
    func loginAppleUser(idToken: String) async -> Result<UserResponse,NetworkError>
}


public struct AuthUsecase:AuthUsecaseProtocol{

    private let repository:AuthRepositoryProtocol;
    private let tokenProvider: TokenProviderProtocol

    
    init(repository: AuthRepositoryProtocol, tokenProvider:TokenProviderProtocol) {
        self.repository = repository
        self.tokenProvider = tokenProvider
    }
    
    func loginUser(body: AuthPayload) async -> Result<UserResponse, NetworkError> {
        let result = await repository.loginUser(body: body)
        
        if case let .success(response) = result {
            tokenProvider.save(
                accessToken: response.authData.accessToken,
                refreshToken: response.authData.refreshToken
            )
        }
        
        return result;
    }
    
    func loginGoogleUser(idToken: String) async -> Result<UserResponse, NetworkError> {
        let result = await repository.loginGoogleUser(idToken: idToken);
        
        if case let .success(response) = result {
            tokenProvider.save(
                accessToken: response.authData.accessToken,
                refreshToken: response.authData.refreshToken
            )
        }
        
        return result;
    }
    
    
    func loginAppleUser(idToken: String) async -> Result<UserResponse, NetworkError> {
        let result = await repository.loginAppleUser(idToken: idToken);
        
        if case let .success(response) = result {
            tokenProvider.save(
                accessToken: response.authData.accessToken,
                refreshToken: response.authData.refreshToken
            )
        }
        
        return result;
    }
    
    
    
    
    func logout() -> Result<Bool, Error>{
        return tokenProvider.clear()
    }
}
