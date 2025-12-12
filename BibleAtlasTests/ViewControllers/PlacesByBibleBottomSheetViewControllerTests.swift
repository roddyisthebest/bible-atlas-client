//
//  PlacesByBibleBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
@testable import BibleAtlas

final class PlacesByBibleBottomSheetViewControllerTests: XCTestCase {

    var sut: PlacesByBibleBottomSheetViewController!
    var mockVM: MockPlacesByBibleBottomSheetViewModel!

    override func setUp() {
        super.setUp()
        mockVM = MockPlacesByBibleBottomSheetViewModel()
        sut = PlacesByBibleBottomSheetViewController(vm: mockVM)

        sut.loadViewIfNeeded()
    }

    override func tearDown() {
        sut = nil
        mockVM = nil
        super.tearDown()
    }

    // MARK: - 1) viewLoaded → VM 호출 여부
    func test_viewDidLoad_triggersViewLoadedEvent() {
        XCTAssertEqual(mockVM.viewLoadedCallCount, 1)
    }

    // MARK: - 2) places 업데이트 → tableView reload & cell 반영
    func test_placesUpdate_reloadTableView() {
        // given
        let dummyPlaces = [
            Place.mock(id: "1", name: "Jerusalem"),
            Place.mock(id: "2", name: "Bethlehem")
        ]

        // when
        mockVM.placesSubject.onNext(dummyPlaces)

        // then
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertEqual(sut.tableView(sut._test_tableView, numberOfRowsInSection: 0), 2)

        let cell = sut.tableView(sut._test_tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? PlaceTableViewCell
        XCTAssertNotNil(cell)
    }

    // MARK: - 3) 스크롤 바닥 → bottomReached 호출
    func test_scrollViewDidScroll_triggersBottomReached() {
        let scrollView = sut._test_tableView

        scrollView.contentSize = CGSize(width: 100, height: 2000)
        scrollView.frame.size.height = 500

        scrollView.setContentOffset(CGPoint(x: 0, y: 1600), animated: false)

        sut.scrollViewDidScroll(scrollView)

        XCTAssertEqual(mockVM.bottomReachedCallCount, 1)
    }

    // MARK: - 4) error 발생 → errorRetryView 표시
    func test_error_emits_showsErrorRetryView() {
        mockVM.errorSubject.onNext(.clientError("TEST ERROR"))

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertFalse(sut._test_errorRetryView.isHidden)
        XCTAssertTrue(sut._test_tableView.isHidden)
    }

    // MARK: - 5) 로딩 상태 표시
    func test_isInitialLoading_showsLoadingView() {
        mockVM.isInitialLoadingSubject.onNext(true)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertFalse(sut._test_loadingView.isHidden)
        XCTAssertTrue(sut._test_tableView.isHidden)
    }

    // MARK: - 6) footer 로딩뷰 표시
    func test_isFetchingNext_showsFooterLoading() {
        mockVM.isFetchingNextSubject.onNext(true)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertFalse(sut._test_footerLoadingView.isHidden)
    }
}
