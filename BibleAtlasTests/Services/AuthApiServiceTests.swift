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

final class MockAuthorizedApiClient: AuthorizedApiClientProtocol {
    var lastRequestURL: String?
    var lastHeaders: HTTPHeaders?
    var lastBody: Data?
    var lastMethodCalled:HttpMethodCaptured!
    var postResult: Result<UserResponse, NetworkError> = .failure(.invalid)
    var deleteResult: Result<Int, NetworkError> = .success(200)

    func postData<T>(
        url: String,
        parameters: Parameters?,
        body: Data?,
        headers: HTTPHeaders?
    ) async -> Result<T, NetworkError> where T : Decodable {
        self.lastRequestURL = url
        self.lastBody = body
        self.lastHeaders = headers
        self.lastMethodCalled = .post
        return postResult as! Result<T, NetworkError>
    }

    // 나머지는 필요 없어도 미리 stub
    func getData<T>(url: String, parameters: Parameters?) async -> Result<T, NetworkError> where T : Decodable {
        fatalError()
    }

    func getRawData(url: String, parameters: Parameters?) async -> Result<Data, NetworkError> {
        fatalError()
    }

    func updateData<T>(url: String, method: HTTPMethod, parameters: Parameters?, body: Data?) async -> Result<T, NetworkError> where T : Decodable {
        fatalError()
    }

    func deleteData<T>(url: String, parameters: Parameters?) async -> Result<T, NetworkError> where T : Decodable {
        lastRequestURL = url
        lastMethodCalled = .delete
        return deleteResult as! Result<T, NetworkError>
    }
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
