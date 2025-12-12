//
//  AppCoordinatorTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
@testable import BibleAtlas

// MARK: - Extra Mocks for AppCoordinator


// AppCoordinator 테스트용 VMFactory Stub
final class AppCoordinatorVMFactoryStub: MockVMFactory {
    override func makeMainVM() -> MainViewModelProtocol {
        // 프로젝트에 이미 있는 MainViewModel용 mock 사용
        return MockMainViewModel()
    }
}

// AppCoordinator 테스트용 BottomSheetNavigator Stub
final class AppCoordinatorBottomSheetNavigatorStub: MockBottomSheetNavigator {

    private(set) var presenter: Presentable?
    private(set) var presentHistory: [BottomSheetType] = []

    override func setPresenter(_ presenter: Presentable?) {
        self.presenter = presenter
        super.setPresenter(presenter)
    }

    override func present(_ type: BottomSheetType) {
        presentHistory.append(type)
        super.present(type)
    }
}

// MARK: - Tests

final class AppCoordinatorTests: XCTestCase {

    private var appStore: MockAppStore!
    private var vmFactory: AppCoordinatorVMFactoryStub!
    private var vcFactory: MockVCFactory!
    private var notificationService: MockNotificationService!
    private var bottomSheetNavigator: AppCoordinatorBottomSheetNavigatorStub!
    private var windowService: MockWindowService!

    private var sut: AppCoordinator!

    override func setUp() {
        super.setUp()

        // 초기 상태: 로그인 상태든 아니든 큰 상관은 없음
        let initialState = AppState(profile: nil, isLoggedIn: false)
        appStore = MockAppStore(state: initialState)

        vmFactory = AppCoordinatorVMFactoryStub()
        vcFactory = MockVCFactory()
        notificationService = MockNotificationService()
        bottomSheetNavigator = AppCoordinatorBottomSheetNavigatorStub()
        windowService = MockWindowService()

        sut = AppCoordinator(
            appStore: appStore,
            vmFactory: vmFactory,
            vcFactory: vcFactory,
            notificationService: notificationService,
            bottomSheetCoordinator: bottomSheetNavigator,
            windowService: windowService
        )
    }

    override func tearDown() {
        sut = nil
        windowService = nil
        bottomSheetNavigator = nil
        notificationService = nil
        vcFactory = nil
        vmFactory = nil
        appStore = nil
        super.tearDown()
    }

    // MARK: - start()

    func test_start_setsRootVC_and_presentsHomeSheet() {
        // given
        let presentExpectation = expectation(description: "present(.home) called")

        // presentHistory를 폴링하는 대신, main async가 돌 시간을 조금 준다
        // (아래 wait에서 검증)
        // when
        sut.start()

        // then (동기 부분 검증)
        XCTAssertFalse(windowService.attachedViewControllers.isEmpty, "start() should attach a root view controller")
        let attachedRoot = windowService.attachedViewControllers.first
        XCTAssertNotNil(attachedRoot, "Root view controller should not be nil")

        // presenter로 동일한 VC가 들어갔는지 (타입까지 강하게 보진 않고, 동일 인스턴스만 체크)
        if let presenter = bottomSheetNavigator.presenter as? UIViewController {
            XCTAssertTrue(attachedRoot === presenter, "BottomSheetNavigator presenter should be the attached root VC")
        } else {
            XCTFail("BottomSheetNavigator presenter should be a UIViewController")
        }

        // 비동기로 present(.home)이 호출됨
        DispatchQueue.main.async {
            if self.bottomSheetNavigator.presentHistory.contains(.home) {
                presentExpectation.fulfill()
            }
        }

        wait(for: [presentExpectation], timeout: 1.0)
    }

    // MARK: - logout()

    func test_logout_dispatchesLogout_and_restartsFlow() {
        // given
        // 일단 현재 상태를 "로그인된 상태"라 가정
        let user = User(id: 1, role: .EXPERT, avatar: "")
        appStore.dispatch(.login(user))

        XCTAssertTrue(appStore.state$.value.isLoggedIn)

        // when
        sut.logout()

        // then
        // 1) 상태가 로그아웃 되었는지
        XCTAssertFalse(appStore.state$.value.isLoggedIn, "logout() should update appStore state to logged out")

        // 2) logout 내부에서 start()가 다시 불려서 attach가 최소 1번은 되었는지
        XCTAssertFalse(windowService.attachedViewControllers.isEmpty, "logout() should re-attach a root view controller by calling start() again")
    }

    
    // MARK: - openSupportCenter()

    func test_openSupportCenter_doesNotCrash() {
        // 단순 커버리지용: URL 생성 및 UIApplication.open 호출까지
        // 크래시 없이 지나가는지만 확인
        sut.openSupportCenter()
        // 별도 assert 없이, 호출만으로 라인 커버리지 확보
    }
    
}
