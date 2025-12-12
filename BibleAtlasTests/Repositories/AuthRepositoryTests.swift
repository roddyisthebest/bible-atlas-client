//
//  AuthRepositoryTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/3/25.
//

import XCTest
@testable import BibleAtlas


final class AuthRepositoryTests: XCTestCase {
    private var sut: AuthRepository!
    private var mockApiService: MockAuthApiService!
    
    override func setUp() {
        super.setUp()
        mockApiService = MockAuthApiService()
        sut = AuthRepository(authApiService: mockApiService)
    }

    func test_loginUser_delegatesToApiService() async {
        _ = await sut.loginUser(body: AuthPayload(userId: "a", password: "b"))
        XCTAssertEqual(mockApiService.calledMethods, ["loginUser"])
    }

    func test_loginGoogleUser_delegatesToApiService() async {
        _ = await sut.loginGoogleUser(idToken: "token")
        XCTAssertEqual(mockApiService.calledMethods, ["loginGoogleUser"])
    }

    func test_loginAppleUser_delegatesToApiService() async {
        _ = await sut.loginAppleUser(idToken: "token")
        XCTAssertEqual(mockApiService.calledMethods, ["loginAppleUser"])
    }

    func test_withdraw_delegatesToApiService() async {
        _ = await sut.withdraw()
        XCTAssertEqual(mockApiService.calledMethods, ["withdraw"])
    }
}

