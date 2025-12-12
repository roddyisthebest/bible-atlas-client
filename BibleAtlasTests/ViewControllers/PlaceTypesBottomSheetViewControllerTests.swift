// PlaceTypesBottomSheetViewControllerTests.swift

import XCTest
@testable import BibleAtlas

final class PlaceTypesBottomSheetViewControllerTests: XCTestCase {
    
    var sut: PlaceTypesBottomSheetViewController!
    var mockViewModel: MockPlaceTypesBottomSheetViewModel!
    
    override func setUp() {
        super.setUp()
        mockViewModel = MockPlaceTypesBottomSheetViewModel()
        sut = PlaceTypesBottomSheetViewController(vm: mockViewModel)
        sut.loadViewIfNeeded()
    }
    
    override func tearDown() {
        sut = nil
        mockViewModel = nil
        super.tearDown()
    }
    
    // viewDidLoad에서 기본 상태 + binding이 세팅되는지
    func test_viewDidLoad_bindsAndStartsLoading() {
        // given: 초기에는 isInitialLoading = false로 둬서 숨김 상태
        XCTAssertNotNil(mockViewModel.receivedInput)
        XCTAssertTrue(sut.test_collectionView.isHidden)  // combineLatest에서 isLoading=true일 것으로 가정
    }
    
    // placeTypes가 들어오면 컬렉션뷰에 반영되는지
    func test_placeTypesUpdate_reloadCollectionView() {
        // given
        let dummyTypes: [PlaceTypeWithPlaceCount] = [
            PlaceTypeWithPlaceCount(id: 1, name: .altar, placeCount: 1),
            PlaceTypeWithPlaceCount(id: 2, name: .bodyOfWater, placeCount: 1)
        ]
        
        // when
        mockViewModel.placeTypesSubject.onNext(dummyTypes)
        // layout 강제
        sut.test_collectionView.layoutIfNeeded()
        
        // then
        XCTAssertEqual(sut.test_collectionView.numberOfItems(inSection: 0), 2)
    }
    
    // 셀 탭 → viewModel에 이벤트 전달
    func test_didSelectItem_sendsPlaceTypeToViewModel() {
        // given
        let dummyTypes: [PlaceTypeWithPlaceCount] = [
            PlaceTypeWithPlaceCount(id: 1, name: .altar, placeCount: 1),
            PlaceTypeWithPlaceCount(id: 2, name: .bodyOfWater, placeCount: 1)
        ]
        mockViewModel.placeTypesSubject.onNext(dummyTypes)
        sut.test_collectionView.layoutIfNeeded()
        
        // when
        let indexPath = IndexPath(item: 1, section: 0)
        sut.collectionView(sut.test_collectionView, didSelectItemAt: indexPath)
        
        // then
        XCTAssertEqual(mockViewModel.placeTypeTapCount, 1)
    }
    
    // 스크롤 바닥 찍으면 bottomReached$ 이벤트 전달
    func test_scrollToBottom_triggersBottomReached() {
        // given
        let dummyTypes = (0..<30).map { id in
            PlaceTypeWithPlaceCount( id: id, name: .altar, placeCount: 1)
        }
        mockViewModel.placeTypesSubject.onNext(dummyTypes)
        sut.test_collectionView.layoutIfNeeded()
        
        let scrollView = sut.test_collectionView
        
        // 스크롤을 바닥으로 세팅
        scrollView.contentSize = CGSize(width: 100, height: 2000)
        scrollView.frame = CGRect(x: 0, y: 0, width: 100, height: 500)
        scrollView.contentOffset = CGPoint(x: 0, y: 1500)
        
        // when
        sut.scrollViewDidScroll(scrollView)
        
        // then
        XCTAssertEqual(mockViewModel.bottomReachedCount, 1)
    }
    
    // 에러 상태 UI
    func test_errorState_showsErrorRetryView() {
        // given
        mockViewModel.isInitialLoadingSubject.onNext(false)
        mockViewModel.errorSubject.onNext(.clientError("error"))
        
        // when
        // combineLatest가 돌도록 한 번 더 placeTypes emit
        mockViewModel.placeTypesSubject.onNext([])
        
        // then
        XCTAssertTrue(sut.test_errorRetryView.isHidden == false)
        XCTAssertTrue(sut.test_collectionView.isHidden)
        XCTAssertTrue(sut.test_emptyLabel.isHidden)
    }
    
    // 로딩 상태 UI
    func test_loadingState_showsLoadingView() {
        // given
        mockViewModel.isInitialLoadingSubject.onNext(true)
        mockViewModel.errorSubject.onNext(nil)
        mockViewModel.placeTypesSubject.onNext([])
        
        // then
        XCTAssertTrue(sut.test_loadingView.isHidden == false)
        XCTAssertTrue(sut.test_collectionView.isHidden)
        XCTAssertTrue(sut.test_emptyLabel.isHidden)
    }
    
    // empty 상태 UI
    func test_emptyState_showsEmptyLabel() {
        // given
        mockViewModel.isInitialLoadingSubject.onNext(false)
        mockViewModel.errorSubject.onNext(nil)
        
        // when
        mockViewModel.placeTypesSubject.onNext([])
        
        // then
        XCTAssertTrue(sut.test_emptyLabel.isHidden == false)
        XCTAssertTrue(sut.test_collectionView.isHidden)
    }
    
    // isFetchingNext → footer 뷰 생성 코드 커버
    func test_footerView_showsLoadingWhenFetching() {
        // given
        mockViewModel.placeTypesSubject.onNext([
            PlaceTypeWithPlaceCount(id: 1, name: .altar, placeCount: 1),
        ])
        sut.test_collectionView.layoutIfNeeded()
        
        // when
        mockViewModel.isFetchingNextSubject.onNext(true)
        let footer = sut.collectionView(
            sut.test_collectionView,
            viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionFooter,
            at: IndexPath(item: 0, section: 0)
        )
        
        // then (단순히 footer를 잘 만들어줬는지만 체크)
        XCTAssertNotNil(footer)
    }
}
