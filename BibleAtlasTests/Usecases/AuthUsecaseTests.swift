//
//  AuthUsecaseTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/3/25.
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

final class AuthUsecaseTests:XCTestCase {
    
    private var sut: AuthUsecase! // system under test
    private var mockRepo: MockAuthRepository!
    private var mockTokenProvider: MockTokenProvider!
    
    
    override func setUp() {
        super.setUp()
        mockRepo = MockAuthRepository()
        mockTokenProvider = MockTokenProvider()
        sut = AuthUsecase(repository: mockRepo, tokenProvider: mockTokenProvider)
    }
    
    
    func test_loginUser_success_savesToken() async{
        let expectedAccessToken = "abc123"
        let expectedRefreshToken = "xyz789"
        let userId = "test@naver.com"
        
        let authData = AuthData(refreshToken: expectedRefreshToken, accessToken: expectedAccessToken)
        
        
        mockRepo.resultToReturn = .success(
            UserResponse(
                user:User(id:1, name:"test", role: .USER, avatar: "test"),
                authData: authData,
                recovered: false
            )
        )
        
        let payload = AuthPayload(userId: userId, password: "1234")
        let result = await sut.loginUser(body: payload)

        switch(result){
        case .success(let userResponse):
            XCTAssertEqual(userResponse.authData.accessToken, expectedAccessToken)
            XCTAssertTrue(mockTokenProvider.didSaveCalled)
            XCTAssertEqual(mockTokenProvider.savedAccessToken, expectedAccessToken)
            XCTAssertEqual(mockTokenProvider.savedRefreshToken, expectedRefreshToken)


        case .failure:
            XCTFail("Expected success, got failure")
        }
        
    }
    
    func test_loginUser_failure_doesNotSaveToken() async {
        
        mockRepo.resultToReturn = .failure(.serverError(500))
        
        let result = await sut.loginUser(body: AuthPayload(userId: "test@naver.com", password: "1234"))
        
        switch result {
        case .failure:
            XCTAssertFalse(mockTokenProvider.didSaveCalled)
        case .success:
            XCTFail("Expected failure, got success")
        }
        
    }
    
    func test_withdraw_success_returnsInt() async{
        mockRepo.withdrawResultToReturn = .success(204)
        let result = await sut.withdraw()

        switch(result){
        case .success(let statusCode):
            XCTAssertEqual(statusCode, 204)
        case .failure:
            XCTFail("Expected success, got failure")
        }
    }
    
    
    func test_withdraw_failure_returnsError() async{
        mockRepo.withdrawResultToReturn = .failure(.serverError(500))
        
        let result = await sut.withdraw()

        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .serverError(500))
        case .success:
            XCTFail("Expected failure, got success")
        }
        
    }
    
    func test_logout_success_returnsVoid(){
        mockTokenProvider.clearResult = .success(Void())
        
        let result = sut.logout()
        switch result {
          case .success(let success):
            XCTAssertTrue(true)
          case .failure:
            XCTFail("Expected success, got failure")
        }
        
        
    }
    
    
    func test_logout_failure_returnsError() {
        let dummyError = NSError(domain: "Test", code: 999, userInfo: nil)
        mockTokenProvider.clearResult = .failure(dummyError)

        let result = sut.logout()

        switch result {
        case .failure(let error as NSError):
            XCTAssertEqual(error.domain, "Test")
            XCTAssertEqual(error.code, 999)
        case .success:
            XCTFail("Expected failure, got success")
        }
    }
    
    
    
}
