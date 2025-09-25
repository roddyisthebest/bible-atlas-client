//
//  MockTokenProvider.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import XCTest
@testable import BibleAtlas

final class MockTokenProvider: TokenProviderProtocol {
    var accessToken: String? = nil
    var refreshToken: String? = nil
    var hasToken: Bool = false
    
    var didSaveCalled = false
    var savedAccessToken: String?
    var savedRefreshToken: String?
    
    var clearResult: Result<Void, Error>!

    
    func save(accessToken: String, refreshToken: String) {
        didSaveCalled = true;
        savedAccessToken = accessToken
        savedRefreshToken = refreshToken
        
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
    }

    
    func setAccessToken(accessToken: String) {
        self.accessToken = accessToken
    }
    
    func clear() -> Result<Void, Error> {
         accessToken = nil
         refreshToken = nil
         return clearResult
     }

}
