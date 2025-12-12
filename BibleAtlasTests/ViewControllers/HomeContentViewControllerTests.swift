//
//  HomeContentViewControllerTests.swift
//  BibleAtlas
//
//  Created by 배성연 on 12/12/25.
//

import XCTest
@testable import BibleAtlas
import RxSwift

final class HomeContentViewControllerTests: XCTestCase {

    var vm: MockHomeContentViewModel!
    var vc: HomeContentViewController!
    var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        vm = MockHomeContentViewModel()
        vc = HomeContentViewController(homeContentViewModel: vm)
        disposeBag = DisposeBag()
        _ = vc.view // trigger viewDidLoad & bindings
        pump(0.02)
    }

    override func tearDown() {
        disposeBag = nil
        vc = nil
        vm = nil
        super.tearDown()
    }

    func test_loadingStateTogglesVisibility() {
        vm.setLoading(true)
        pump(0.02)
        XCTAssertTrue(vc._test_scrollView.isHidden)

        vm.setLoading(false)
        pump(0.02)
        XCTAssertFalse(vc._test_scrollView.isHidden)
    }

    func test_recentSearches_populateAndShowTable() {
        vm.setError(nil)
        let items = [RecentSearchItem(id: "1", name: "Bethlehem", koreanName: "베들레헴", type: "test"),
                     RecentSearchItem(id: "2", name: "Jerusalem", koreanName: "예루살렘", type: "test")]
        vm.setRecentSearches(items)
        pump(0.05)

        XCTAssertFalse(vc._test_recentTable.isHidden)
        XCTAssertFalse(vc._test_moreRecentButton.isHidden)
        XCTAssertEqual(vc._test_recentTable.numberOfRows(inSection: 0), items.count)
    }

    func test_emptyOrErrorState_hidesTableAndShowsEmpty() {
        vm.setRecentSearches([])
        vm.setError(RecentSearchError.unknown)
        pump(0.05)

        XCTAssertTrue(vc._test_recentTable.isHidden)
        XCTAssertTrue(vc._test_moreRecentButton.isHidden)
        XCTAssertFalse(vc._test_emptyView.isHidden)
    }

    func test_menuActions_emitInputs() {
        guard let input = vm.lastInput else { return XCTFail("Input should be set after bind") }

        let typeExp = expectation(description: "placesByType emitted")
        let charExp = expectation(description: "placesByCharacter emitted")
        let bibleExp = expectation(description: "placesByBible emitted")

        input.placesByTypeButtonTapped$
            .subscribe(onNext: { _ in typeExp.fulfill() })
            .disposed(by: disposeBag)

        input.placesByCharacterButtonTapped$
            .subscribe(onNext: { _ in charExp.fulfill() })
            .disposed(by: disposeBag)

        input.placesByBibleButtonTapped$
            .subscribe(onNext: { _ in bibleExp.fulfill() })
            .disposed(by: disposeBag)

        vc._test_emitPlacesByType()
        vc._test_emitPlacesByCharacter()
        vc._test_emitPlacesByBible()

        wait(for: [typeExp, charExp, bibleExp], timeout: 1.0)
    }

    func test_reportButtonTap_emitsInput() {
        guard let input = vm.lastInput else { return XCTFail("Input should be set after bind") }

        let exp = expectation(description: "report tapped")
        input.reportButtonTapped$
            .subscribe(onNext: { _ in exp.fulfill() })
            .disposed(by: disposeBag)

        vc._test_reportButton.sendActions(for: .touchUpInside)
        wait(for: [exp], timeout: 1.0)
    }

    func test_recentRowSelection_emitsId() {
        let items = [RecentSearchItem(id: "1", name: "A", koreanName: "가", type: "test"),
                     RecentSearchItem(id: "2", name: "B", koreanName: "나", type: "test")]
        vm.setError(nil)
        vm.setRecentSearches(items)
        pump(0.05)

        guard let input = vm.lastInput else { return XCTFail("Input should be set after bind") }
        let exp = expectation(description: "recent row tapped")
        var captured: String?
        input.recentSearchCellTapped$
            .subscribe(onNext: { id in
                captured = id
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        vc._test_selectRecentRow(1)
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(captured, items[1].id)
    }

    func test_moreRecentButtonTap_emitsInput() {
        vm.setError(nil)
        vm.setRecentSearches([RecentSearchItem(id: "1", name: "A", koreanName: "가", type: "test")])
        pump(0.05)

        guard let input = vm.lastInput else { return XCTFail("Input should be set after bind") }
        let exp = expectation(description: "more recent tapped")
        input.moreRecentSearchesButtonTapped$
            .subscribe(onNext: { _ in exp.fulfill() })
            .disposed(by: disposeBag)

        vc._test_moreRecentButton.sendActions(for: .touchUpInside)
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helpers
    private func findCollectionButtons() -> [CollectionButton] {
        vc.view.layoutIfNeeded()
        var result: [CollectionButton] = []
        func traverse(_ v: UIView) {
            if let b = v as? CollectionButton { result.append(b) }
            v.subviews.forEach(traverse)
        }
        traverse(vc.view)
        // 좌->우 순서로 정렬 (stackView 내 배치 순서를 반영)
        return result.sorted { $0.frame.minX < $1.frame.minX }
    }

    // MARK: - Additional coverage

    func test_emptyWithoutError_hidesTable_showsEmpty_andHidesMore() {
        vm.setError(nil)
        vm.setRecentSearches([])
        pump(0.05)

        XCTAssertTrue(vc._test_recentTable.isHidden)
        XCTAssertTrue(vc._test_moreRecentButton.isHidden)
        XCTAssertFalse(vc._test_emptyView.isHidden)
    }

    func test_forceMedium_disablesScroll() {
        // initially false (HomeContentViewController sets scrollView.isScrollEnabled = false)
        XCTAssertFalse(vc._test_scrollView.isScrollEnabled)
        vm.emitForceMedium()
        pump(0.05)
        XCTAssertFalse(vc._test_scrollView.isScrollEnabled)
    }

    func test_collectionCounts_updateSubLabels() {
        vm.setCounts(like: 7, save: 8, memo: 9)
        pump(0.05)

        let buttons = findCollectionButtons()
        XCTAssertEqual(buttons.count, 3, "Expected 3 collection buttons")

        // favorite, bookmark, memo 순서라고 가정 (좌->우)
        let favorite = buttons[0]
        let bookmark = buttons[1]
        let memo = buttons[2]

        XCTAssertTrue(favorite.subLabel.text?.contains("7") == true)
        XCTAssertTrue(bookmark.subLabel.text?.contains("8") == true)
        XCTAssertTrue(memo.subLabel.text?.contains("9") == true)
    }

    func test_collectionButtonsTap_emitFilters() {
        guard let input = vm.lastInput else { return XCTFail("Input should be set after bind") }

        var received: [PlaceFilter] = []
        let exp = expectation(description: "collection taps")
        exp.expectedFulfillmentCount = 3

        input.collectionButtonTapped$
            .subscribe(onNext: { filter in
                received.append(filter)
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        let buttons = findCollectionButtons()
        XCTAssertEqual(buttons.count, 3, "Expected 3 collection buttons")
        // 좌->우: favorite(.like), bookmark(.save), memo(.memo)
        buttons[0].sendActions(for: .touchUpInside)
        buttons[1].sendActions(for: .touchUpInside)
        buttons[2].sendActions(for: .touchUpInside)

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(received, [.like, .save, .memo])
    }

    func test_recentCell_separatorInsets_lastRow_vs_others() {
        vm.setError(nil)
        let items = [
            RecentSearchItem(id: "1", name: "A", koreanName: "가", type: "test"),
            RecentSearchItem(id: "2", name: "B", koreanName: "나", type: "test")
        ]
        vm.setRecentSearches(items)
        pump(0.05)

        let first = vc.tableView(vc._test_recentTable, cellForRowAt: IndexPath(row: 0, section: 0))
        let last = vc.tableView(vc._test_recentTable, cellForRowAt: IndexPath(row: 1, section: 0))

        XCTAssertEqual(first.separatorInset.left, 20, accuracy: 0.5)
        XCTAssertEqual(last.separatorInset.left, vc._test_recentTable.bounds.width, accuracy: 1.0)
    }

    func test_recentRowHeight_is80() {
        let height = vc.tableView(vc._test_recentTable, heightForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(height, 80)
    }
}

