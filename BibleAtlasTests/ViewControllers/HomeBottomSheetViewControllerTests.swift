//
//  HomeBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/22/25.
//

import XCTest
@testable import BibleAtlas

//private func pump(_ sec: TimeInterval = 0.05) {
//    RunLoop.current.run(until: Date().addingTimeInterval(sec))
//}

final class HomeBottomSheetViewControllerTests: XCTestCase {

    var vm: MockHomeBottomSheetViewModel!
    var vc: HomeBottomSheetViewController!

    override func setUp() {
            super.setUp()
            vm = MockHomeBottomSheetViewModel()

            // 실제 VC 그대로 사용 (final이라 서브클래싱 불가)
            let homeVC = HomeContentViewController(homeContentViewModel: MockHomeContentViewModel())
            let readyVC = SearchReadyViewController(searchReadyViewModel: MockSearchReadyViewModel())
            let resultVC = SearchResultViewController(searchResultViewModel: MockSearchResultViewModel())

        vc = HomeBottomSheetViewController(
                homeBottomSheetViewModel: vm,
                homeContentViewController: homeVC,
                searchReadyViewController: readyVC,
                searchResultViewController: resultVC
            )

            _ = vc.view  // viewDidLoad 트리거 (bindViewModel 호출됨)
            pump()
        }
    
    override func tearDown() {
        vc = nil
        vm = nil
        super.tearDown()
    }
    
    func test_homeMode_showsHomeContent_and_buttonsVisibility() {
        vm._screenMode$.accept(.home)
        pump(0.01)

        XCTAssertTrue(vc.children.first is HomeContentViewController)
        XCTAssertFalse(vc._test_isUserAvatarHidden)
        XCTAssertTrue(vc._test_isCancelHidden)
    }
    
    func test_searchReadyMode_swapsToSearchReady_and_buttonsVisibility() {
        vm._screenMode$.accept(.searchReady)
        pump()

        XCTAssertTrue(vc.children.first is SearchReadyViewController)
        XCTAssertTrue(vc._test_isUserAvatarHidden)
        XCTAssertFalse(vc._test_isCancelHidden)
    }
    
    func test_searchingMode_swapsToSearchResult_and_buttonsVisibility() {
        vm._screenMode$.accept(.searching)
        pump(0.01)

        XCTAssertTrue(vc.children.first is SearchResultViewController)
        XCTAssertTrue(vc._test_isUserAvatarHidden)
        XCTAssertFalse(vc._test_isCancelHidden)
    }
    
    func test_detentChanges_whenForceMediumAndRestore_emits(){
        
        vm._forceMedium$.accept(())
        pump(0.01)
        
        XCTAssertEqual(vc._test_selectedDetentIdentifier, .medium)
        XCTAssertEqual(vc._test_detentsCount, 1)
        
        
        vm._restoreDetents$.accept(())
        pump(0.01)
        XCTAssertEqual(vc._test_detentsCount, 3)
        
    }
    
    func test_detentChanges_whenIsSearchingIsTrue(){
        vc._test_beginEditing();
        pump(0.01)

        XCTAssertEqual(vc._test_selectedDetentIdentifier, .large)
        XCTAssertEqual(vc._test_detentsCount, 1)
        
        vm._forceMedium$.accept(())
        pump(0.01)
        
        XCTAssertEqual(vc._test_selectedDetentIdentifier, .medium)
        XCTAssertEqual(vc._test_detentsCount, 1)
        
        
        vm._restoreDetents$.accept(())
        pump(0.01)
        
        XCTAssertEqual(vc._test_selectedDetentIdentifier, .large)
        XCTAssertEqual(vc._test_detentsCount, 1)
    }
    
    

    
    
}
