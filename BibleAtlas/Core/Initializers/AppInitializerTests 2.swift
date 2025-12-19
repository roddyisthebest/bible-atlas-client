import XCTest
import RxRelay
@testable import BibleAtlas

// MARK: - Mocks for AppInitializer
final class AppInitMockTokenProvider: TokenProviderProtocol {
    var savedAccessToken: String?
    var savedRefreshToken: String?
    var hasToken: Bool = false

    func save(accessToken: String, refreshToken: String) {
        savedAccessToken = accessToken
        savedRefreshToken = refreshToken
        hasToken = true
    }

    func clear() -> Result<Void, Error> {
        savedAccessToken = nil
        savedRefreshToken = nil
        hasToken = false
        return .success(())
    }
}

final class AppInitMockUserApiService: UserApiServiceProtocol {
    var getProfileResultToReturn: Result<User, NetworkError> = .failure(.clientError("not set"))
    var getProfileCallCount = 0

    func getProfile() async -> Result<User, NetworkError> {
        getProfileCallCount += 1
        return getProfileResultToReturn
    }
}

final class AppInitMockAppStore: AppStoreProtocol {
    let state$: BehaviorRelay<AppState>
    var dispatchedActions: [AppAction] = []

    init(initial: AppState = .init(profile: nil, isLoggedIn: false)) {
        state$ = BehaviorRelay(value: initial)
    }

    func dispatch(_ action: AppAction) {
        dispatchedActions.append(action)
        var state = state$.value
        switch action {
        case .login(let user):
            state.profile = user
            state.isLoggedIn = true
        case .logout:
            state.profile = nil
            state.isLoggedIn = false
        }
        state$.accept(state)
    }
}

// MARK: - Tests
final class AppInitializerTests: XCTestCase {

    func test_restoreSession_noToken_doesNothing() async {
        // given
        let tokenProvider = AppInitMockTokenProvider()
        tokenProvider.hasToken = false
        let appStore = AppInitMockAppStore()
        let api = AppInitMockUserApiService()
        api.getProfileResultToReturn = .success(User(id: 1, name: "u", role: .USER, avatar: "a"))

        let sut = AppInitializer(tokenProvider: tokenProvider, appStore: appStore, userApiService: api)

        // when
        await sut.restoreSessionIfPossible()

        // then: API 미호출, 상태 변화 없음
        XCTAssertEqual(api.getProfileCallCount, 0)
        XCTAssertEqual(appStore.state$.value.isLoggedIn, false)
        XCTAssertNil(appStore.state$.value.profile)
        XCTAssertTrue(appStore.dispatchedActions.isEmpty)
    }

    func test_restoreSession_withToken_success_logsIn() async {
        // given
        let tokenProvider = AppInitMockTokenProvider()
        tokenProvider.hasToken = true
        let appStore = AppInitMockAppStore()
        let api = AppInitMockUserApiService()
        let expectedUser = User(id: 42, name: "tester", role: .USER, avatar: "av")
        api.getProfileResultToReturn = .success(expectedUser)

        let sut = AppInitializer(tokenProvider: tokenProvider, appStore: appStore, userApiService: api)

        // when
        await sut.restoreSessionIfPossible()

        // then
        XCTAssertEqual(api.getProfileCallCount, 1)
        XCTAssertEqual(appStore.state$.value.isLoggedIn, true)
        XCTAssertEqual(appStore.state$.value.profile?.id, expectedUser.id)
        // 액션 기록 확인
        XCTAssertEqual(appStore.dispatchedActions.count, 1)
        if case let .login(user)? = appStore.dispatchedActions.first {
            XCTAssertEqual(user.id, expectedUser.id)
        } else {
            XCTFail("Expected .login action dispatched")
        }
    }

    func test_restoreSession_withToken_failure_doesNotLogin() async {
        // given
        let tokenProvider = AppInitMockTokenProvider()
        tokenProvider.hasToken = true
        let appStore = AppInitMockAppStore()
        let api = AppInitMockUserApiService()
        api.getProfileResultToReturn = .failure(.clientError("boom"))

        let sut = AppInitializer(tokenProvider: tokenProvider, appStore: appStore, userApiService: api)

        // when
        await sut.restoreSessionIfPossible()

        // then
        XCTAssertEqual(api.getProfileCallCount, 1)
        XCTAssertEqual(appStore.state$.value.isLoggedIn, false)
        XCTAssertNil(appStore.state$.value.profile)
        XCTAssertTrue(appStore.dispatchedActions.isEmpty)
    }
}
