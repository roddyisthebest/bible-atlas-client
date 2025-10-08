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
        
        UIView.setAnimationsEnabled(false)
        
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
    
    /// 스크롤을 조금 내리면 border가 나타난다
    func test_headerBorder_shows_when_scrolling_down() {
        // 초기값: 맨 위 → 숨김 상태여야 함
        XCTAssertEqual(vc._test_headerBorderAlpha, 0, accuracy: 0.001)
        XCTAssertFalse(vc._test_isTitleSingleLine)

        // 약간 아래로 스크롤(임계값 4 초과를 보장하기 위해 8로)
        vc._test_scroll(toY: 8)
        pump(0.01) // 애니메이션 껐지만, 런루프 한 틱

        XCTAssertEqual(vc._test_headerBorderAlpha, 1, accuracy: 0.001)
        XCTAssertTrue(vc._test_isTitleSingleLine)
    }
    
    func test_headerBorder_hides_when_scrolling_back_to_top() {
          // 먼저 보이게 만든 뒤…
          vc._test_scroll(toY: 8)
          pump(0.01)
          XCTAssertEqual(vc._test_headerBorderAlpha, 1, accuracy: 0.001)

          // 다시 맨 위로
          vc._test_scroll(toY: 0)
          pump(0.01)

          XCTAssertEqual(vc._test_headerBorderAlpha, 0, accuracy: 0.001)
          XCTAssertFalse(vc._test_isTitleSingleLine)
      }


    func test_headerBorder_hysteresis_behavior() {
            // 보이게 만들기
            vc._test_scroll(toY: 6) // > 4
            pump(0.01)
            XCTAssertEqual(vc._test_headerBorderAlpha, 1, accuracy: 0.001)

            // 3은 hideThreshold(2)보다 큼 → 계속 보이는 상태 유지
            vc._test_scroll(toY: 3)
            pump(0.01)
            XCTAssertEqual(vc._test_headerBorderAlpha, 1, accuracy: 0.001)

            // 1은 hideThreshold(2)보다 작음 → 숨김
            vc._test_scroll(toY: 1)
            pump(0.01)
            XCTAssertEqual(vc._test_headerBorderAlpha, 0, accuracy: 0.001)
        }
    
}
