//
//  AuthUsecaseTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/3/25.
//

import XCTest
@testable import BibleAtlas



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
          case .success:
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
    
    
    // MARK: - Google Login

       func test_loginGoogleUser_success_savesToken() async {
           // given
           let expectedAccessToken = "google-access"
           let expectedRefreshToken = "google-refresh"

           let authData = AuthData(
               refreshToken: expectedRefreshToken,
               accessToken: expectedAccessToken
           )

           mockRepo.resultToReturn = .success(
               UserResponse(
                   user: User(id: 1, name: "google", role: .USER, avatar: "g"),
                   authData: authData,
                   recovered: false
               )
           )

           // when
           let result = await sut.loginGoogleUser(idToken: "dummy-google-idtoken")

           // then
           switch result {
           case .success(let response):
               XCTAssertEqual(response.authData.accessToken, expectedAccessToken)
               XCTAssertTrue(mockTokenProvider.didSaveCalled)
               XCTAssertEqual(mockTokenProvider.savedAccessToken, expectedAccessToken)
               XCTAssertEqual(mockTokenProvider.savedRefreshToken, expectedRefreshToken)
           case .failure:
               XCTFail("Expected success, got failure")
           }
       }

       func test_loginGoogleUser_failure_doesNotSaveToken() async {
           // given
           mockRepo.resultToReturn = .failure(.serverError(500))

           // when
           let result = await sut.loginGoogleUser(idToken: "dummy-google-idtoken")

           // then
           switch result {
           case .failure:
               XCTAssertFalse(mockTokenProvider.didSaveCalled)
           case .success:
               XCTFail("Expected failure, got success")
           }
       }

       // MARK: - Apple Login

       func test_loginAppleUser_success_savesToken() async {
           // given
           let expectedAccessToken = "apple-access"
           let expectedRefreshToken = "apple-refresh"

           let authData = AuthData(
               refreshToken: expectedRefreshToken,
               accessToken: expectedAccessToken
           )

           mockRepo.resultToReturn = .success(
               UserResponse(
                   user: User(id: 2, name: "apple", role: .USER, avatar: "a"),
                   authData: authData,
                   recovered: false
               )
           )

           // when
           let result = await sut.loginAppleUser(idToken: "dummy-apple-idtoken")

           // then
           switch result {
           case .success(let response):
               XCTAssertEqual(response.authData.accessToken, expectedAccessToken)
               XCTAssertTrue(mockTokenProvider.didSaveCalled)
               XCTAssertEqual(mockTokenProvider.savedAccessToken, expectedAccessToken)
               XCTAssertEqual(mockTokenProvider.savedRefreshToken, expectedRefreshToken)
           case .failure:
               XCTFail("Expected success, got failure")
           }
       }

       func test_loginAppleUser_failure_doesNotSaveToken() async {
           // given
           mockRepo.resultToReturn = .failure(.serverError(500))

           // when
           let result = await sut.loginAppleUser(idToken: "dummy-apple-idtoken")

           // then
           switch result {
           case .failure:
               XCTAssertFalse(mockTokenProvider.didSaveCalled)
           case .success:
               XCTFail("Expected failure, got success")
           }
       }
    
    
    
}
