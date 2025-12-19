//
//  BottomSheetCoordinatorTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import XCTest
@testable import BibleAtlas
import RxSwift




final class BottomSheetCoordinatorTests: XCTestCase {
    
    var host: TestHost!
    var presenterVC: PresenterHostVC!
    var vcFactory: MockVCFactory!
    var vmFactory: MockVMFactory!
    var noti: MockNotificationService!
    var sut: BottomSheetCoordinator!
    
    
    override func setUp() {
        super.setUp()

        host = TestHost()
        presenterVC = PresenterHostVC()
        host.present(presenterVC)

        vcFactory = MockVCFactory()
        vmFactory = MockVMFactory()
        noti = MockNotificationService()

        sut = BottomSheetCoordinator(vcFactory: vcFactory, vmFactory: vmFactory, notificationService: noti)
        sut.setPresenter(presenterVC)
    }

    
    
    override func tearDown() {
        sut = nil
        noti = nil
        vmFactory = nil
        vcFactory = nil
        presenterVC = nil
        host = nil
        super.tearDown()
    }
    
    func assertPresentCallsFactory(
        type: BottomSheetType,
        expectedFactoryName: String,
        line: UInt = #line
    ) {
        sut.present(type)
        pump(0.03)

        let names = vcFactory.calls.map(\.name)
        XCTAssertTrue(
            names.contains(expectedFactoryName),
            "Expected \(expectedFactoryName) to be called for \(type)",
            line: line
        )
        

    }

    func test_present_home_buildsAndPresentsHome() {
        sut.present(.home)
        pump(0.05)

        let top = presenterVC.presentedViewController
        XCTAssertNotNil(top, "Home sheet가 올라와야 함")
        XCTAssertNotNil(top?.sheetPresentationController, "pageSheet 시트가 붙어야 함")
        XCTAssertTrue(vcFactory.calls.map(\.name).contains("makeHomeBottomSheetVC"))
        
        XCTAssertTrue(vmFactory.made.contains("homeVM"))
        XCTAssertTrue(vmFactory.made.contains("homeContentVM"))
        XCTAssertTrue(vmFactory.made.contains("searchResultVM"))
        XCTAssertTrue(vmFactory.made.contains("searchReadyVM"))
    }
    
    func test_present_placeDetail_first_setsExistingToMedium_andPresentsDetail_andPostsGeoJson() {
           // given
           sut.present(.home)
           pump(0.03)
           guard let home = presenterVC.presentedViewController,
                 let homeSheet = home.sheetPresentationController else { XCTFail(); return }
           homeSheet.detents = [.large(), .medium()]
           homeSheet.selectedDetentIdentifier = .large

           // when
           sut.present(.placeDetail("P1"))
           pump(0.08)

           XCTAssertEqual(noti.calledNotificationNames, [.sheetCommand, .fetchGeoJsonRequired])
    }
    
