import XCTest
import RxSwift
import RxRelay
@testable import BibleAtlas



final class SearchReadyViewControllerTests: XCTestCase {
    var sut: SearchReadyViewController!
    var mockVM: MockSearchReadyViewModel!

    override func setUp() {
        super.setUp()
        mockVM = MockSearchReadyViewModel()
        sut = SearchReadyViewController(searchReadyViewModel: mockVM)
        // Load view hierarchy
        _ = sut.view
        sut.view.layoutIfNeeded()
    }

    override func tearDown() {
        sut = nil
        mockVM = nil
        super.tearDown()
    }

    // MARK: - Recent searches visibility

    func test_recentSearches_empty_hidesRecentStack() {
        mockVM.recentSearches$.accept([])
        mockVM.errorToFetchRecentSearches$.accept(nil)

        // Trigger initial bindings again by simulating lifecycle
        sut.viewDidLoad()
        sut.view.layoutIfNeeded()

        XCTAssertTrue(sut._test_isRecentSearchStackHidden)
    }

    func test_recentSearches_present_showsRecentStack_andTableCount() {
        let items = [
            RecentSearchItem(id: "r1", name: "A", koreanName: "가", type: "t"),
            RecentSearchItem(id: "r2", name: "B", koreanName: "나", type: "t")
        ]
        mockVM.recentSearches$.accept(items)
        mockVM.errorToFetchRecentSearches$.accept(nil)

        sut.viewDidLoad()
        sut.view.layoutIfNeeded()

        XCTAssertFalse(sut._test_isRecentSearchStackHidden)
        XCTAssertEqual(sut._test_recentTable.numberOfRows(inSection: 0), items.count)
    }

    // MARK: - Popular places loading/empty/content

    func test_popularPlaces_isFetching_showsLoading() {
        mockVM.isFetching$.accept(true)
        mockVM.errorToFetchPlaces$.accept(nil)
        mockVM.popularPlaces$.accept([])

        sut.viewDidLoad()
        sut.view.layoutIfNeeded()

        XCTAssertTrue(sut._test_isLoadingVisible)
        XCTAssertTrue(sut._test_popularTable.isHidden)
    }

    func test_popularPlaces_empty_showsEmpty_andHidesMoreButton() {
        mockVM.isFetching$.accept(false)
        mockVM.errorToFetchPlaces$.accept(nil)
        mockVM.popularPlaces$.accept([])

        sut.viewDidLoad()
        sut.view.layoutIfNeeded()

        XCTAssertFalse(sut._test_emptyView.isHidden)
        XCTAssertTrue(sut._test_popularTable.isHidden)
        XCTAssertTrue(sut._test_morePopularButton.isHidden)
    }

    func test_popularPlaces_nonEmpty_showsTable_andMoreButton() {
        mockVM.isFetching$.accept(false)
        mockVM.errorToFetchPlaces$.accept(nil)
        let places = [
            Place.mock(id: "p1", name: "P1"),
            Place.mock(id: "p2", name: "P2")
        ]
        mockVM.popularPlaces$.accept(places)

        sut.viewDidLoad()
        sut.view.layoutIfNeeded()

        XCTAssertFalse(sut._test_popularTable.isHidden)
        XCTAssertTrue(sut._test_emptyView.isHidden)
        XCTAssertFalse(sut._test_morePopularButton.isHidden)
        XCTAssertEqual(sut._test_popularTable.numberOfRows(inSection: 0), places.count)
    }

    // MARK: - Cell taps propagate to ViewModel

    func test_recentSearchCellTap_propagatesIdToViewModel() {
        let items = [RecentSearchItem(id: "rid", name: "A", koreanName: "가", type: "t")]
        mockVM.recentSearches$.accept(items)
        mockVM.errorToFetchRecentSearches$.accept(nil)

        sut.viewDidLoad()
        sut.view.layoutIfNeeded()

        let index = IndexPath(row: 0, section: 0)
        sut.tableView(sut._test_recentTable, didSelectRowAt: index)

        XCTAssertEqual(mockVM.lastRecentTappedId, "rid")
    }

    func test_popularPlaceCellTap_propagatesIdToViewModel() {
        let places = [Place.mock(id: "pid", name: "P")]
        mockVM.popularPlaces$.accept(places)
        mockVM.isFetching$.accept(false)
        mockVM.errorToFetchPlaces$.accept(nil)

        sut.viewDidLoad()
        sut.view.layoutIfNeeded()

        let index = IndexPath(row: 0, section: 0)
        sut.tableView(sut._test_popularTable, didSelectRowAt: index)

        XCTAssertEqual(mockVM.lastPopularTappedId, "pid")
    }

    // MARK: - More buttons

    func test_tap_moreButtons_propagatesToViewModel() {
        sut.viewDidLoad()
        sut.view.layoutIfNeeded()

        sut._test_moreRecentButton.sendActions(for: .touchUpInside)
        sut._test_morePopularButton.sendActions(for: .touchUpInside)

        XCTAssertTrue(mockVM.didTapMoreRecent)
        XCTAssertTrue(mockVM.didTapMorePopular)
    }

    // MARK: - Error state shows retry view

    func test_errorToFetchPlaces_showsErrorRetryView() {
        mockVM.isFetching$.accept(false)
        mockVM.errorToFetchPlaces$.accept(.clientError("e"))
        mockVM.popularPlaces$.accept([])

        sut.viewDidLoad()
        sut.view.layoutIfNeeded()

        XCTAssertFalse(sut._test_errorRetryView.isHidden)
        XCTAssertFalse(sut._test_isLoadingVisible)
    }
}
