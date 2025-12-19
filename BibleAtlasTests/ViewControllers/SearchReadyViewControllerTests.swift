//
//  SearchReadyViewControllerTests.swift
//  BibleAtlas
//
//  Created by 배성연 on 12/12/25.
//

import XCTest
import RxSwift
import RxRelay
@testable import BibleAtlas


// MARK: - Testable VC
final class TestSearchReadyViewController: SearchReadyViewController {
    var lastPresentedAlert: UIAlertController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if let alert = viewControllerToPresent as? UIAlertController {
            lastPresentedAlert = alert
        }
        completion?()
    }
}

// MARK: - Tests
final class SearchReadyViewControllerTests: XCTestCase {
    private var sut: TestSearchReadyViewController!
    private var mockVM: MockSearchReadyViewModel!

    override func setUp() {
        super.setUp()
        mockVM = MockSearchReadyViewModel()
        sut = TestSearchReadyViewController(searchReadyViewModel: mockVM)
        _ = sut.view // trigger viewDidLoad + bind
    }

    override func tearDown() {
        sut = nil
        mockVM = nil
        super.tearDown()
    }

    private func pump(_ sec: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(sec))
    }

    // MARK: - Recent searches layout / visibility

    func test_recentSearches_hidden_whenEmpty_orError() {
        // 1) empty + no error => hidden
        mockVM.relays.recentSearches.accept([])
        mockVM.relays.errorToFetchRecentSearches.accept(nil)
        pump()
        XCTAssertTrue(sut._test_isRecentSearchStackHidden)

        // 2) error => hidden + alert presented
        XCTAssertNil(sut.lastPresentedAlert)
        mockVM.relays.errorToFetchRecentSearches.accept(.fetchFailed(NSError(domain: "t", code: 1)))
        pump()
        XCTAssertTrue(sut._test_isRecentSearchStackHidden)
        XCTAssertNotNil(sut.lastPresentedAlert)
    }

    func test_recentSearches_visible_and_tableHeightUpdated_whenDataProvided() {
        let items = [
            RecentSearchItem(id: "1", name: "A", koreanName: "가", type: "t"),
            RecentSearchItem(id: "2", name: "B", koreanName: "나", type: "t")
        ]
        mockVM.relays.errorToFetchRecentSearches.accept(nil)
        mockVM.relays.recentSearches.accept(items)
        pump()

        XCTAssertFalse(sut._test_isRecentSearchStackHidden)
        XCTAssertEqual(sut._test_recentTable.numberOfRows(inSection: 0), 2)
    }

    // MARK: - Popular places states

    func test_popularPlaces_loading_state() {
        mockVM.relays.isFetching.accept(true)
        mockVM.relays.errorToFetchPlaces.accept(nil)
        pump()

        XCTAssertTrue(sut._test_loadingView.isAnimating)
        XCTAssertTrue(sut._test_popularTable.isHidden)
    }

    func test_popularPlaces_empty_state() {
        mockVM.relays.isFetching.accept(false)
        mockVM.relays.errorToFetchPlaces.accept(nil)
        mockVM.relays.popularPlaces.accept([])
        pump()

        XCTAssertFalse(sut._test_loadingView.isAnimating)
        XCTAssertTrue(sut._test_popularTable.isHidden)
        XCTAssertFalse(sut._test_emptyView.isHidden)
        XCTAssertTrue(sut._test_morePopularButton.isHidden)
    }

    func test_popularPlaces_success_state() {
        let places = [
            Place.mock(id: "p1", name: "A"),
            Place.mock(id: "p2", name: "B")
        ]
        mockVM.relays.isFetching.accept(false)
        mockVM.relays.errorToFetchPlaces.accept(nil)
        mockVM.relays.popularPlaces.accept(places)
        pump()

        XCTAssertFalse(sut._test_loadingView.isAnimating)
        XCTAssertFalse(sut._test_popularTable.isHidden)
        XCTAssertTrue(sut._test_emptyView.isHidden)
        XCTAssertFalse(sut._test_morePopularButton.isHidden)
        XCTAssertEqual(sut._test_popularTable.numberOfRows(inSection: 0), 2)
    }

    func test_popularPlaces_error_state_showsErrorRetry() {
        mockVM.relays.isFetching.accept(false)
        mockVM.relays.errorToFetchPlaces.accept(.clientError("x"))
        pump()

        XCTAssertFalse(sut._test_loadingView.isAnimating)
        XCTAssertFalse(sut._test_errorRetryView.isHidden)
    }

    // MARK: - Interactions

    func test_tapping_recentRow_sendsId_toViewModel() {
        let items = [RecentSearchItem(id: "1", name: "A", koreanName: "가", type: "t")]
        mockVM.relays.errorToFetchRecentSearches.accept(nil)
        mockVM.relays.recentSearches.accept(items)
        pump()

        sut.tableView(sut._test_recentTable, didSelectRowAt: IndexPath(row: 0, section: 0))
        pump()

        XCTAssertEqual(mockVM.didTapRecentId, "1")
    }

    func test_tapping_popularRow_sendsId_toViewModel() {
        let places = [Place.mock(id: "p1", name: "A")]
        mockVM.relays.errorToFetchPlaces.accept(nil)
        mockVM.relays.isFetching.accept(false)
        mockVM.relays.popularPlaces.accept(places)
        pump()

        sut.tableView(sut._test_popularTable, didSelectRowAt: IndexPath(row: 0, section: 0))
        pump()

        XCTAssertEqual(mockVM.didTapPopularId, "p1")
    }

    func test_tapping_moreButtons_emitToViewModel() {
        sut._test_moreRecentButton.sendActions(for: .touchUpInside)
        sut._test_morePopularButton.sendActions(for: .touchUpInside)
        pump()

        XCTAssertTrue(mockVM.didTapMoreRecent)
        XCTAssertTrue(mockVM.didTapMorePopular)
    }
}

