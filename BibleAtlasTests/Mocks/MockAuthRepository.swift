//
//  MockAuthRepository.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import XCTest
@testable import BibleAtlas


final class MockAuthRepository: AuthRepositoryProtocol{
    var resultToReturn: Result<UserResponse, NetworkError>!
    var withdrawResultToReturn: Result<Int, NetworkError>!
    
    func loginUser(body: BibleAtlas.AuthPayload) async -> Result<BibleAtlas.UserResponse, BibleAtlas.NetworkError> {
        return resultToReturn
    }
    
    func loginGoogleUser(idToken: String) async -> Result<BibleAtlas.UserResponse, BibleAtlas.NetworkError> {
        return resultToReturn
    }
    
    func loginAppleUser(idToken: String) async -> Result<BibleAtlas.UserResponse, BibleAtlas.NetworkError> {
        return resultToReturn
    }
    
    func withdraw() async -> Result<Int, BibleAtlas.NetworkError> {
        return withdrawResultToReturn
    }
}
