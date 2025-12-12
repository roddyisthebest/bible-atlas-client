//
//  PlaceCharactersBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
import RxSwift
@testable import BibleAtlas

final class PlaceCharactersBottomSheetViewControllerTests: XCTestCase {
    
    private var sut: PlaceCharactersBottomSheetViewController!
    private var mockVM: MockPlaceCharactersBottomSheetViewModel!
    private var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        mockVM = MockPlaceCharactersBottomSheetViewModel()
        sut = PlaceCharactersBottomSheetViewController(vm: mockVM)
        
        // viewDidLoad 실행 + bindViewModel + viewLoaded$.accept()
        _ = sut.view
        pump()
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
    
    // PlacePrefix 임시 생성 헬퍼
    private func makePrefix(_ prefix: String, count: String = "3") -> PlacePrefix {
        // 👉 네 실제 PlacePrefix 정의에 맞게 수정해줘야 함
        // 예측: struct PlacePrefix { let prefix: String; let placeCount: String }
        return PlacePrefix(prefix: prefix, placeCount: count)
    }
    
    // MARK: - Life cycle / viewLoaded
    
    func test_viewDidLoad_triggersViewLoadedOnViewModel() {
        XCTAssertEqual(mockVM.viewLoadedCallCount, 1)
    }
    
    // MARK: - placeCharacters 바인딩
    
    func test_placeCharactersBinding_reloadCollectionViewAndShowCollection() {
        // given
        let items = [
            makePrefix("a", count: "2"),
            makePrefix("b", count: "5")
        ]
        mockVM.placeCharactersRelay.accept(items)
        
        // when
        pump()
        
        // then
        XCTAssertFalse(sut._test_collectionView.isHidden, "데이터 있을 때 collectionView는 보여야 함")
        XCTAssertTrue(sut._test_emptyLabel.isHidden, "데이터 있을 때 emptyLabel은 숨겨야 함")
        XCTAssertEqual(sut._test_collectionView.numberOfItems(inSection: 0), items.count)
    }
    
    // MARK: - 상태별 UI 토글
    
    func test_loadingState_showsLoadingAndHidesCollectionAndEmptyAndError() {
        // given
        mockVM.isInitialLoadingRelay.accept(true)
        mockVM.errorRelay.accept(nil)
        
        // when
        pump()
        
        // then
        XCTAssertTrue(sut._test_collectionView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertTrue(sut._test_errorRetryView.isHidden)
        XCTAssertFalse(sut._test_loadingView.isHidden)
    }
    
    func test_errorState_showsErrorRetryAndHidesCollectionAndEmptyAndLoading() {
        // given
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(.clientError("테스트 에러"))
        
        // when
        pump()
        
        // then
        XCTAssertTrue(sut._test_collectionView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertFalse(sut._test_errorRetryView.isHidden)
        XCTAssertTrue(sut._test_loadingView.isHidden)
    }
    
    func test_emptyState_showsEmptyLabelAndHidesCollection() {
        // given
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(nil)
        mockVM.placeCharactersRelay.accept([]) // 비어있음
        
        // when
        pump()
        
        // then
        XCTAssertTrue(sut._test_collectionView.isHidden)
        XCTAssertFalse(sut._test_emptyLabel.isHidden)
    }
    
    func test_nonEmptyState_showsCollectionAndHidesEmpty() {
        // given
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(nil)
        mockVM.placeCharactersRelay.accept([makePrefix("c")])
        
        // when
        pump()
        
        // then
        XCTAssertFalse(sut._test_collectionView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
    }
    
    // MARK: - 셀 선택 → ViewModel 인풋
    
    func test_didSelectItem_sendsUppercasedPrefixToViewModel() {
        // given
        let prefix = makePrefix("d", count: "10")
        mockVM.placeCharactersRelay.accept([prefix])
        pump()
        
        let indexPath = IndexPath(item: 0, section: 0)
        
        // when
        sut.collectionView(
            sut._test_collectionView,
            didSelectItemAt: indexPath
        )
        pump()
        
        // then
        XCTAssertEqual(mockVM.lastTappedCharacter, "D") // uppercased() 확인
    }
    
    // MARK: - 버튼/리트라이
    
    func test_closeButtonTap_triggersCloseOnViewModel() {
        // when
        sut._test_closeButton.sendActions(for: .touchUpInside)
        pump()
        
        // then
        XCTAssertEqual(mockVM.closeButtonTapCount, 1)
    }
    
    func test_errorRetryRefetchTap_triggersRefetchOnViewModel() {
        // when
        sut._test_errorRetryView.refetchTapped$.accept(())
        pump()
        
        // then
        XCTAssertEqual(mockVM.refetchButtonTapCount, 1)
    }
    
    // MARK: - 추가 테스트
    
    func test_flowLayout_sizeAndSpacing_areExpected() {
        // Ensure concrete bounds for layout calculation
        sut.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        sut.view.layoutIfNeeded()

        let cv = sut._test_collectionView
        let layout = cv.collectionViewLayout
        let indexPath = IndexPath(item: 0, section: 0)

        let size = sut.collectionView(cv, layout: layout, sizeForItemAt: indexPath)
        let expectedWidth = (cv.bounds.width - 40) / 3.0 // spacing = 10, totalSpacing = 40
        XCTAssertEqual(size.width, expectedWidth, accuracy: 1.0)
        XCTAssertEqual(size.height, expectedWidth, accuracy: 1.0)

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
        let items = [
            makePrefix("A", count: "1"),
            makePrefix("B", count: "2")
        ]
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(nil)
        mockVM.placeCharactersRelay.accept(items)
        pump()

        let cv = sut._test_collectionView
        XCTAssertEqual(cv.numberOfItems(inSection: 0), 2)

        let cell0 = sut.collectionView(cv, cellForItemAt: IndexPath(item: 0, section: 0))
        let cell1 = sut.collectionView(cv, cellForItemAt: IndexPath(item: 1, section: 0))
        XCTAssertTrue(cell0 is PlaceCharacterCell)
        XCTAssertTrue(cell1 is PlaceCharacterCell)
    }

    func test_forceMedium_and_restoreDetents_doesNotCrash() {
        mockVM.forceMediumRelay.accept(())
        pump()
        mockVM.restoreDetentsRelay.accept(())
        pump()
        XCTAssertTrue(true)
    }

    func test_errorToNonEmpty_togglesUICorrectly() {
        // Start in error state
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(.clientError("err"))
        pump()
        XCTAssertTrue(sut._test_collectionView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertFalse(sut._test_errorRetryView.isHidden)

        // Switch to non-empty
        mockVM.errorRelay.accept(nil)
        mockVM.placeCharactersRelay.accept([makePrefix("Z", count: "1")])
        pump()
        XCTAssertFalse(sut._test_collectionView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertTrue(sut._test_errorRetryView.isHidden)
    }

    func test_didSelectItem_uppercasesMultiCharacterPrefix() {
        let prefix = makePrefix("ab", count: "3")
        mockVM.placeCharactersRelay.accept([prefix])
        pump()

        sut.collectionView(sut._test_collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
        pump()

        XCTAssertEqual(mockVM.lastTappedCharacter, "AB")
    }

    func test_emptyLabel_hasText() {
        let text = sut._test_emptyLabel.text ?? ""
        XCTAssertFalse(text.isEmpty)
    }
}
