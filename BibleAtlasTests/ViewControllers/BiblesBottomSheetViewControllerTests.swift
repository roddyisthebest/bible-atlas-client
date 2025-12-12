//
//  BiblesBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
@testable import BibleAtlas

final class BiblesBottomSheetViewControllerTests: XCTestCase {
    
    private var sut: BiblesBottomSheetViewController!
    private var mockVM: MockBiblesBottomSheetViewModel!
    
    override func setUp() {
        super.setUp()
        mockVM = MockBiblesBottomSheetViewModel()
        sut = BiblesBottomSheetViewController(vm: mockVM)
        
        // viewDidLoad 호출
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
    
    // MARK: - viewLoaded 바인딩
    
    func test_viewDidLoad_emits_viewLoaded_toViewModel() {
        XCTAssertEqual(mockVM.viewLoadedCount, 1)
    }
    
    // MARK: - close 버튼 바인딩
    
    func test_closeButtonTap_emits_closeButtonTapped_toViewModel() {
        // when
        sut._test_closeButton.sendActions(for: .touchUpInside)
        pump()
        
        // then
        XCTAssertEqual(mockVM.closeButtonTapCount, 1)
    }
    
    // MARK: - 상태별 UI
    
    func test_loadingState_showsLoadingAndHidesOthers() {
        // given
        mockVM.isInitialLoadingRelay.accept(true)
        mockVM.errorRelay.accept(nil)
        mockVM.bibleBookCountsRelay.accept([])
        pump()
        
        // then
        XCTAssertFalse(sut._test_loadingView.isHidden)
        XCTAssertTrue(sut._test_collectionView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertTrue(sut._test_errorRetryView.isHidden)
    }
    
    func test_emptyState_showsEmptyLabelAndHidesCollectionView() {
        // given
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(nil)
        mockVM.bibleBookCountsRelay.accept([])
        pump()
        
        // then
        XCTAssertTrue(sut._test_loadingView.isHidden)
        XCTAssertFalse(sut._test_emptyLabel.isHidden)
        XCTAssertTrue(sut._test_collectionView.isHidden)
        XCTAssertTrue(sut._test_errorRetryView.isHidden)
    }
    
    func test_errorState_showsErrorViewAndHidesOthers() {
        // given
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(.clientError("테스트 에러"))
        pump()
        
        // then
        XCTAssertTrue(sut._test_loadingView.isHidden)
        XCTAssertTrue(sut._test_collectionView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertFalse(sut._test_errorRetryView.isHidden)
    }
    
    func test_nonEmptyState_showsCollectionViewAndHidesEmptyLabel() {
        // given
        let dummy = BibleBookCount(bible: .Etc, placeCount: 3) // 실제 enum 케이스에 맞게 수정 가능
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(nil)
        mockVM.bibleBookCountsRelay.accept([dummy])
        pump()
        
        // then
        XCTAssertTrue(sut._test_loadingView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertFalse(sut._test_collectionView.isHidden)
        XCTAssertEqual(sut._test_collectionView.numberOfItems(inSection: 0), 1)
    }
    
    // MARK: - 셀 탭 바인딩
    
    func test_didSelectItem_emits_cellTapped_toViewModel() {
        // given
        let dummy = BibleBookCount(bible: .Etc, placeCount: 5) // BibleBook 실제 케이스에 맞게만 수정
        mockVM.bibleBookCountsRelay.accept([dummy])
        pump()
        
        let indexPath = IndexPath(item: 0, section: 0)
        
        // when: 컬렉션뷰 선택 이벤트 트리거
        sut.collectionView(
            sut._test_collectionView,
            didSelectItemAt: indexPath
        )
        pump()
        
        // then
        XCTAssertEqual(mockVM.cellTappedBooks.count, 1)
        XCTAssertEqual(mockVM.cellTappedBooks.first, dummy.bible)
    }
    
    func test_flowLayout_sizeAndSpacing_areExpected() {
        // Ensure layout has concrete bounds
        sut.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        sut.view.layoutIfNeeded()

        let cv = sut._test_collectionView
        let layout = cv.collectionViewLayout

        let indexPath = IndexPath(item: 0, section: 0)
        let size = sut.collectionView(cv, layout: layout, sizeForItemAt: indexPath)

        // spacing = 10, totalSpacing = 40, width = (bounds.width - 40) / 3
        let expectedWidth = (cv.bounds.width - 40) / 3.0
        XCTAssertEqual(size.width, expectedWidth, accuracy: 1.0)
        XCTAssertEqual(size.height, expectedWidth + 20, accuracy: 1.0)

        let lineSpacing = sut.collectionView(cv, layout: layout, minimumLineSpacingForSectionAt: 0)
        XCTAssertEqual(lineSpacing, 0)

        let interSpacing = sut.collectionView(cv, layout: layout, minimumInteritemSpacingForSectionAt: 0)
        XCTAssertEqual(interSpacing, 10)
    }
    
    func test_headerLabel_hasTitle() {
        let title = sut._test_headerLabel.text ?? ""
        XCTAssertFalse(title.isEmpty)
    }
    
    func test_nonEmptyState_twoItems_cellsAreConfigured() {
        // given
        let dummies = [
            BibleBookCount(bible: .Gen, placeCount: 3),
            BibleBookCount(bible: .Exod, placeCount: 5)
        ]
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(nil)
        mockVM.bibleBookCountsRelay.accept(dummies)
        pump()

        // then
        let cv = sut._test_collectionView
        XCTAssertEqual(cv.numberOfItems(inSection: 0), 2)

        let cell0 = sut.collectionView(cv, cellForItemAt: IndexPath(item: 0, section: 0))
        let cell1 = sut.collectionView(cv, cellForItemAt: IndexPath(item: 1, section: 0))
        XCTAssertTrue(cell0 is BibleBookCell)
        XCTAssertTrue(cell1 is BibleBookCell)
    }
    
    func test_forceMedium_and_restoreDetents_doesNotCrash() {
        // When
        mockVM.forceMediumRelay.accept(())
        pump()
        mockVM.restoreDetentsRelay.accept(())
        pump()

        // Then: nothing to assert (sheetPresentationController may be nil in unit tests),
        // but reaching here means the subscriptions ran without crashing.
        XCTAssertTrue(true)
    }
}
