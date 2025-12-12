//
//  VMFactoryTests.swift
//  BibleAtlasTests
//
//  Created by 성연 배 on 12/6/25.
//

import XCTest
import RxSwift
@testable import BibleAtlas

final class VMFactoryTests: XCTestCase {

    private var sut: VMFactory!
    private var navigator: MockBottomSheetNavigator!
    private var appCoordinator: MockAppCoordinator!
    private var appStore: MockAppStore!

    override func setUp() {
        super.setUp()

        // AppState는 기존에 쓰던 멤버와 동일하게 생성
        let initialState = AppState(profile: nil, isLoggedIn: false)
        appStore = MockAppStore(state: initialState)

        navigator = MockBottomSheetNavigator()
        appCoordinator = MockAppCoordinator()

        // usecases / collectionStore / notification / recentSearchService 는 nil로 두어도
        // VMFactory 내부에서 옵셔널로 넘기고 있어서 생성 자체는 문제 없이 이뤄짐.
        sut = VMFactory(
            appStore: appStore,
            collectionStore: nil,
            usecases: nil,
            notificationService: nil,
            recentSearchService: nil
        )

        sut.configure(navigator: navigator, appCoordinator: appCoordinator)
    }

    override func tearDown() {
        sut = nil
        navigator = nil
        appCoordinator = nil
        appStore = nil
        super.tearDown()
    }

    // MARK: - Home / Main 관련

    func test_makeHomeBottomSheetVM_returnsHomeBottomSheetViewModel() {
        let vm = sut.makeHomeBottomSheetVM()
        XCTAssertTrue(vm is HomeBottomSheetViewModel)
    }

    func test_makeHomeContentVM_returnsHomeContentViewModel() {
        let vm = sut.makeHomeContentVM()
        XCTAssertTrue(vm is HomeContentViewModel)
    }

    func test_makeSearchResultVM_returnsSearchResultViewModel() {
        let keyword$ = Observable.just("test")
        let isSearchingMode$ = Observable.just(true)
        let cancel$ = Observable<Void>.never()

        let vm = sut.makeSearchResultVM(
            keyword$: keyword$,
            isSearchingMode$: isSearchingMode$,
            cancelButtonTapped$: cancel$
        )

        XCTAssertTrue(vm is SearchResultViewModel)
    }

    func test_makeSearchReadyVM_returnsSearchReadyViewModel() {
        let vm = sut.makeSearchReadyVM()
        XCTAssertTrue(vm is SearchReadyViewModel)
    }

    func test_makeMainVM_returnsMainViewModel() {
        let vm = sut.makeMainVM()
        XCTAssertTrue(vm is MainViewModel)
    }

    // MARK: - Auth / Account / MyPage

    func test_makeLoginBottomSheetVM_returnsLoginBottomSheetViewModel() {
        let vm = sut.makeLoginBottomSheetVM()
        XCTAssertTrue(vm is LoginBottomSheetViewModel)
    }

    func test_makeMyPageBottomSheetVM_returnsMyPageBottomSheetViewModel() {
        let vm = sut.makeMyPageBottomSheetVM()
        XCTAssertTrue(vm is MyPageBottomSheetViewModel)
    }

    func test_makeAccountManagementBottomSheetVM_returnsAccountManagementBottomSheetViewModel() {
        let vm = sut.makeAccountManagementBottomSheetVM()
        XCTAssertTrue(vm is AccountManagementBottomSheetViewModel)
    }

    // MARK: - Collections / Places (기본)

    func test_makeMyCollectionBottomSheetVM_returnsMyCollectionBottomSheetViewModel() {
        let vm = sut.makeMyCollectionBottomSheetVM(filter: .like)
        XCTAssertTrue(vm is MyCollectionBottomSheetViewModel)
    }

    func test_makePlaceDetailBottomSheetVM_returnsPlaceDetailViewModel() {
        let vm = sut.makePlaceDetailBottomSheetVM(placeId: "test-place-id")
        XCTAssertTrue(vm is PlaceDetailViewModel)
    }

    func test_makeMemoBottomSheetVM_returnsMemoBottomSheetViewModel() {
        let vm = sut.makeMemoBottomSheetVM(placeId: "test-place-id")
        XCTAssertTrue(vm is MemoBottomSheetViewModel)
    }

