//
//  PlaceDetailSheetScrollTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/22/25.
//

import XCTest
@testable import BibleAtlas





final class PlaceDetailViewControllerScrollTests: XCTestCase {

    var vc: PlaceDetailViewController!
    var vm: MockPlaceDetailViewModel!
    var host: UIViewController!
    var window: UIWindow!
    
    
    override func setUp() {
        super.setUp()
        vm = MockPlaceDetailViewModel()
        vc = PlaceDetailViewController(placeDetailViewModel: vm, placeId: "test-id")

        // 실제 pageSheet로 붙여서 sheetPresentationController 생성
        host = UIViewController()
        host.view.backgroundColor = .white
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()

        vc.modalPresentationStyle = .pageSheet
        host.present(vc, animated: false)
        pump()
     }
    
    override func tearDown() {
        host?.dismiss(animated: false)
        window = nil
        host = nil
        vc = nil
        vm = nil
        super.tearDown()
    }
    
    
    func test_scrollEnabled_true_when_large_detent() {
        guard let sheet = vc.sheetPresentationController else {
            XCTFail("sheetPresentationController is nil"); return
        }

        // detents 준비
        sheet.detents = [.large(), .medium()]
        sheet.selectedDetentIdentifier = .medium
        pump()

        // 먼저 medium에서 false인지 확인
        // delegate는 medium 전환 때도 불릴 수 있으니 직접 알려줘도 됨(안정성 확보)
        vc.sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheet)
        XCTAssertFalse(vc._test_isScrollEnabled, "medium에서는 스크롤이 꺼져 있어야 함")

        // large로 전환 (animateChanges를 쓰면 delegate가 자동 호출됨)
        sheet.animateChanges {
            sheet.selectedDetentIdentifier = .large
        }
        pump()

        vc.sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheet)
        XCTAssertTrue(vc._test_isScrollEnabled, ".large에서는 스크롤이 켜져 있어야 함")
    }
    
    
    func test_scrollEnabled_false_when_medium_detent() {
         guard let sheet = vc.sheetPresentationController else {
             XCTFail("sheetPresentationController is nil"); return
         }
         sheet.detents = [.large(), .medium()]

         // large → true
         sheet.animateChanges { sheet.selectedDetentIdentifier = .large }
         pump()
        
         vc.sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheet)

         XCTAssertTrue(vc._test_isScrollEnabled)

         // medium → false
         sheet.animateChanges { sheet.selectedDetentIdentifier = .medium }
         pump()
        
         vc.sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheet)

         XCTAssertFalse(vc._test_isScrollEnabled)
     }

    
}