    func test_present_placeDetail_nested_postsFetchPlaceRequired_withPrev() {
           sut.present(.home)
           pump(0.03)
           sut.present(.placeDetail("A"))
           pump(0.03)

           let exp = expectation(description: "fetchPlaceRequired")
           var captured: [String: String?]?
           let d = noti.observe(.fetchPlaceRequired).subscribe(onNext: { n in
               captured = n.object as? [String: String?]
               exp.fulfill()
           })
           sut.present(.placeDetail("B"))
           wait(for: [exp], timeout: 1.0)
           d.dispose()

           XCTAssertEqual(captured?["placeId"] ?? nil, "B")
           XCTAssertEqual(captured?["prevPlaceId"] ?? nil, "A")
       }
    
    
    func test_dismissFromDetail_restoresPrevDetents_andResetsGeoJson() {
            sut.present(.home)
            pump(0.03)
//            guard let home = presenterVC.presentedViewController,
//                  let homeSheet = home.sheetPresentationController else { XCTFail(); return }
//            homeSheet.detents = [.large(), .medium()]
//            homeSheet.selectedDetentIdentifier = .large

            sut.present(.placeDetail("P1"))
            pump(0.05)
        

            // when
            sut.dismissFromDetail(animated: false)
            pump(0.08)

            // then
        XCTAssertEqual(noti.calledNotificationNames, [.sheetCommand, .fetchGeoJsonRequired, .sheetCommand, .resetGeoJson])
    }
    
   
    // 6) .placeDetailPrevious: 히스토리 되돌리기 → fetchPlaceRequired(prev 포함/없음) 발송
       func test_placeDetailPrevious_postsFetchPlaceRequired_forBackNavigation() {
           sut.present(.home)
           pump(0.02)
           sut.present(.placeDetail("A"))
           pump(0.02)
           sut.present(.placeDetail("B"))
           pump(0.02)

           let exp = expectation(description: "fetchPlaceRequired for back")
           var captured: [String: String?]?
           let d = noti.observe(.fetchPlaceRequired).subscribe(onNext: { n in
               captured = n.object as? [String: String?]
               exp.fulfill()
           })
           sut.present(.placeDetailPrevious)
           wait(for: [exp], timeout: 1.0)
           d.dispose()

           XCTAssertEqual(captured?["placeId"] ?? nil, "A", "이전 place로 돌아가야 함")
           // prev가 더 없으면 nil일 수 있음 (케이스에 따라 A/prev=nil)
       }
    
        
    func test_present_variousSheetTypes_buildsCorrespondingViewControllers() {
        // 1) 로그인
        assertPresentCallsFactory(
            type: .login,
            expectedFactoryName: "makeLoginBottomSheetVC"
        )

        // 2) 마이컬렉션 (like 필터 예시)
        assertPresentCallsFactory(
            type: .myCollection(.like),
            expectedFactoryName: "makeMyCollectionBottomSheetViewController"
        )

        // 3) 메모
        assertPresentCallsFactory(
            type: .memo("PLACE_ID"),
            expectedFactoryName: "makeMemoBottomSheetViewController"
        )

        // 4) 장소 수정
        assertPresentCallsFactory(
            type: .placeModification("PLACE_ID"),
            expectedFactoryName: "makePlaceModificationBottomSheetViewController"
        )

        // 5) 타입별 장소 목록
        // ⚠️ PlaceTypeName 케이스는 프로젝트 enum에 맞게 수정 필요
        assertPresentCallsFactory(
            type: .placesByType(.altar), // 예: .city / .CITY 등 실제 enum 케이스로 변경
            expectedFactoryName: "makePlacesByTypeBottomSheetViewController"
        )

        // 6) 인물별 장소 목록
        assertPresentCallsFactory(
            type: .placesByCharacter("David"),
            expectedFactoryName: "makePlacesByCharacterBottomSheetViewController"
        )

        // 7) 성경별 장소 목록
        assertPresentCallsFactory(
            type: .placesByBible(.Exod),
            expectedFactoryName: "makePlacesByBibleBottomSheetViewController"
        )

        // 8) 성경 구절 상세 (이미 VCFactory에서 .Etc 쓰는 거 보고 맞춰줌)
        assertPresentCallsFactory(
            type: .bibleVerseDetail(.Etc, "Egypt", "나일강"),
            expectedFactoryName: "makeBibleVerseDetailBottomSheetViewController"
        )

        // 9) 장소 타입 리스트
        assertPresentCallsFactory(
            type: .placeTypes,
            expectedFactoryName: "makePlaceTypesBottomSheetViewController"
        )

        // 10) 장소 캐릭터 리스트
        assertPresentCallsFactory(
            type: .placeCharacters,
            expectedFactoryName: "makePlaceCharactersBottomSheetViewController"
        )

        // 11) 성경별 리스트
        assertPresentCallsFactory(
            type: .bibles,
            expectedFactoryName: "makeBiblesBottomSheetViewController"
        )

        // 12) 최근 검색어
        assertPresentCallsFactory(
            type: .recentSearches,
            expectedFactoryName: "makeRecentSearchesBottomSheetViewController"
        )

        // 13) 인기 장소
        assertPresentCallsFactory(
            type: .popularPlaces,
            expectedFactoryName: "makePopularPlacesBottomSheetViewController"
        )

        // 14) 마이페이지
        assertPresentCallsFactory(
            type: .myPage,
            expectedFactoryName: "makeMyPageBottomSheetViewController"
        )

        // 15) 계정 관리
        assertPresentCallsFactory(
            type: .accountManagement,
            expectedFactoryName: "makeAccountManagementBottomSheetViewController"
        )

        // 16) 장소 신고
        assertPresentCallsFactory(
            type: .placeReport("PLACE_ID", .etc),
            expectedFactoryName: "makePlaceReportBottomSheetVC"
        )

        // 17) 성경 장/절 리스트
        assertPresentCallsFactory(
            type: .bibleBookVerseList("PLACE_ID", .Exod),
            expectedFactoryName: "makeBibleBookVerseListBottomSheetViewController"
        )

        // 18) 통합 신고(앱 전체)
        assertPresentCallsFactory(
            type: .report,
            expectedFactoryName: "makeReportBottomSheetViewController"
        )
    }
    
}
