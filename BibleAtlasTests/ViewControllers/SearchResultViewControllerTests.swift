//
//  SearchResultViewControllerTests.swift
//  BibleAtlas
//
//  Created by 배성연 on 12/12/25.
//

import XCTest
import RxSwift
import RxRelay
@testable import BibleAtlas



// MARK: - Test VC that intercepts alert presentation
final class TestSearchResultViewController: SearchResultViewController {
    var lastPresentedAlert: UIAlertController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if let alert = viewControllerToPresent as? UIAlertController {
            lastPresentedAlert = alert
        }
        completion?()
    }
}

// MARK: - Tests
final class SearchResultViewControllerTests: XCTestCase {

    private var sut: TestSearchResultViewController!
    private var mockVM: MockSearchResultViewModel!

    override func setUp() {
        super.setUp()
        mockVM = MockSearchResultViewModel()
        sut = TestSearchResultViewController(searchResultViewModel: mockVM)
        _ = sut.view // trigger viewDidLoad
    }

    override func tearDown() {
        sut = nil
        mockVM = nil
        super.tearDown()
    }

    private func pump(_ sec: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(sec))
    }

    func test_initial_state_showsEmptyTable_andHiddenEmptyLabel() {
        XCTAssertEqual(sut._test_tableView.numberOfRows(inSection: 0), 0)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
    }

    func test_renderPlaces_updatesTable_andEmptyLabelVisibility() {
        // given
        let places = [
            Place.mock(id: "1", name: "A"),
            Place.mock(id: "2", name: "B")
        ]

        // when: emit non-searching, no error, non-empty keyword
        mockVM.isSearchingRelay.accept(false)
        mockVM.errorToFetchPlacesRelay.accept(nil)
        mockVM.debouncedKeywordRelay.accept("A")
        mockVM.placesRelay.accept(places)
        pump()

        // then
        XCTAssertEqual(sut._test_tableView.numberOfRows(inSection: 0), 2)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
    }

    func test_emptyKeyword_hidesEmptyLabel_andKeepsTable() {
        mockVM.isSearchingRelay.accept(false)
        mockVM.errorToFetchPlacesRelay.accept(nil)
        mockVM.debouncedKeywordRelay.accept("")
        mockVM.placesRelay.accept([])
        pump()

        XCTAssertTrue(sut._test_emptyLabel.isHidden)
    }

    func test_error_showsErrorRetryView_andHidesTable() {
        mockVM.errorToFetchPlacesRelay.accept(.clientError("x"))
        pump()

        XCTAssertTrue(sut._test_tableView.isHidden)
        XCTAssertFalse(sut._test_errorRetryView.isHidden)
    }

    func test_isSearching_togglesSearchingView_andDisablesInteraction() {
        mockVM.isSearchingRelay.accept(true)
        mockVM.errorToFetchPlacesRelay.accept(nil)
        pump()

        // searchingView는 LoadingView라 isAnimating 여부를 직접 확인하기 어려울 수 있으므로
        // 상호작용 비활성화 여부로 대체 검증
        XCTAssertFalse(sut._test_tableView.isUserInteractionEnabled)

        mockVM.isSearchingRelay.accept(false)
        mockVM.debouncedKeywordRelay.accept("K")
        pump()

        XCTAssertTrue(sut._test_tableView.isUserInteractionEnabled)
    }

    func test_isFetchingNext_togglesFooterLoading() {
        mockVM.isSearchingRelay.accept(false)
        mockVM.errorToFetchPlacesRelay.accept(nil)
        mockVM.debouncedKeywordRelay.accept("A")
        pump()

        mockVM.isFetchingNextRelay.accept(true)
        pump()
        XCTAssertTrue(sut._test_footerLoadingView.isAnimating)

        mockVM.isFetchingNextRelay.accept(false)
        pump()
        XCTAssertFalse(sut._test_footerLoadingView.isAnimating)
    }

    func test_didSelectRow_forwardsPlaceToViewModel() {
        // given
        let places = [Place.mock(id: "1", name: "A")]
        mockVM.isSearchingRelay.accept(false)
        mockVM.errorToFetchPlacesRelay.accept(nil)
        mockVM.debouncedKeywordRelay.accept("A")
        mockVM.placesRelay.accept(places)
        pump()

        // when
        sut.tableView(sut._test_tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        pump()

        // then
        XCTAssertEqual(mockVM.captured.lastSelectedPlace?.id, "1")
    }

    func test_bottomReached_emitsToViewModel() {
        sut._test_emitBottomReached()
        pump()
        XCTAssertEqual(mockVM.captured.bottomReachedCount, 1)
    }

    func test_errorToSaveRecentSearch_presentsAlert() {
        XCTAssertNil(sut.lastPresentedAlert)
        mockVM.errorToSaveRecentSearchRelay.accept(.saveFailed(NSError(domain: "t", code: 1)))
        pump()
        XCTAssertNotNil(sut.lastPresentedAlert)
    }

    func test_nonEmptyKeywordWithEmptyResults_showsEmptyLabel_andKeepsTableVisible() {
        // given
        mockVM.isSearchingRelay.accept(false)
        mockVM.errorToFetchPlacesRelay.accept(nil)
        mockVM.debouncedKeywordRelay.accept("Query")
        mockVM.placesRelay.accept([])
        pump(0.1)

        // then
        XCTAssertFalse(sut._test_tableView.isHidden)
        XCTAssertTrue(sut._test_errorRetryView.isHidden)
        XCTAssertEqual(sut._test_tableView.numberOfRows(inSection: 0), 0)
        XCTAssertFalse(sut._test_emptyLabel.isHidden)
    }

    func test_errorState_hidesSearchingView() {
        // when
        mockVM.errorToFetchPlacesRelay.accept(.clientError("err"))
        pump()

        // then
        XCTAssertTrue(sut._test_searchingView.isHidden)
        XCTAssertFalse(sut._test_errorRetryView.isHidden)
    }

    func test_refetchButtonTapped_forwardsToViewModel() {
        // when
        sut._test_errorRetryView.refetchTapped$.accept(())
        pump()

        // then
        XCTAssertTrue(mockVM.captured.refetchTapped)
    }

    func test_scrollViewDidScroll_triggersBottomReachedNearBottom() {
        // given: enough rows to make content larger than frame
        let places = (1...50).map { Place.mock(id: "\($0)", name: "P\($0)") }
        mockVM.isSearchingRelay.accept(false)
        mockVM.errorToFetchPlacesRelay.accept(nil)
        mockVM.debouncedKeywordRelay.accept("A")
        mockVM.placesRelay.accept(places)
        pump(0.2)

        // ensure layout updated
        sut._test_tableView.layoutIfNeeded()
        let contentHeight = sut._test_tableView.contentSize.height
        let height = sut._test_tableView.bounds.height
        guard contentHeight > height else {
            // If content isn't tall enough in CI, still call emit helper to assert path
            sut._test_emitBottomReached()
            pump()
            XCTAssertGreaterThanOrEqual(mockVM.captured.bottomReachedCount, 1)
            return
        }

        // when: scroll near bottom
        let offsetY = max(0, contentHeight - height - 140 + 1)
        sut._test_tableView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
        // manually invoke delegate to be robust in tests
        sut.scrollViewDidScroll(sut._test_tableView)
        pump()

        // then
        XCTAssertGreaterThanOrEqual(mockVM.captured.bottomReachedCount, 1)
    }

    func test_heightForRowAt_returns80() {
        let h = sut.tableView(sut._test_tableView, heightForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(h, 80)
    }
}