    func test_makePlaceModificationBottomSheerVM_returnsPlaceModificationBottomSheetViewModel() {
        let vm = sut.makePlaceModificationBottomSheerVM(placeId: "test-place-id")
        XCTAssertTrue(vm is PlaceModificationBottomSheetViewModel)
    }

    // MARK: - Place Types / Characters / Bible / Popular

    func test_makePlaceTypesBottomSheetVM_returnsPlaceTypesBottomSheetViewModel() {
        let vm = sut.makePlaceTypesBottomSheetVM()
        XCTAssertTrue(vm is PlaceTypesBottomSheetViewModel)
    }

    func test_makePlaceCharactersBottomSheetVM_returnsPlaceCharactersBottomSheetViewModel() {
        let vm = sut.makePlaceCharactersBottomSheetVM()
        XCTAssertTrue(vm is PlaceCharactersBottomSheetViewModel)
    }

    func test_makeBiblesBottomSheetVM_returnsBiblesBottomSheetViewModel() {
        let vm = sut.makeBiblesBottomSheetVM()
        XCTAssertTrue(vm is BiblesBottomSheetViewModel)
    }

    func test_makePopularPlacesBottomSheetVM_returnsPopularPlacesBottomSheetViewModel() {
        let vm = sut.makePopularPlacesBottomSheetVM()
        XCTAssertTrue(vm is PopularPlacesBottomSheetViewModel)
    }

    func test_makePlacesByTypeBottomSheetVM_returnsPlacesByTypeBottomSheetViewModel() {
        // ⚠️ 이 라인의 .river 는 네 프로젝트의 실제 PlaceTypeName 케이스로 바꿔줘야 함.
        // 예: .river / .mountain / .settlement 등등
        let typeName: PlaceTypeName = .river  // <- 실제 케이스로 교체 필요

        let vm = sut.makePlacesByTypeBottomSheetVM(placeTypeName: typeName)
        XCTAssertTrue(vm is PlacesByTypeBottomSheetViewModel)
    }

    func test_makePlacesByCharacterBottomSheetVM_returnsPlacesByCharacterBottomSheetViewModel() {
        let vm = sut.makePlacesByCharacterBottomSheetVM(character: "A")
        XCTAssertTrue(vm is PlacesByCharacterBottomSheetViewModel)
    }

    func test_makePlacesByBibleBottomSheetVM_returnsPlacesByBibleBottomSheetViewModel() {
        let vm = sut.makePlacesByBibleBottomSheetVM(bible: .Gen)
        XCTAssertTrue(vm is PlacesByBibleBottomSheetViewModel)
    }

    // MARK: - Bible Verse / Report / Recent / Etc

    func test_makeBibleVerseDetailBottomSheetVM_returnsBibleVerseDetailBottomSheetViewModel() {
        let vm = sut.makeBibleVerseDetailBottomSheetVM(
            bibleBook: .Gen,
            keyword: "1:1",
            placeName: "Eden"
        )
        XCTAssertTrue(vm is BibleVerseDetailBottomSheetViewModel)
    }

    func test_makeRecentSearchesBottomSheetVM_returnsRecentSearchesBottomSheetViewModel() {
        let vm = sut.makeRecentSearchesBottomSheetVM()
        XCTAssertTrue(vm is RecentSearchesBottomSheetViewModel)
    }

    func test_makeReportBottomSheetVM_returnsReportBottomSheetViewModel() {
        let vm = sut.makeReportBottomSheetVM()
        XCTAssertTrue(vm is ReportBottomSheetViewModel)
    }

    func test_makePlaceReportBottomSheetVM_returnsPlaceReportBottomSheetViewModel() {
        let vm = sut.makePlaceReportBottomSheetVM(
            placeId: "test-place-id",
            reportType: .falseInfomation   // 네 enum에 있는 케이스 그대로 사용
        )
        XCTAssertTrue(vm is PlaceReportBottomSheetViewModel)
    }

    func test_makeBibleBookVerseListBottomSheetVM_returnsBibleBookVerseListBottomSheetViewModel() {
        let vm = sut.makeBibleBookVerseListBottomSheetVM(
            placeId: "test-place-id",
            bibleBook: .Gen
        )
        XCTAssertTrue(vm is BibleBookVerseListBottomSheetViewModel)
    }
}
