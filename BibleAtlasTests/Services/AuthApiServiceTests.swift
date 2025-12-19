//
//  AuthApiServiceTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/3/25.
//

import XCTest
import Alamofire
@testable import BibleAtlas

enum HttpMethodCaptured {
    case get, post, put, patch, delete
}



final class AuthApiServiceTests:XCTestCase {
    
    private var sut: AuthApiService!
    private var mockAuthorizedApiClient:MockAuthorizedApiClient!
    
        
    override func setUp(){
        super.setUp()
        mockAuthorizedApiClient = MockAuthorizedApiClient();
        sut = AuthApiService(apiClient: mockAuthorizedApiClient, url: "https://api.bibleatlas.app")
    }
   
    func test_loginUser_shouldSetBasicAuthHeaderAndCorrectURL() async {
        // given
        let payload = AuthPayload(userId: "abc", password: "123")
        
        // when
        _ = await sut.loginUser(body: payload)
        
        // then
        let expectedCredential = "abc:123".data(using: .utf8)!.base64EncodedString()
        
        XCTAssertEqual(mockAuthorizedApiClient.lastHeaders?["Authorization"], "Basic \(expectedCredential)")
        XCTAssertEqual(mockAuthorizedApiClient.lastRequestURL, "https://api.bibleatlas.app/login")
    }
    
    
    func test_loginGoogleUser_shouldSetJsonBodyAndHeader() async {
        let mockClient = MockAuthorizedApiClient()
        let sut = AuthApiService(apiClient: mockClient, url: "https://api.example.com")

        _ = await sut.loginGoogleUser(idToken: "dummy_token")

        XCTAssertEqual(mockClient.lastRequestURL, "https://api.example.com/google-login")
        XCTAssertEqual(mockClient.lastHeaders?["Content-Type"], "application/json")

        let body = try! JSONSerialization.jsonObject(with: mockClient.lastBody!, options: []) as! [String: String]
        XCTAssertEqual(body["idToken"], "dummy_token")
    }
    
    func test_withdraw_shouldCallDeleteWithCorrectURL() async {
        let mockClient = MockAuthorizedApiClient()
        let sut = AuthApiService(apiClient: mockClient, url: "https://api.example.com")

        _ = await sut.withdraw()

        XCTAssertEqual(mockClient.lastRequestURL, "https://api.example.com/withdraw")
        XCTAssertEqual(mockClient.lastMethodCalled, .delete)
    }
    
}
