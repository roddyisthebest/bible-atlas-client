//
//  PlacesByTypeBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
import RxSwift
@testable import BibleAtlas

final class PlacesByTypeBottomSheetViewControllerTests: XCTestCase {

    private var sut: PlacesByTypeBottomSheetViewController!
    private var mockVM: MockPlacesByTypeBottomSheetViewModel!
    private var disposeBag: DisposeBag!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        mockVM = MockPlacesByTypeBottomSheetViewModel()
        sut = PlacesByTypeBottomSheetViewController(vm: mockVM)

        // viewDidLoad + bindViewModel + viewLoaded$ emit
        _ = sut.view
        pump()
    }

    override func tearDown() {
        sut = nil
        mockVM = nil
        disposeBag = nil
        super.tearDown()
    }

    /// 메인 런루프 한 번 돌려주기
    private func pump(_ sec: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(sec))
    }

    /// 테스트용 dummy Place (필드명은 프로젝트 상황에 맞게 조정)
    private func makeDummyPlace(id: String = "1", name: String = "Test Place") -> Place {
        return Place(
            id: id,
            name: name,
            anotherNames: nil,
            anotherKoreanNames: nil,
            koreanName: "테스트 장소",
            isModern: false,
            description: "desc",
            koreanDescription: "한글 desc",
            stereo: .parent,
            verse: nil,
            likeCount: 0,
            unknownPlacePossibility: nil,
            types: [],
            childRelations: nil,
            parentRelations: nil,
            isLiked: nil,
            isSaved: nil,
            memo: nil,
            imageTitle: nil,
            longitude: nil,
            latitude: nil
        )
    }

    // MARK: - viewDidLoad / 기본 바인딩

    func test_viewDidLoad_triggersViewLoadedOnViewModel() {
        // setUp 시점에 이미 viewLoaded$ emit
        XCTAssertEqual(mockVM.viewLoadedCallCount, 1)
    }

    func test_headerTitle_updatesWhenTypeNameEmits() {
        // given
        let typeName: PlaceTypeName = .altar   // 실제 enum 케이스 맞게 사용

        // when
        mockVM.typeNameSubject.onNext(typeName)
        pump()

        // then
        let expectedTitle = L10n.isEnglish ? typeName.titleEn : typeName.titleKo
        XCTAssertEqual(sut._test_headerLabel.text, expectedTitle)
    }

    // MARK: - places 바인딩 → tableView

    func test_placesUpdate_reloadTableViewWithCorrectNumberOfRows() {
        // given
        let place1 = makeDummyPlace(id: "1", name: "Place 1")
        let place2 = makeDummyPlace(id: "2", name: "Place 2")

        // when
        mockVM.placesSubject.onNext([place1, place2])
        mockVM.isInitialLoadingSubject.onNext(false)
        mockVM.errorSubject.onNext(nil)
        pump()

        // then
        let rows = sut._test_tableView.numberOfRows(inSection: 0)
        XCTAssertEqual(rows, 2)
    }

    // MARK: - 셀 선택 → ViewModel로 placeId 전달

    func test_didSelectRow_sendsPlaceIdToViewModel() {
        // given
        let place = makeDummyPlace(id: "place-123", name: "Chosen")
        mockVM.placesSubject.onNext([place])
        mockVM.isInitialLoadingSubject.onNext(false)
        mockVM.errorSubject.onNext(nil)
        pump()

        let tableView = sut._test_tableView
        let indexPath = IndexPath(row: 0, section: 0)

        // when
        sut.tableView(tableView, didSelectRowAt: indexPath)
        pump()

        // then
        XCTAssertEqual(mockVM.placeCellTappedIds.count, 1)
        XCTAssertEqual(mockVM.placeCellTappedIds.first, "place-123")
    }

    // MARK: - close 버튼 → ViewModel close 이벤트 전달

    func test_closeButtonTap_triggersViewModelClose() {
        // given
        _ = sut.view
        pump()

        // when
        sut._test_closeButton.sendActions(for: .touchUpInside)
        pump()

        // then
        XCTAssertEqual(mockVM.closeButtonTapCount, 1)
    }

    // MARK: - 상태 바인딩: isInitialLoading / error / places

    func test_state_isLoading_showsLoading_hidesTableEmptyError() {
        // given
        mockVM.placesSubject.onNext([])
        mockVM.errorSubject.onNext(nil)

        // when: 마지막에 isInitialLoading = true 쏴서 그 상태로 combineLatest 최종 세팅
        mockVM.isInitialLoadingSubject.onNext(true)
        pump()

        // then
        XCTAssertFalse(sut._test_loadingView.isHidden)
        XCTAssertTrue(sut._test_tableView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertTrue(sut._test_errorRetryView.isHidden)
    }

    func test_state_error_showsErrorRetryView_hidesTableAndEmptyAndLoading() {
        // given
        mockVM.isInitialLoadingSubject.onNext(false)
        mockVM.placesSubject.onNext([])

        // when
        mockVM.errorSubject.onNext(.clientError("에러"))
        pump()

        // then
        XCTAssertTrue(sut._test_loadingView.isHidden)
        XCTAssertTrue(sut._test_tableView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertFalse(sut._test_errorRetryView.isHidden)
    }

    func test_state_emptyAndNotLoading_showsEmptyLabel_hidesTable() {
        // given
        mockVM.isInitialLoadingSubject.onNext(false)
        mockVM.errorSubject.onNext(nil)

        // when
        mockVM.placesSubject.onNext([])
        pump()

        // then
        XCTAssertTrue(sut._test_loadingView.isHidden)
        XCTAssertFalse(sut._test_emptyLabel.isHidden)
        XCTAssertTrue(sut._test_tableView.isHidden)
        XCTAssertTrue(sut._test_errorRetryView.isHidden)
    }

    func test_state_hasPlaces_showsTable_hidesEmptyLabel() {
        // given
        let place = makeDummyPlace(id: "1", name: "Non empty")
        mockVM.isInitialLoadingSubject.onNext(false)
        mockVM.errorSubject.onNext(nil)

        // when
        mockVM.placesSubject.onNext([place])
        pump()

        // then
        XCTAssertTrue(sut._test_loadingView.isHidden)
        XCTAssertTrue(sut._test_errorRetryView.isHidden)
        XCTAssertTrue(sut._test_emptyLabel.isHidden)
        XCTAssertFalse(sut._test_tableView.isHidden)
    }

    // MARK: - isFetchingNext 바인딩: footer 로딩뷰 start/stop (크래시 없이 동작만 확인)

    func test_isFetchingNext_togglesFooterLoadingView_withoutCrash() {
        // when
        mockVM.isFetchingNextSubject.onNext(true)
        pump()
        mockVM.isFetchingNextSubject.onNext(false)
        pump()

        // then: 특별한 크래시 없이 여기까지 오면 OK
        XCTAssertNotNil(sut._test_footerLoadingView)
    }

    // MARK: - scrollViewDidScroll → bottomReached debounce + isBottomEmitted 동작

    func test_scrollToBottom_triggersBottomReachedOnlyOnce_untilReset() {
        let tableView = sut._test_tableView

        // 스크롤 영역 셋업 (스크롤 가능하도록)
        tableView.contentSize = CGSize(width: 100, height: 1000)
        tableView.frame = CGRect(x: 0, y: 0, width: 100, height: 200)

        // 1) 맨 아래까지 스크롤 → 1회 호출
        tableView.contentOffset.y = 800
        sut.scrollViewDidScroll(tableView)
        pump(0.2)
        XCTAssertEqual(mockVM.bottomReachedCallCount, 1)

        // 2) 같은 위치에서 다시 스크롤 이벤트 → isBottomEmitted 때문에 더 안 올라가야 함
        sut.scrollViewDidScroll(tableView)
        pump(0.2)
        XCTAssertEqual(mockVM.bottomReachedCallCount, 1)

        // 3) 에러 발생 시 VC에서 isBottomEmitted = false 로 리셋
        mockVM.errorSubject.onNext(.clientError("에러"))
        pump(0.2)

        // 다시 맨 아래 스크롤 → 한 번 더 호출되어야 함 (총 2회)
        sut.scrollViewDidScroll(tableView)
        pump(0.2)
        XCTAssertEqual(mockVM.bottomReachedCallCount, 2)
    }
}
