//
//  MyCollectionBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
@testable import BibleAtlas

final class MyCollectionBottomSheetViewControllerTests: XCTestCase {
    
    private var sut: MyCollectionBottomSheetViewController!
    private var mockVM: MockMyCollectionBottomSheetViewModel!
    
    override func setUp() {
        super.setUp()
        mockVM = MockMyCollectionBottomSheetViewModel(initialFilter: .like)
        sut = MyCollectionBottomSheetViewController(myCollectionBottomSheetViewModel: mockVM)
        
        // viewDidLoad + bindViewModel 실행
        _ = sut.view
        pump()
    }
    
    override func tearDown() {
        sut = nil
        mockVM = nil
        super.tearDown()
    }
    
    private func pump(_ seconds: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }
    
    // MARK: - Input 바인딩 테스트
    
    func test_viewDidLoad_emits_myCollectionViewLoaded() {
        // then
        XCTAssertEqual(mockVM.myCollectionViewLoadedCount, 1)
    }
    
    func test_closeButtonTap_emits_closeButtonTappedToViewModel() {
        // when
        sut._test_closeButton.sendActions(for: .touchUpInside)
        pump()
        
        // then
        XCTAssertEqual(mockVM.closeButtonTapCount, 1)
    }
    
    // MARK: - Header 텍스트 (filter 바인딩)
    
    func test_filter_like_setsHeaderToFavorites() {
        // given
        mockVM.filterRelay.accept(.like)
        pump()
        
        // then
        XCTAssertEqual(sut._test_headerLabel.text, L10n.MyCollection.favorites)
    }
    
    func test_filter_memo_setsHeaderToMemos() {
        // given
        mockVM.filterRelay.accept(.memo)
        pump()
        
        // then
        XCTAssertEqual(sut._test_headerLabel.text, L10n.MyCollection.memos)
    }
    
    func test_filter_save_setsHeaderToSaves() {
        // given
        mockVM.filterRelay.accept(.save)
        pump()
        
        // then
        XCTAssertEqual(sut._test_headerLabel.text, L10n.MyCollection.saves)
    }
    
    // MARK: - 로딩 / 빈 상태 / 에러 상태 UI
    
