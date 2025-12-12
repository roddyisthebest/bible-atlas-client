//
//  File.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
@testable import BibleAtlas


final class MockAuthApiService: AuthApiServiceProtocol {
    var calledMethods: [String] = []
    
    func loginUser(body: AuthPayload) async -> Result<UserResponse, NetworkError> {
        calledMethods.append("loginUser")
        return .failure(.invalid)
    }
    
    func loginGoogleUser(idToken: String) async -> Result<UserResponse, NetworkError> {
        calledMethods.append("loginGoogleUser")
        return .failure(.invalid)
    }
    
    func loginAppleUser(idToken: String) async -> Result<UserResponse, NetworkError> {
        calledMethods.append("loginAppleUser")
        return .failure(.invalid)
    }
    
    func withdraw() async -> Result<Int, NetworkError> {
        calledMethods.append("withdraw")
        return .success(200)
    }
}
