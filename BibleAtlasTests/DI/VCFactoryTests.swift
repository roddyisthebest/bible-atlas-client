//
//  VCFactoryTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/9/25.
//

import XCTest
@testable import BibleAtlas


// MARK: - Tests

final class VCFactoryTests: XCTestCase {

    private var sut: VCFactory!

    override func setUp() {
        super.setUp()
        sut = VCFactory()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - make*VC 테스트

    func test_makeHomeBottomSheetVC_returnsHomeBottomSheetViewController_andSetsModalInPresentation() {
        // given
        let homeVM = MockHomeBottomSheetViewModel()
        let homeContentVM = MockHomeContentViewModel()
        let searchResultVM = MockSearchResultViewModel()
        let searchReadyVM = MockSearchReadyViewModel()

        // when
        let vc = sut.makeHomeBottomSheetVC(
            homeVM: homeVM,
            homeContentVM: homeContentVM,
            searchResultVM: searchResultVM,
            searchReadyVM: searchReadyVM
        )

        // then
        XCTAssertTrue(vc is HomeBottomSheetViewController)
        XCTAssertTrue(vc.isModalInPresentation)   // home 타입에서 true로 세팅
    }

    func test_makeLoginBottomSheetVC_returnsLoginBottomSheetViewController() {
        // given
        let vm = MockLoginBottomSheetViewModel()

        // when
        let vc = sut.makeLoginBottomSheetVC(vm: vm)

        // then
        XCTAssertTrue(vc is LoginBottomSheetViewController)
        // login 은 isModalInPresentation = false (setupVC 안 타고 있음)
    }

    func test_makeMyCollectionBottomSheetVC_returnsMyCollectionBottomSheetViewController() {
        // given
        let vm = MockMyCollectionBottomSheetViewModel()

        // when
        let vc = sut.makeMyCollectionBottomSheetVC(vm: vm)

        // then
        XCTAssertTrue(vc is MyCollectionBottomSheetViewController)
    }

    func test_makePlaceDetailBottomSheetVC_returnsPlaceDetailViewController_andModalInPresentationTrue() {
        // given
        let vm = MockPlaceDetailViewModel()
        let placeId = "123"

        // when
        let vc = sut.makePlaceDetailBottomSheetVC(vm: vm, placeId: placeId)

        // then
        XCTAssertTrue(vc is PlaceDetailViewController)
        XCTAssertTrue(vc.isModalInPresentation)   // placeDetail case 에서 true
    }

    func test_makeMemoBottomSheetVC_returnsMemoBottomSheetViewController() {
        // given
        let vm = MockMemoBottomSheetViewModel()

        // when
        let vc = sut.makeMemoBottomSheetVC(vm: vm)

        // then
        XCTAssertTrue(vc is MemoBottomSheetViewController)
    }

    func test_makePlaceModificationBottomSheetVC_returnsPlaceModificationBottomSheetViewController() {
        // given
        let vm = MockPlaceModificationBottomSheetViewModel()

        // when
        let vc = sut.makePlaceModificationBottomSheetVC(vm: vm)

        // then
        XCTAssertTrue(vc is PlaceModificationBottomSheetViewController)
    }

    func test_makePlaceTypesBottomSheetVC_returnsPlaceTypesBottomSheetViewController() {
        // given
        let vm = MockPlaceTypesBottomSheetViewModel()

        // when
        let vc = sut.makePlaceTypesBottomSheetVC(vm: vm)

        // then
        XCTAssertTrue(vc is PlaceTypesBottomSheetViewController)
        XCTAssertTrue(vc.isModalInPresentation)   // default branch
    }

    func test_makeBiblesBottomSheetVC_returnsBiblesBottomSheetViewController() {
        // given
        let vm = MockBiblesBottomSheetViewModel()

        // when
        let vc = sut.makeBiblesBottomSheetVC(vm: vm)

        // then
        XCTAssertTrue(vc is BiblesBottomSheetViewController)
        XCTAssertTrue(vc.isModalInPresentation)   // default branch
    }

    func test_makeMainVC_returnsMainViewController() {
        // given
        let vm = MockMainViewModel()

        // when
        let vc = sut.makeMainVC(vm: vm)

        // then
        XCTAssertTrue(vc is MainViewController)
    }

    // MARK: - setupVC 테스트 (sheet 설정 확인)

    func test_setupVC_homeConfiguresSheetCorrectly() {
        // given
        let vc = UIViewController()
        vc.modalPresentationStyle = .pageSheet   // sheetPresentationController 활성화
        // when
        sut.setupVC(type: .home, sheet: vc)

        // then
        guard let sheet = vc.sheetPresentationController else {
            return XCTFail("sheetPresentationController should not be nil")
        }
        XCTAssertEqual(sheet.detents.count, 3) // [.large(), .medium(), lowestDetent]
        XCTAssertEqual(sheet.largestUndimmedDetentIdentifier, .medium)
        XCTAssertEqual(sheet.selectedDetentIdentifier, .medium)
        XCTAssertTrue(sheet.prefersGrabberVisible)
        XCTAssertFalse(sheet.prefersScrollingExpandsWhenScrolledToEdge)
        XCTAssertTrue(vc.isModalInPresentation)
    }

    func test_setupVC_loginConfiguresSheetCorrectly() {
        // given
        let vc = UIViewController()
        vc.modalPresentationStyle = .pageSheet

        // when
        sut.setupVC(type: .login, sheet: vc)

        // then
        guard let sheet = vc.sheetPresentationController else {
            return XCTFail("sheetPresentationController should not be nil")
        }
        XCTAssertEqual(sheet.detents.count, 2) // [highDetent, centerDetent]
        XCTAssertFalse(sheet.prefersGrabberVisible)
        XCTAssertTrue(sheet.prefersScrollingExpandsWhenScrolledToEdge)
        XCTAssertFalse(vc.isModalInPresentation)
    }

    func test_setupVC_defaultConfiguresLargeDetentAndModalInPresentation() {
        // given: placeTypes 는 switch 의 default 로 빠지는 케이스
        let vc = UIViewController()
        vc.modalPresentationStyle = .pageSheet

        // when
        sut.setupVC(type: .placeTypes, sheet: vc)

        // then
        guard let sheet = vc.sheetPresentationController else {
            return XCTFail("sheetPresentationController should not be nil")
        }
        XCTAssertEqual(sheet.detents.count, 1) // [.large()]
        XCTAssertFalse(sheet.prefersGrabberVisible)
        XCTAssertFalse(sheet.prefersScrollingExpandsWhenScrolledToEdge)
        XCTAssertTrue(vc.isModalInPresentation)
    }

    func test_setupVC_myPageUsesLowDetent() {
        // given
        let vc = UIViewController()
        vc.modalPresentationStyle = .pageSheet

        // when
        sut.setupVC(type: .myPage, sheet: vc)

        // then
        guard let sheet = vc.sheetPresentationController else {
            return XCTFail("sheetPresentationController should not be nil")
        }
        XCTAssertEqual(sheet.detents.count, 1)   // [lowDetent]
        XCTAssertTrue(sheet.prefersScrollingExpandsWhenScrolledToEdge)
        XCTAssertFalse(sheet.prefersGrabberVisible)
        // myPage 는 isModalInPresentation 을 건드리지 않음 -> 기본값 false
        XCTAssertFalse(vc.isModalInPresentation)
    }
    
    // MARK: - makePlacesByTypeBottomSheetVC

       func test_makePlacesByTypeBottomSheetVC_returnsPlacesByTypeBottomSheetViewController() {
           // given
           let vm = MockPlacesByTypeBottomSheetViewModel()

           // when
           let vc = sut.makePlacesByTypeBottomSheetVC(vm: vm, placeTypeName: .altar)

           // then
           XCTAssertTrue(vc is PlacesByTypeBottomSheetViewController)
           // sheet 설정은 setupVC 테스트에서 따로 검증
       }

       // MARK: - makePlacesByBibleBottomSheetVC

       func test_makePlacesByBibleBottomSheetVC_returnsPlacesByBibleBottomSheetViewController() {
           // given
           let vm = MockPlacesByBibleBottomSheetViewModel()

           // when
           let vc = sut.makePlacesByBibleBottomSheetVC(vm: vm, bibleBook: .Gen)

           // then
           XCTAssertTrue(vc is PlacesByBibleBottomSheetViewController)
       }

       // MARK: - makeRecentSearchesBottomSheetVC

       func test_makeRecentSearchesBottomSheetVC_returnsRecentSearchesBottomSheetViewController() {
           // given
           let vm = MockRecentSearchesBottomSheetViewModel()

           // when
           let vc = sut.makeRecentSearchesBottomSheetVC(vm: vm)

           // then
           XCTAssertTrue(vc is RecentSearchesBottomSheetViewController)
       }

       // MARK: - makePopularPlacesBottomSheetVC

       func test_makePopularPlacesBottomSheetVC_returnsPopularPlacesBottomSheetViewController() {
           // given
           let vm = MockPopularPlacesBottomSheetViewModel()

           // when
           let vc = sut.makePopularPlacesBottomSheetVC(vm: vm)

           // then
           XCTAssertTrue(vc is PopularPlacesBottomSheetViewController)
       }

       // MARK: - makeMyPageBottomSheetVC

       func test_makeMyPageBottomSheetVC_returnsMyPageBottomSheetViewController() {
           // given
           let vm = MockMyPageBottomSheetViewModel(menuItems: []);

           // when
           let vc = sut.makeMyPageBottomSheetVC(vm: vm)

           // then
           XCTAssertTrue(vc is MyPageBottomSheetViewController)
       }

       // MARK: - makeAccountManagementBottomSheetVC

       func test_makeAccountManagementBottomSheetVC_returnsAccountManagementBottomSheetViewController() {
           // given
           let vm = MockAccountManagementBottomSheetViewModel()

           // when
           let vc = sut.makeAccountManagementBottomSheetVC(vm: vm)

           // then
           XCTAssertTrue(vc is AccountManagementBottomSheetViewController)
       }

       // MARK: - makePlaceReportBottomSheetVC

       func test_makePlaceReportBottomSheetVC_returnsPlaceReportBottomSheetViewController() {
           // given
           let vm = MockPlaceReportBottomSheetViewModelForVC()

           // when
           let vc = sut.makePlaceReportBottomSheetVC(vm: vm)

           // then
           XCTAssertTrue(vc is PlaceReportBottomSheetViewController)
       }

       // MARK: - makeBibleBookVerseListBottomSheetVC

       func test_makeBibleBookVerseListBottomSheetVC_returnsBibleBookVerseListBottomSheetViewController() {
           // given
           let vm = MockBibleBookVerseListBottomSheetViewModel()

           // when
           let vc = sut.makeBibleBookVerseListBottomSheetVC(vm: vm)

           // then
           XCTAssertTrue(vc is BibleBookVerseListBottomSheetViewController)
       }

       // MARK: - makeReportBottomSheetVC

       func test_makeReportBottomSheetVC_returnsReportBottomSheetViewController() {
           // given
           let vm = MockReportBottomSheetViewModel()

           // when
           let vc = sut.makeReportBottomSheetVC(vm: vm)

           // then
           XCTAssertTrue(vc is ReportBottomSheetViewController)
           // setupVC를 안 쓰는 애라 presentation 설정은 없음
       }

}