    func test_initialLoading_showsLoadingViewAndHidesTableAndEmptyAndError() {
        // given
        mockVM.isInitialLoadingRelay.accept(true)
        mockVM.errorRelay.accept(nil)
        mockVM.placesRelay.accept([])
        pump()
        
        // then
        XCTAssertFalse(sut._test_loadingView.isHidden)
        XCTAssertTrue(sut._test_tableView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertTrue(sut._test_errorRetryView.isHidden)
    }
    
    func test_afterLoading_withEmptyPlaces_showsEmptyLabelAndHidesTable() {
        // given
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(nil)
        mockVM.placesRelay.accept([])
        pump()
        
        // then
        XCTAssertTrue(sut._test_loadingView.isHidden)
        XCTAssertFalse(sut._test_emptyLabel.isHidden)
        XCTAssertTrue(sut._test_tableView.isHidden)
        XCTAssertTrue(sut._test_errorRetryView.isHidden)
    }
    
    func test_errorState_showsErrorViewAndHidesTableAndEmptyAndLoading() {
        // given
        let error = NetworkError.clientError("테스트 에러")
        mockVM.errorRelay.accept(error)
        mockVM.isInitialLoadingRelay.accept(false)
        pump()
        
        // then
        XCTAssertTrue(sut._test_loadingView.isHidden)
        XCTAssertTrue(sut._test_tableView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertFalse(sut._test_errorRetryView.isHidden)
    }
    
    // MARK: - bottomReached 바인딩 (스크롤 시)
    // Place 인스턴스 생성은 프로젝트 모델 정의에 맞게 수정 필요.
    
    func test_scrollToBottom_emits_bottomReachedToViewModel() {
        // given: 테이블에 데이터가 있다고 가정 (실제 Place 생성은 프로젝트 정의에 맞게 수정)
        // mockVM.placesRelay.accept([makeDummyPlace(id: "1")])
        // pump()
        
        let tableView = sut._test_tableView
        tableView.layoutIfNeeded()
        
        // contentSize 강제 세팅 (스크롤 가능한 상태)
        tableView.contentSize = CGSize(width: tableView.bounds.width, height: tableView.bounds.height * 2)
        tableView.contentOffset = CGPoint(x: 0, y: tableView.contentSize.height - tableView.bounds.height + 1)
        
        // when
        sut.scrollViewDidScroll(tableView)
        pump()
        
        // then
        XCTAssertEqual(mockVM.bottomReachedCount, 1)
    }
    
    // MARK: - Sheet detents (forceMedium / restoreDetents)
    func test_forceMedium_and_restoreDetents_changeSheetDetents() {
        // Use a fresh instance to set modalPresentationStyle before view loads
        let vm2 = MockMyCollectionBottomSheetViewModel(initialFilter: .like)
        let vc2 = MyCollectionBottomSheetViewController(myCollectionBottomSheetViewModel: vm2)
        vc2.modalPresentationStyle = .pageSheet
        _ = vc2.view
        pump(0.05)

        let initialCount = vc2.sheetPresentationController?.detents.count ?? 0

        // when: forceMedium
        vm2.forceMediumRelay.accept(())
        pump(0.05)

        // then: selected detent should be medium, and only one detent present
        XCTAssertEqual(vc2.sheetPresentationController?.selectedDetentIdentifier, .medium)
        XCTAssertEqual(vc2.sheetPresentationController?.detents.count, 1)
        XCTAssertEqual(vc2.sheetPresentationController?.largestUndimmedDetentIdentifier, .medium)

        // when: restore
        vm2.restoreDetentsRelay.accept(())
        pump(0.05)

        // then: detents restored to initial count (may be 0/1/.. depending on environment)
        XCTAssertEqual(vc2.sheetPresentationController?.detents.count ?? 0, initialCount)
    }

    // MARK: - TableView cells / selection / height
    func test_cell_separatorInsets_lastRow_vs_others_and_rowHeight() {
        // given
        let places = [
            Place.mock(id: "1", name: "A"),
            Place.mock(id: "2", name: "B")
        ]
        mockVM.placesRelay.accept(places)
        pump(0.05)

        // when
        let first = sut.tableView(sut._test_tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        let last = sut.tableView(sut._test_tableView, cellForRowAt: IndexPath(row: 1, section: 0))

        // then: separator inset
        XCTAssertEqual(first.separatorInset.left, 20, accuracy: 1.0)
        XCTAssertEqual(last.separatorInset.left, sut._test_tableView.bounds.width, accuracy: 1.0)

        // and: height is 80
        let h = sut.tableView(sut._test_tableView, heightForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(h, 80)
    }

    func test_cellForRowAt_returnsPlaceTableViewCell() {
        // given
        let places = [Place.mock(id: "1", name: "A")]
        mockVM.placesRelay.accept(places)
        pump(0.05)

        // when
        let cell = sut.tableView(sut._test_tableView, cellForRowAt: IndexPath(row: 0, section: 0))

        // then
        XCTAssertTrue(cell is PlaceTableViewCell)
    }

    func test_didSelectRow_forwardsPlaceIdToViewModel() {
        // given
        let places = [Place.mock(id: "pid", name: "P")] 
        mockVM.placesRelay.accept(places)
        pump(0.05)

        // when
        sut.tableView(sut._test_tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        pump(0.02)

        // then
        XCTAssertEqual(mockVM.selectedPlaceIds.last, "pid")
    }

    func test_numberOfRows_matchesPlacesCount() {
        let places = (1...3).map { Place.mock(id: "\($0)", name: "P\($0)") }
        mockVM.placesRelay.accept(places)
        pump(0.05)
        XCTAssertEqual(sut._test_tableView.numberOfRows(inSection: 0), 3)
    }

    // MARK: - Bottom reached gating
    func test_bottomReached_emitsOnlyOnceUntilScrollsUp() {
        let tv = sut._test_tableView
        tv.layoutIfNeeded()
        tv.contentSize = CGSize(width: tv.bounds.width, height: tv.bounds.height * 3)

        // 1) Scroll to bottom → emit once
        tv.contentOffset = CGPoint(x: 0, y: tv.contentSize.height - tv.bounds.height + 2)
        sut.scrollViewDidScroll(tv)
        pump(0.01)
        XCTAssertEqual(mockVM.bottomReachedCount, 1)

        // 2) Stay at bottom and call again → still 1 (gated)
        sut.scrollViewDidScroll(tv)
        pump(0.01)
        XCTAssertEqual(mockVM.bottomReachedCount, 1)

        // 3) Scroll up → reset gate, then bottom again → emit 2nd time
        tv.contentOffset = CGPoint(x: 0, y: 0)
        sut.scrollViewDidScroll(tv) // resets isBottomEmitted = false
        tv.contentOffset = CGPoint(x: 0, y: tv.contentSize.height - tv.bounds.height + 2)
        sut.scrollViewDidScroll(tv)
        pump(0.01)
        XCTAssertEqual(mockVM.bottomReachedCount, 2)
    }

    // MARK: - Footer loading toggles
    func test_isFetchingNext_togglesFooterLoading() {
        let tv = sut._test_tableView
        tv.layoutIfNeeded()
        tv.contentSize = CGSize(width: tv.bounds.width, height: tv.bounds.height * 2)
        pump(0.02)

        guard let footer = tv.tableFooterView as? LoadingView else {
            return XCTFail("Footer should be LoadingView")
        }

        mockVM.isFetchingNextRelay.accept(true)
        pump(0.05)
        XCTAssertTrue(footer.isAnimating)

        mockVM.isFetchingNextRelay.accept(false)
        pump(0.05)
        XCTAssertFalse(footer.isAnimating)
    }

    // MARK: - Error retry refetch
    func test_errorRetry_refetchButton_emitsToViewModel() {
        sut._test_errorRetryView.refetchTapped$.accept(())
        pump(0.02)
        XCTAssertEqual(mockVM.refetchButtonTapCount, 1)
    }
}

