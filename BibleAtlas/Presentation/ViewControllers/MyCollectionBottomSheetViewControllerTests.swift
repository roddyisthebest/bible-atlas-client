//
//  MyCollectionBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MyCollectionBottomSheetViewControllerAdditionalTests: XCTestCase {
    private var sut: MyCollectionBottomSheetViewController!
    private var mockVM: MockMyCollectionBottomSheetViewModel!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockVM = MockMyCollectionBottomSheetViewModel(initialFilter: .like)
        sut = MyCollectionBottomSheetViewController(myCollectionBottomSheetViewModel: mockVM)
        sut.modalPresentationStyle = .pageSheet
        _ = sut.view
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        sut = nil
        mockVM = nil
        disposeBag = nil
        super.tearDown()
    }

    private func pump(_ seconds: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    func test_closeButtonTap_incrementsViewModelCounter() {
        sut._test_closeButton.sendActions(for: .touchUpInside)
        pump()
        XCTAssertEqual(mockVM.closeButtonTapCount, 1)
    }

    func test_didSelectRow_forwardsPlaceId() {
        let places = [Place.mock(id: "p1", name: "P1")]
        mockVM.placesRelay.accept(places)
        pump()

        sut.tableView(sut._test_tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        pump()
        XCTAssertEqual(mockVM.selectedPlaceIds.last, "p1")
    }

    func test_scrollToBottom_emitsBottomReached() {
        let tv = sut._test_tableView
        tv.layoutIfNeeded()
        tv.contentSize = CGSize(width: tv.bounds.width, height: tv.bounds.height * 2)
        tv.contentOffset = CGPoint(x: 0, y: tv.contentSize.height - tv.bounds.height + 1)
        sut.scrollViewDidScroll(tv)
        pump()
        XCTAssertEqual(mockVM.bottomReachedCount, 1)
    }

    func test_isFetchingNext_togglesFooterLoading() {
        let tv = sut._test_tableView
        tv.layoutIfNeeded()
        guard let footer = tv.tableFooterView as? LoadingView else {
            return XCTFail("Footer should be LoadingView")
        }
        mockVM.isFetchingNextRelay.accept(true)
        pump()
        XCTAssertTrue(footer.isAnimating)
        mockVM.isFetchingNextRelay.accept(false)
        pump()
        XCTAssertFalse(footer.isAnimating)
    }

    func test_filter_changesHeaderLabel() {
        mockVM.filterRelay.accept(.memo)
        pump()
        XCTAssertEqual(sut._test_headerLabel.text, L10n.MyCollection.memos)
    }
}
