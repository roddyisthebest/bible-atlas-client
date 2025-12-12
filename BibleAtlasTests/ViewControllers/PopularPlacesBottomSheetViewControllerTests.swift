//
//  PopularPlacesBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
@testable import BibleAtlas

final class PopularPlacesBottomSheetViewControllerTests: XCTestCase {

    private var sut: PopularPlacesBottomSheetViewController!
    private var mockVM: MockPopularPlacesBottomSheetViewModel!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockVM = MockPopularPlacesBottomSheetViewModel()
        sut = PopularPlacesBottomSheetViewController(popularPlacesBottomSheetViewModel: mockVM)

        // viewDidLoad 호출 + bindViewModel + viewLoaded$.accept(())
        _ = sut.view
        pump()
    }

    override func tearDown() {
        sut = nil
        mockVM = nil
        super.tearDown()
    }

    /// Rx / 레이아웃 비동기 반영용
    private func pump(_ seconds: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    // MARK: - 기본 바인딩 / life cycle

    func test_viewDidLoad_triggersViewLoadedOnViewModel() {
        // setUp 시점에 이미 viewDidLoad + viewLoaded$.accept(()) 호출됨
        XCTAssertEqual(mockVM.viewLoadedCallCount, 1)
    }

    // MARK: - 상태 바인딩: 로딩 / 에러 / 빈 목록

    func test_initialLoading_showsLoadingAndHidesTableAndEmptyAndError() {
        // given
        mockVM.isInitialLoadingSubject.onNext(true)
        mockVM.errorSubject.onNext(nil)
        mockVM.placesSubject.onNext([])
        pump()

        // then
        XCTAssertFalse(sut._test_loadingView.isHidden, "로딩 중에는 loadingView가 보여야 함")
        XCTAssertTrue(sut._test_tableView.isHidden, "로딩 중엔 tableView 숨김")
        XCTAssertTrue(sut._test_emptyLabel.isHidden, "로딩 중엔 emptyLabel 숨김")
        XCTAssertTrue(sut._test_errorRetryView.isHidden, "로딩 중엔 errorView 숨김")
    }

    func test_error_showsErrorRetryView_andHidesTableAndEmptyAndLoading() {
        // given: 에러 발생
        mockVM.isInitialLoadingSubject.onNext(false)
        mockVM.placesSubject.onNext([])
        mockVM.errorSubject.onNext(.clientError("테스트 에러"))
        pump()

        // then
        XCTAssertFalse(sut._test_errorRetryView.isHidden, "에러 시 errorRetryView 보여야 함")
        XCTAssertTrue(sut._test_tableView.isHidden, "에러 시 tableView 숨김")
        XCTAssertTrue(sut._test_emptyLabel.isHidden, "에러 시 emptyLabel 숨김")
        XCTAssertTrue(sut._test_loadingView.isHidden, "에러 시 loadingView 숨김")
    }

    func test_emptyPlaces_showsEmptyLabel_andHidesTable() {
        // given: 로딩 끝 + 에러 없음 + places 비어있음
        mockVM.isInitialLoadingSubject.onNext(false)
        mockVM.errorSubject.onNext(nil)
        mockVM.placesSubject.onNext([])
        pump()

        // then
        XCTAssertFalse(sut._test_emptyLabel.isHidden, "목록이 비어있으면 emptyLabel 보여야 함")
        XCTAssertTrue(sut._test_tableView.isHidden, "목록이 비어있으면 tableView 숨김")
        XCTAssertTrue(sut._test_loadingView.isHidden, "로딩 종료 상태")
        XCTAssertTrue(sut._test_errorRetryView.isHidden, "에러 없음")
    }

    // ⚠️ places가 비어있지 않은 케이스에서의 tableView row 갯수 검증은
    // Place 생성 방식(프로젝트의 Place 초기화 방식)에 따라 달라서 여기서는 생략했어.
    // 필요하면 dummy Place 팩토리 만들어서 mockVM.placesSubject.onNext([dummy]) 하고
    // sut._test_tableView.numberOfRows(inSection: 0)을 검증하면 됨.

    // MARK: - bottomReached → ViewModel에 전달

    func test_scrollToBottom_triggersBottomReachedOnViewModel() {
        // given
        let tableView = sut._test_tableView

        // 스크롤 가능한 사이즈 세팅
        tableView.contentSize = CGSize(width: 100, height: 1000)
        tableView.frame = CGRect(x: 0, y: 0, width: 100, height: 200)

        // when: 바닥까지 스크롤했다고 가정
        tableView.contentOffset.y = 800
        pump()

        // then
        XCTAssertEqual(mockVM.bottomReachedCallCount, 1)
    }

    // MARK: - close 버튼 → ViewModel close 이벤트 전달

    func test_closeButtonTap_triggersViewModelClose() {
        // given
        let closeButton = sut._test_closeButton

        // when
        closeButton.sendActions(for: .touchUpInside)
        pump()

        // then
        XCTAssertEqual(mockVM.closeButtonTapCount, 1)
    }

    // MARK: - 에러 화면의 refetch 버튼 → viewModel refetch 이벤트 전달 (선택)

    func test_whenErrorRetryViewRefetchTapped_triggersViewModelRefetch() {
        // 이 부분은 ErrorRetryView 안에 refetchTapped$ 같은 것이 있다고 가정.
        // 이미 다른 VC 테스트에서 쓰던 패턴대로라면, 테스트용 익스텐션에서
        // refetchTapped$를 바로 쏠 수 있게 열어두면 됨.

        // given: 에러 상태로 전환
        mockVM.errorSubject.onNext(.clientError("에러"))
        pump()

        // when: refetch 버튼 탭 시그널 직접 쏘기
        sut._test_errorRetryView.refetchTapped$.accept(())
        pump()

        // then
        XCTAssertEqual(mockVM.refetchButtonTapCount, 1)
    }

    // MARK: - 셀 선택 → ViewModel로 placeId 전달 (선택)

    // 이 테스트는 실제 Place 인스턴스가 필요해서,
    // 프로젝트에 Place 더미 팩토리 있으면 그에 맞게 구현해서 사용하면 됨.
    // 아래는 skeleton 예시:

    
    func test_didSelectRow_sendsPlaceIdToViewModel() {
        // given
        let dummyPlace = Place.mock(id:"place-1")
        mockVM.placesSubject.onNext([dummyPlace])
        pump()

        let tableView = sut._test_tableView
        let indexPath = IndexPath(row: 0, section: 0)

        // when
        sut.tableView(tableView, didSelectRowAt: indexPath)
        pump()

        // then
        XCTAssertEqual(mockVM.selectedPlaceIds, ["place-1"])
    }
}
