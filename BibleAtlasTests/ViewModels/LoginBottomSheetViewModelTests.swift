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
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))

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
    
    func test_localLogin_invalidCredentials_emitInvalidFormatError_and_doNotCallUsecase() {
        // given
        let vm = LoginBottomSheetViewModel(
            navigator: nil,
            usecase: mockAuthusecase,   // 여기는 있어도 됨 (안 불려야 하니까)
            appStore: mockAppStore,
            notificationService: mockNotificationService
        )
        
        // loginResultToReturn이 있어도, validation에서 걸리기 때문에 사용되면 안 됨
        mockAuthusecase.loginResultToReturn = .success(
            UserResponse(
                user: User(id: 1, role: .USER, avatar: "test"),
                authData: AuthData(refreshToken: "r", accessToken: "a"),
                recovered: false
            )
        )

        let localButtonTapped$ = PublishRelay<(String?, String?)>()
        let output = vm.transform(input: .init(
            googleTokenReceived$: .empty(),
            appleTokenReceived$: .empty(),
            localLoginButtonTapped$: localButtonTapped$.asObservable(),
            closeButtonTapped$: .empty()
        ))

        let exp = expectation(description: "validation error emitted")
        var captured: NetworkError?

        let disposable = output.error$
            .take(1)
            .subscribe(onNext: { e in
                captured = e
                exp.fulfill()
            })

        // when: 공백 + 공백
        localButtonTapped$.accept(("   ", "   "))

        wait(for: [exp], timeout: 1.0)
        disposable.dispose()

  
        XCTAssertEqual(captured, .clientError(L10n.Login.invalidFormat))
        
    }

    func test_localLogin_whenUsecaseIsNil_emitsFatalError_andDoesNotCrash() {
        // given
        let vm = LoginBottomSheetViewModel(
            navigator: nil,
            usecase: nil,                    // 🔥 핵심
            appStore: mockAppStore,
            notificationService: mockNotificationService
        )

        let localButtonTapped$ = PublishRelay<(String?, String?)>()
        let output = vm.transform(input: .init(
            googleTokenReceived$: .empty(),
            appleTokenReceived$: .empty(),
            localLoginButtonTapped$: localButtonTapped$.asObservable(),
            closeButtonTapped$: .empty()
        ))

        let exp = expectation(description: "fatal error emitted")
        var captured: NetworkError?

        let disposable = output.error$
            .take(1)
            .subscribe(onNext: { e in
                captured = e
                exp.fulfill()
            })

        // when
        localButtonTapped$.accept(("id", "pw"))

        wait(for: [exp], timeout: 1.0)
        disposable.dispose()

        // then
        XCTAssertEqual(captured, .clientError(L10n.FatalError.reExec))
    }

    
    func test_googleLogin_success_updatesAppStore_postsNotification_andDismisses() {
        // given
        let user = User(id: 1, role: .USER, avatar: "avatar")
        let authData = AuthData(refreshToken: "r", accessToken: "a")
        let userResponse = UserResponse(user: user, authData: authData, recovered: false)
        
        mockAuthusecase.loginResultToReturn = .success(userResponse)
        let loginExp = expectation(description: "google login completed")
        mockAuthusecase.googleCompletedExp = loginExp
        
        let vm = LoginBottomSheetViewModel(
            navigator: mockNavigator,
            usecase: mockAuthusecase,
            appStore: mockAppStore,
            notificationService: mockNotificationService
        )
        
        let googleToken$ = PublishRelay<String?>()
        
        // output을 받아 googleLoading$로 dismiss 완료 시점을 기다린다
        let output = vm.transform(input: .init(
            googleTokenReceived$: googleToken$.asObservable(),
            appleTokenReceived$: .empty(),
            localLoginButtonTapped$: .empty(),
            closeButtonTapped$: .empty()
        ))
        
        let stateExp = expectation(description: "state updated after google login")
        let stateDisposable = mockAppStore.state$
            .skip(1)
            .take(1)
            .subscribe(onNext: { _ in stateExp.fulfill() })
        
        // dismiss까지 완료되었음을 보장하기 위해 googleLoading$ == false 대기
        let loadingDoneExp = expectation(description: "google loading false (dismiss done)")
        let loadingDisposable = output.googleLoading$
            .skip(1)
            .filter { $0 == false }
            .take(1)
            .subscribe(onNext: { _ in loadingDoneExp.fulfill() })
        
        // when
        googleToken$.accept("google-id-token")
        
        // then
        wait(for: [loginExp, stateExp, loadingDoneExp], timeout: 2.0)
        stateDisposable.dispose()
        loadingDisposable.dispose()
        
        // 사이드 이펙트들 확인
        XCTAssertTrue(mockAppStore.state$.value.isLoggedIn)
        XCTAssertEqual(mockNotificationService.calledNotificationName, .refetchRequired)
        XCTAssertTrue(mockNavigator.isDismissed)
    }
    
    
    func test_googleLogin_failure_emitsError_andNoSideEffects() {
        // given
        mockAuthusecase.loginResultToReturn = .failure(.clientError("google-error"))
        
        let vm = LoginBottomSheetViewModel(
            navigator: mockNavigator,
            usecase: mockAuthusecase,
            appStore: mockAppStore,
            notificationService: mockNotificationService
        )
        
        let googleToken$ = PublishRelay<String?>()
        let output = vm.transform(input: .init(
            googleTokenReceived$: googleToken$.asObservable(),
            appleTokenReceived$: .empty(),
            localLoginButtonTapped$: .empty(),
            closeButtonTapped$: .empty()
        ))
        
        let errorExp = expectation(description: "google error emitted")
        var captured: NetworkError?
        
        let disposable = output.error$
            .take(1)
            .subscribe(onNext: { e in
                captured = e
                errorExp.fulfill()
            })
        
        // when
        googleToken$.accept("google-id-token")
        
        // then
        wait(for: [errorExp], timeout: 1.0)
        disposable.dispose()
        
        XCTAssertEqual(captured, .clientError("google-error"))
        XCTAssertFalse(mockAppStore.state$.value.isLoggedIn)
        XCTAssertNil(mockNotificationService.calledNotificationName)
        XCTAssertFalse(mockNavigator.isDismissed)
    }
    
    
    
    func test_appleLogin_success_updatesAppStore_postsNotification_andDismisses() {
        // given
        let user = User(id: 2, role: .USER, avatar: "apple-avatar")
        let authData = AuthData(refreshToken: "r2", accessToken: "a2")
        let userResponse = UserResponse(user: user, authData: authData, recovered: false)
        
        mockAuthusecase.loginResultToReturn = .success(userResponse)
        let loginExp = expectation(description: "apple login completed")
        mockAuthusecase.appleCompletedExp = loginExp
        
        let vm = LoginBottomSheetViewModel(
            navigator: mockNavigator,
            usecase: mockAuthusecase,
            appStore: mockAppStore,
            notificationService: mockNotificationService
        )
        
        let appleToken$ = PublishRelay<String?>()
        
        let output = vm.transform(input: .init(
            googleTokenReceived$: .empty(),
            appleTokenReceived$: appleToken$.asObservable(),
            localLoginButtonTapped$: .empty(),
            closeButtonTapped$: .empty()
        ))
        
        let stateExp = expectation(description: "state updated after apple login")
        let stateDisposable = mockAppStore.state$
            .skip(1)
            .take(1)
            .subscribe(onNext: { _ in stateExp.fulfill() })
        
        // dismiss까지 완료되었음을 보장하기 위해 appleLoading$ == false 대기
        let appleLoadingDoneExp = expectation(description: "apple loading false (dismiss done)")
        let appleLoadingDisposable = output.appleLoading$
            .skip(1)
            .filter { $0 == false }
            .take(1)
            .subscribe(onNext: { _ in appleLoadingDoneExp.fulfill() })
        
        // when
        appleToken$.accept("apple-id-token")
        
        // then
        wait(for: [loginExp, stateExp, appleLoadingDoneExp], timeout: 2.0)
        stateDisposable.dispose()
        appleLoadingDisposable.dispose()
        
        XCTAssertTrue(mockAppStore.state$.value.isLoggedIn)
        XCTAssertEqual(mockNotificationService.calledNotificationName, .refetchRequired)
        XCTAssertTrue(mockNavigator.isDismissed)
    }

    func test_appleLogin_failure_emitsError_andNoSideEffects() {
        // given
        mockAuthusecase.loginResultToReturn = .failure(.clientError("apple-error"))
        
        let vm = LoginBottomSheetViewModel(
            navigator: mockNavigator,
            usecase: mockAuthusecase,
            appStore: mockAppStore,
            notificationService: mockNotificationService
        )
        
        let appleToken$ = PublishRelay<String?>()
        let output = vm.transform(input: .init(
            googleTokenReceived$: .empty(),
            appleTokenReceived$: appleToken$.asObservable(),
            localLoginButtonTapped$: .empty(),
            closeButtonTapped$: .empty()
        ))
        
        let errorExp = expectation(description: "apple error emitted")
        var captured: NetworkError?
        
        let disposable = output.error$
            .take(1)
            .subscribe(onNext: { e in
                captured = e
                errorExp.fulfill()
            })
        
        // when
        appleToken$.accept("apple-id-token")
        
        // then
        wait(for: [errorExp], timeout: 1.0)
        disposable.dispose()
        
        XCTAssertEqual(captured, .clientError("apple-error"))
        XCTAssertFalse(mockAppStore.state$.value.isLoggedIn)
        XCTAssertNil(mockNotificationService.calledNotificationName)
        XCTAssertFalse(mockNavigator.isDismissed)
    }

    
    func test_closeButtonTapped_dismissesNavigator() {
        // given
        let vm = LoginBottomSheetViewModel(
            navigator: mockNavigator,
            usecase: nil,
            appStore: nil,
            notificationService: nil
        )
        
        let close$ = PublishRelay<Void>()
        
        _ = vm.transform(input: .init(
            googleTokenReceived$: .empty(),
            appleTokenReceived$: .empty(),
            localLoginButtonTapped$: .empty(),
            closeButtonTapped$: close$.asObservable()
        ))
        
        // when
        close$.accept(())
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        
        // then
        XCTAssertTrue(mockNavigator.isDismissed)
    }

    
    
}

