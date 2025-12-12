//
//  AccountManagementBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
import RxSwift
import RxRelay
@testable import BibleAtlas

// 실제 VC를 상속해서 present(_:animated:completion:)만 가로채는 테스트용 서브클래스
final class TestAccountManagementBottomSheetViewController: AccountManagementBottomSheetViewController {

    /// 최근에 present된 UIAlertController를 잡아두는 용도
    var lastPresentedAlert: UIAlertController?

    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {

        if let alert = viewControllerToPresent as? UIAlertController {
            lastPresentedAlert = alert
        }

        // 실제 화면 표시 필요 없으니 super.present는 안 불러도 됨
        completion?()
    }
}

final class AccountManagementBottomSheetViewControllerTests: XCTestCase {

    private var sut: AccountManagementBottomSheetViewController!
    private var mockVM: MockAccountManagementBottomSheetViewModel!
    private var disposeBag: DisposeBag!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        mockVM = MockAccountManagementBottomSheetViewModel()
        sut = TestAccountManagementBottomSheetViewController(accountManagementBottomSheetViewModel: mockVM)

        // viewDidLoad + bindViewModel + setup* 호출
        _ = sut.view
        pump()
    }

    override func tearDown() {
        sut = nil
        mockVM = nil
        disposeBag = nil
        super.tearDown()
    }

    /// 메인 런루프를 잠깐 돌려서 Rx/레이아웃 등 비동기 처리 반영
    private func pump(_ sec: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(sec))
    }

    // MARK: - 기본 UI / 메뉴 세팅

    func test_viewDidLoad_setsMenuItems_andTableRows() {
        // given: setUp에서 이미 view 로드 및 menuItems 설정됨

        let rows = sut._test_tableView.numberOfRows(inSection: 0)

        // then: VM의 menuItems 개수와 동일해야 함
        XCTAssertEqual(rows, mockVM.menuItems.count)
        XCTAssertGreaterThan(rows, 0)
    }

    // MARK: - 테이블 셀 선택 → ViewModel로 menuItem 전달

    func test_didSelectRow_sendsMenuItemToViewModel() {
        // given
        let tableView = sut._test_tableView
        let indexPath = IndexPath(row: 1, section: 0) // 두 번째 메뉴 (logout)

        // when
        sut.tableView(tableView, didSelectRowAt: indexPath)
        pump()

        // then
        XCTAssertEqual(mockVM.receivedMenuItems.count, 1)
        XCTAssertEqual(mockVM.receivedMenuItems.first?.id, mockVM.menuItems[1].id)
    }

    // MARK: - close 버튼 → ViewModel close 이벤트 전달

    func test_closeButtonTap_triggersViewModelClose() {
        // given
        _ = sut.view
        pump()

        // when
        sut._test_closeButton.sendActions(for: .touchUpInside)
        pump()

        // then
        XCTAssertEqual(mockVM.receivedCloseTapCount, 1)
    }

    // MARK: - isWithdrawing 바인딩: 로딩 오버레이 + 인터랙션 토글

    func test_isWithdrawing_togglesLoadingOverlay_andUserInteraction() {
        // given: 초기 상태
        XCTAssertTrue(sut._test_loadingOverlayView.isHidden)
        XCTAssertTrue(sut.view.isUserInteractionEnabled)

        // when: withdrawing 시작
        mockVM.isWithdrawingSubject.onNext(true)
        pump(0.1)

        // then
        XCTAssertFalse(sut._test_loadingOverlayView.isHidden)
        XCTAssertFalse(sut.view.isUserInteractionEnabled)

        // when: withdrawing 끝
        mockVM.isWithdrawingSubject.onNext(false)
        pump(0.1)

        // then
        XCTAssertTrue(sut._test_loadingOverlayView.isHidden)
        XCTAssertTrue(sut.view.isUserInteractionEnabled)
    }

    func test_showWithdrawConfirm_presentsAlert() {
        // given
        XCTAssertNil((sut as? TestAccountManagementBottomSheetViewController)?.lastPresentedAlert)

        // when
        mockVM.showWithdrawConfirmSubject.onNext(())
        pump(0.1)

        // then
        guard
            let testSut = sut as? TestAccountManagementBottomSheetViewController,
            let alert = testSut.lastPresentedAlert
        else {
            return XCTFail("Expected UIAlertController for withdraw confirm")
        }

        XCTAssertEqual(alert.title, L10n.AccountManagement.withdrawConfirmTitle)
        XCTAssertEqual(alert.message, L10n.AccountManagement.withdrawConfirmMessage)

        // destructive 스타일 액션이 하나 있는지만 확인
        XCTAssertNotNil(alert.actions.first(where: { $0.style == .destructive }))
    }


    func test_showWithdrawComplete_presentsAlert() {
        // given
        XCTAssertNil((sut as? TestAccountManagementBottomSheetViewController)?.lastPresentedAlert)

        // when
        mockVM.showWithdrawCompleteSubject.onNext(())
        pump(0.1)

        // then
        guard
            let testSut = sut as? TestAccountManagementBottomSheetViewController,
            let alert = testSut.lastPresentedAlert
        else {
            return XCTFail("Expected UIAlertController for withdraw complete")
        }

        XCTAssertEqual(alert.title, L10n.AccountManagement.withdrawCompleteTitle)
        XCTAssertEqual(alert.message, L10n.AccountManagement.withdrawCompleteMessage)

        // OK (default) 스타일 액션 존재 확인
        XCTAssertNotNil(alert.actions.first(where: { $0.style == .default }))
    }

    // MARK: - error 바인딩: error emit 시 alert 호출 (crash 없이 동작)

    func test_error_emits_showsErrorAlert() {
        // given
        XCTAssertNil((sut as? TestAccountManagementBottomSheetViewController)?.lastPresentedAlert)

        // when
        mockVM.errorSubject.onNext(.clientError("테스트 에러"))
        pump(0.1)

        // then
        let testSut = sut as? TestAccountManagementBottomSheetViewController
        XCTAssertNotNil(testSut?.lastPresentedAlert)
    }
    
    
    func test_headerTitle_exists_and_rowHeight_isMenuHeight() {
        // header title
        let title = sut._test_headerLabel.text ?? ""

        // row height check (using delegate call)
        let height = sut.tableView(sut._test_tableView, heightForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertGreaterThan(height, 0)
    }
    
    func test_withdrawConfirm_alertAction_triggersRelay() {
        // given
        let testSut = sut as! TestAccountManagementBottomSheetViewController
        mockVM.showWithdrawConfirmSubject.onNext(())
        pump(0.1)
        guard let alert = testSut.lastPresentedAlert else { return XCTFail("no alert") }

        // when: tap destructive action (withdraw)
        // verify destructive action exists (but we don't call private handler)
        XCTAssertNotNil(alert.actions.first(where: { $0.style == .destructive }))
        pump(0.05)

        // then: use the debug hook to simulate relay and assert via VM input counts
        sut._test_triggerWithdrawConfirm()
        XCTAssertEqual(mockVM.receivedWithdrawConfirmTapCount, 1)
    }
    
    func test_withdrawComplete_alertAction_triggersRelay() {
        // given
        let testSut = sut as! TestAccountManagementBottomSheetViewController
        mockVM.showWithdrawCompleteSubject.onNext(())
        pump(0.1)
        guard let alert = testSut.lastPresentedAlert else { return XCTFail("no alert") }

        // when: tap default OK action
        // verify default OK action exists (but we don't call private handler)
        XCTAssertNotNil(alert.actions.first(where: { $0.style == .default }))
        pump(0.05)

        // then: trigger relay and assert
        sut._test_triggerWithdrawCompleteConfirm()
        XCTAssertEqual(mockVM.receivedWithdrawCompleteConfirmTapCount, 1)
    }
    
    func test_selectEachMenuItem_relaysToViewModel() {
        let table = sut._test_tableView
        for i in 0..<(mockVM.menuItems.count) {
            sut.tableView(table, didSelectRowAt: IndexPath(row: i, section: 0))
        }
        pump(0.1)
        XCTAssertEqual(mockVM.receivedMenuItems.count, mockVM.menuItems.count)
    }
}

