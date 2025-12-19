//
//  AppInitializerTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
import RxRelay
@testable import BibleAtlas

final class AppInitializerTests: XCTestCase {

    private var tokenProvider: MockTokenProvider!
    private var appStore: MockAppStore!
    private var userApiService: MockUserApiService!
    private var sut: AppInitializer!

    override func setUp() {
        super.setUp()
        // 프로젝트의 mocks에 있는 타입을 사용합니다.
        tokenProvider = MockTokenProvider()
        appStore = MockAppStore(state: AppState(profile: nil, isLoggedIn: false))
        userApiService = MockUserApiService()
        sut = AppInitializer(
            tokenProvider: tokenProvider,
            appStore: appStore,
            userApiService: userApiService
        )
    }

    override func tearDown() {
        sut = nil
        userApiService = nil
        appStore = nil
        tokenProvider = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_restoreSession_doesNothing_when_hasNoToken() async {
        // given
        tokenProvider.hasToken = false

        // when
        await sut.restoreSessionIfPossible()

        // then
        XCTAssertFalse(userApiService.getProfileCalled, "토큰이 없으면 getProfile이 호출되면 안 됨")
        // MockAppStore는 내부적으로 state만 변경하므로, 로그인 상태가 변하지 않았는지만 확인
        XCTAssertEqual(appStore.state$.value.isLoggedIn, false)
        XCTAssertNil(appStore.state$.value.profile)
    }

    func test_restoreSession_fetchesProfile_andDispatchesLogin_when_success() async {
        // given
        tokenProvider.hasToken = true

        let profile = User(id: 1, name: "tester", role: .USER, avatar: "test")
        userApiService.getProfileResult = Result<User, NetworkError>.success(profile)

        // when
        await sut.restoreSessionIfPossible()

        // then
        XCTAssertTrue(userApiService.getProfileCalled, "토큰이 있으면 getProfile이 호출되어야 함")
        XCTAssertEqual(appStore.state$.value.isLoggedIn, true, "성공 시 로그인 상태여야 함")
        XCTAssertEqual(appStore.state$.value.profile?.id, profile.id)
    }

    func test_restoreSession_fetchesProfile_butDoesNotDispatchLogin_when_failure() async {
        // given
        tokenProvider.hasToken = true
        userApiService.getProfileResult = Result<User, NetworkError>.failure(.clientError("stubbed"))

        // when
        await sut.restoreSessionIfPossible()

        // then
        XCTAssertTrue(userApiService.getProfileCalled, "토큰이 있으면 getProfile을 시도해야 함")
        XCTAssertEqual(appStore.state$.value.isLoggedIn, false, "프로필 요청 실패 시 로그인 상태가 되면 안 됨")
        XCTAssertNil(appStore.state$.value.profile)
    }
}

