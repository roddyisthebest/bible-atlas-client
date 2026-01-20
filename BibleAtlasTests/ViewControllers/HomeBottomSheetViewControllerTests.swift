//
//  HomeBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/22/25.
//

import XCTest
import RxSwift
@testable import BibleAtlas




final class HomeBottomSheetViewControllerTests: XCTestCase {

    private var vm: MockHomeBottomSheetViewModel!
    private var sut: HomeBottomSheetViewController!
    private var window: UIWindow!
    private var host: UIViewController!

    override func setUp() {
        super.setUp()

        vm = MockHomeBottomSheetViewModel()

        let homeVC = HomeContentViewController(homeContentViewModel: MockHomeContentViewModel())
        let readyVC = SearchReadyViewController(searchReadyViewModel: MockSearchReadyViewModel())
        let resultVC = SearchResultViewController(searchResultViewModel: MockSearchResultViewModel())

        sut = HomeBottomSheetViewController(
            homeBottomSheetViewModel: vm,
            homeContentViewController: homeVC,
            searchReadyViewController: readyVC,
            searchResultViewController: resultVC
        )

        // ✅ sheetPresentationController 살리려면 실제로 pageSheet로 present 해야 함
        host = UIViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()

        sut.modalPresentationStyle = .pageSheet
        host.present(sut, animated: false)

        pumpMain(0.1) // viewDidLoad + attachChild + bind 완료
    }

    override func tearDown() {
        host.dismiss(animated: false)
        pumpMain(0.05)

        sut = nil
        vm = nil
        host = nil
        window = nil

        super.tearDown()
    }

    // MARK: - Helpers

    private func pumpMain(_ seconds: TimeInterval = 0.05) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    private func visibleChild() -> UIViewController? {
        // attach-once 이후 children가 3개라서 "보이는 VC"를 찾아야 함
        return sut.children.first(where: { $0.view.isHidden == false })
    }

    private func sheet() -> UISheetPresentationController {
        guard let s = sut.sheetPresentationController else {
            XCTFail("Expected sheetPresentationController to exist. Ensure sut is presented as .pageSheet.")
            fatalError()
        }
        return s
    }

    // MARK: - Tests

    func test_initial_showsHomeContent_and_buttons() {
        pumpMain(0.05)

        let v = visibleChild()
        XCTAssertTrue(v is HomeContentViewController)

        XCTAssertFalse(sut._test_isUserAvatarHidden)
        XCTAssertTrue(sut._test_isCancelHidden)
    }

    func test_searchReadyMode_showsSearchReady_and_locksLargeDetent_and_buttons() {
        vm._screenMode$.accept(.searchReady)

        // apply(mode:)는 동기지만 lockToLargeDetentCoalesced()가 main.async라서 펌프 필요
        pumpMain(0.15)

        let v = visibleChild()
        XCTAssertTrue(v is SearchReadyViewController)

        XCTAssertTrue(sut._test_isUserAvatarHidden)
        XCTAssertFalse(sut._test_isCancelHidden)

        // ✅ large lock 확인
        let s = sheet()
        XCTAssertEqual(s.selectedDetentIdentifier, .large)
        XCTAssertEqual(s.detents.count, 1)
    }

    func test_searchingMode_showsSearchResult_and_locksLargeDetent_and_buttons() {
        vm._screenMode$.accept(.searching)
        pumpMain(0.15)

        let v = visibleChild()
        XCTAssertTrue(v is SearchResultViewController)

        XCTAssertTrue(sut._test_isUserAvatarHidden)
        XCTAssertFalse(sut._test_isCancelHidden)

        let s = sheet()
        XCTAssertEqual(s.selectedDetentIdentifier, .large)
        XCTAssertEqual(s.detents.count, 1)
    }

    func test_homeMode_restoresDetents_and_dismissKeyboard_and_buttons() {
        // 먼저 searching으로 만들어 detent lock 상태로 만들고
        vm._screenMode$.accept(.searching)
        pumpMain(0.15)

        // 다시 home으로
        vm._screenMode$.accept(.home)
        pumpMain(0.15)

        let v = visibleChild()
        XCTAssertTrue(v is HomeContentViewController)

        XCTAssertFalse(sut._test_isUserAvatarHidden)
        XCTAssertTrue(sut._test_isCancelHidden)

        // restoreDetentsAndDismissKeyboard()에서 detents를 3개로 세팅함
        let s = sheet()
        XCTAssertEqual(s.detents.count, 3)
        XCTAssertEqual(s.selectedDetentIdentifier, .medium)
    }

    func test_forceMedium_and_restoreDetents_emits_changeSheetDetents() {
        // 테스트를 안정시키기 위해, 현재 detents를 "알려진 값"으로 만들어둠
        let s = sheet()
        s.animateChanges {
            s.detents = [.large(), .medium()]
            s.selectedDetentIdentifier = .medium
        }
        pumpMain(0.1)

        // forceMedium
        vm._forceMedium$.accept(())
        pumpMain(0.15)

        XCTAssertEqual(s.detents.count, 1)
        XCTAssertEqual(s.selectedDetentIdentifier, .medium)

        // restore
        vm._restoreDetents$.accept(())
        pumpMain(0.15)

        XCTAssertEqual(s.detents.count, 2)
        XCTAssertEqual(s.selectedDetentIdentifier, .medium)
    }

    func test_bind_editingDidBegin_is_wired() {
        // VC 바인딩이 제대로 되었는지: _test_beginEditing()이 lastInput.editingDidBegin$로 들어오는지 검증
        guard let input = vm.lastInput else {
            return XCTFail("Expected transform(input:) to be called and lastInput captured.")
        }

        let exp = expectation(description: "editingDidBegin emitted")

        let bag = DisposeBag()
        input.editingDidBegin$
            .take(1)
            .subscribe(onNext: { _ in exp.fulfill() })
            .disposed(by: bag)

        sut._test_beginEditing()
        pumpMain(0.2)

        wait(for: [exp], timeout: 1.0)
    }

    func test_bind_keywordChanged_is_wired() {
        guard let input = vm.lastInput else {
            return XCTFail("Expected transform(input:) to be called and lastInput captured.")
        }

        let exp = expectation(description: "keywordChanged emitted")
        let bag = DisposeBag()

        var last: String?
        input.keywordChanged$
            .skip(1) // initial ""
            .take(1)
            .subscribe(onNext: { value in
                last = value
                exp.fulfill()
            })
            .disposed(by: bag)

        sut._test_typeSearchText("Jerusalem")
        pumpMain(0.2)

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(last, "Jerusalem")
    }
}
