//
//  LoginBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/11/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas


final class MockAuthUsecase:AuthUsecaseProtocol{
    
    var loginResultToReturn:Result<UserResponse,NetworkError>?
    
    var logoutResultToReturn:Result<Void, Error>?
    
    var withdrawResultToReturn:Result<Int, NetworkError>?
    
    var completedExp: XCTestExpectation?

    
    func loginUser(body: BibleAtlas.AuthPayload) async -> Result<BibleAtlas.UserResponse, BibleAtlas.NetworkError> {
        defer { completedExp?.fulfill() }
        return loginResultToReturn ?? .failure(.clientError("test-error"))
    }
    
    func logout() -> Result<Void, Error> {
        return logoutResultToReturn ?? .failure(NSError(domain: "Test", code: 1))
    }
    
    func loginGoogleUser(idToken: String) async -> Result<BibleAtlas.UserResponse, BibleAtlas.NetworkError> {
        return loginResultToReturn ?? .failure(.clientError("test-error"))
    }
    
    func loginAppleUser(idToken: String) async -> Result<BibleAtlas.UserResponse, BibleAtlas.NetworkError> {
        return loginResultToReturn ?? .failure(.clientError("test-error"))
    }
    
    func withdraw() async -> Result<Int, BibleAtlas.NetworkError> {
        return withdrawResultToReturn ?? .failure(.clientError("test-error"))
    }
    
    
}




final class MockNotificationService: RxNotificationServiceProtocol {

    // 테스트용 추적
    var calledNotificationName: Notification.Name?
    var calledNotificationNames: [Notification.Name] = []

    // 이름별 Subject 풀
    private var subjects: [Notification.Name: PublishSubject<Notification>] = [:]

    // 필요 시 해당 이름의 Subject를 가져오거나 생성
    private func subject(for name: Notification.Name) -> PublishSubject<Notification> {
        if let s = subjects[name] { return s }
        let s = PublishSubject<Notification>()
        subjects[name] = s
        return s
    }

    // 실제 트리거: observe 구독자들에게 이벤트 전달
    func post(_ name: Notification.Name, object: Any?) {
        calledNotificationName = name
        calledNotificationNames.append(name)
        subject(for: name).onNext(Notification(name: name, object: object))
    }

    // 구독 제공
    func observe(_ name: Notification.Name) -> Observable<Notification> {
        subject(for: name).asObservable()
    }

    // (옵션) 테스트에서 쓰기 좋은 헬퍼
    func emit(_ name: Notification.Name, object: Any? = nil) {
        post(name, object: object)
    }
}



final class LoginBottomSheetViewModelTests:XCTestCase{
    
    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!
    private var mockNavigator: MockBottomSheetNavigator!
    private var mockAppStore: MockAppStore!
    private var mockRecentSearchService:MockRecentSearchService!
    
    private var mockNotificationService:MockNotificationService!
    
    private let appState = AppState(profile:nil, isLoggedIn: false)
    
    private var mockAuthusecase:MockAuthUsecase!

    
    override func setUp(){
        super.setUp()
            
        disposeBag = DisposeBag();
        scheduler = TestScheduler(initialClock: 0);
        mockNavigator = MockBottomSheetNavigator()
        mockAppStore = MockAppStore(state: appState)
        mockRecentSearchService = MockRecentSearchService();
        mockAuthusecase = MockAuthUsecase();
        mockNotificationService = MockNotificationService();
    }
    
    func test_localLogin_success_togglesLoading_and_performsSideEffects(){
        
        let user = User(id: 1, role: .USER, avatar: "test");
        let authData = AuthData(refreshToken: "test-refresh", accessToken: "access-token")
        
        let userResponse = UserResponse(user: user, authData: authData, recovered: false)
        
        let expectation = XCTestExpectation(description: "wait for async task")
        
        mockAuthusecase.completedExp = expectation
        
        mockAuthusecase.loginResultToReturn = .success(userResponse)
        
        let viewModel = LoginBottomSheetViewModel(navigator: mockNavigator, usecase: mockAuthusecase, appStore: mockAppStore, notificationService: mockNotificationService)
        
        let localButtonTapped$ = PublishRelay<(String?,String?)>()
        
        let _ = viewModel.transform(input: LoginBottomSheetViewModel.Input(googleTokenReceived$: .empty(), appleTokenReceived$: .empty(), localLoginButtonTapped$: localButtonTapped$.asObservable(), closeButtonTapped$: .empty()))
        
        let stateExpectation = XCTestExpectation(description: "appStore state updated")
        
        
        let token = mockAppStore.state$
            .skip(1) // 초기값 false 스킵
            .take(1)
            .subscribe(onNext: { _ in stateExpectation.fulfill() })
        
        localButtonTapped$.accept(("id","pw"))
        
        wait(for: [expectation], timeout: 1.0)
        wait(for: [stateExpectation], timeout: 1.0)

        token.dispose()

        XCTAssertEqual(mockAppStore.state$.value.isLoggedIn, true)
        
        XCTAssertEqual(mockNotificationService.calledNotificationName, .refetchRequired)
        
        XCTAssertEqual(mockNavigator.isDismissed, true)
    }

    func test_localLogin_failure_emitsError_and_noSideEffects() {
        // given
        mockAuthusecase.loginResultToReturn = .failure(.clientError("test-error"))

        let vm = LoginBottomSheetViewModel(
            navigator: nil,
            usecase: mockAuthusecase,
            appStore: nil,
            notificationService: nil
        )

        let localButtonTapped$ = PublishRelay<(String?, String?)>()
        let output = vm.transform(input: .init(
            googleTokenReceived$: .empty(),
            appleTokenReceived$: .empty(),
            localLoginButtonTapped$: localButtonTapped$.asObservable(), closeButtonTapped$: .empty()
        ))

        let exp = expectation(description: "error emitted")
        var captured: NetworkError?
        let disposable = output.error$
            .take(1)
            .subscribe(onNext: { e in
                captured = e
                exp.fulfill()
            })


        localButtonTapped$.accept(("id", "pw"))
        
        wait(for: [exp], timeout: 2.0)
        disposable.dispose()

        XCTAssertEqual(captured, .clientError("test-error"))
    }


    func test_googleLogin_nilToken_doesNothing(){
        
        let viewModel = LoginBottomSheetViewModel(navigator: nil, usecase: nil, appStore: nil, notificationService: nil)
        
        let googleTokenReceived$ = PublishRelay<String?>();
        
        let output = viewModel.transform(input: LoginBottomSheetViewModel.Input(googleTokenReceived$: googleTokenReceived$.asObservable(), appleTokenReceived$: googleTokenReceived$.asObservable(), localLoginButtonTapped$: .empty(), closeButtonTapped$: .empty()))
        
        
        
        googleTokenReceived$.accept(nil);
        
        let observer = scheduler.createObserver(Bool.self);
        
        output.googleLoading$
            .observe(on: scheduler)
            .bind(to:observer)
            .disposed(by: disposeBag)
            
        scheduler.start();
        
        
        let googleLoading = observer.events.compactMap{ $0.value.event.element}.first!
    
        XCTAssertFalse(googleLoading)
        
        
    }

    
    
    
}
