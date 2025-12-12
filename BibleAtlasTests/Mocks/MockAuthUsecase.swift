//
//  MockAuthUsecase.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/10/25.
//

import Foundation
import XCTest
@testable import BibleAtlas



final class MockAuthUsecase: AuthUsecaseProtocol {
    
    var loginResultToReturn: Result<UserResponse, NetworkError>?
    var logoutResultToReturn: Result<Void, Error>?
    var withdrawResultToReturn: Result<Int, NetworkError>?
    
    var completedExp: XCTestExpectation?      // local login
    var googleCompletedExp: XCTestExpectation?
    var appleCompletedExp: XCTestExpectation?
    
    func loginUser(body: BibleAtlas.AuthPayload) async -> Result<BibleAtlas.UserResponse, BibleAtlas.NetworkError> {
        defer { completedExp?.fulfill() }
        return loginResultToReturn ?? .failure(.clientError("test-error"))
    }
    
    func logout() -> Result<Void, Error> {
        return logoutResultToReturn ?? .failure(NSError(domain: "Test", code: 1))
    }
    
    func loginGoogleUser(idToken: String) async -> Result<BibleAtlas.UserResponse, BibleAtlas.NetworkError> {
        defer { googleCompletedExp?.fulfill() }
        return loginResultToReturn ?? .failure(.clientError("test-error"))
    }
    
    func loginAppleUser(idToken: String) async -> Result<BibleAtlas.UserResponse, BibleAtlas.NetworkError> {
        defer { appleCompletedExp?.fulfill() }
        return loginResultToReturn ?? .failure(.clientError("test-error"))
    }
    
    func withdraw() async -> Result<Int, BibleAtlas.NetworkError> {
        return withdrawResultToReturn ?? .failure(.clientError("test-error"))
    }
}
