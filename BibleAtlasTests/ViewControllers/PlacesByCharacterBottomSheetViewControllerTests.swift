//
//  PlacesByCharacterBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
import RxSwift
@testable import BibleAtlas

final class PlacesByCharacterBottomSheetViewControllerTests: XCTestCase {

    private var sut: PlacesByCharacterBottomSheetViewController!
    private var mockVM: MockPlacesByCharacterBottomSheetViewModel!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        mockVM = MockPlacesByCharacterBottomSheetViewModel()
        sut = PlacesByCharacterBottomSheetViewController(vm: mockVM)

        // viewDidLoad + bindViewModel + viewLoaded$.accept
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

    // MARK: - Life cycle

    func test_viewDidLoad_triggersViewLoadedOnViewModel() {
        XCTAssertEqual(mockVM.viewLoadedCallCount, 1)
    }

    // MARK: - header character 바인딩

    func test_characterBinding_updatesHeaderLabel() {
        // given
        mockVM.characterRelay.accept("B")

        // when
        pump()

        // then
        XCTAssertEqual(
            sut._test_headerLabel.text,
            L10n.PlacesByCharacter.title("B")
        )
    }

    // MARK: - places 바인딩 -> tableView rows

    func test_placesBinding_updatesTableViewRows() {
        // given
        let place1 = Place.mock(id: "1", name: "Alpha")
        let place2 = Place.mock(id: "2", name: "Beta")

        mockVM.placesRelay.accept([place1, place2])

        // when
        pump()

        // then
        XCTAssertEqual(sut._test_tableView.numberOfRows(inSection: 0), 2)
    }

    // MARK: - Loading / Error / Empty 상태 UI 토글

    func test_loadingState_showsLoadingAndHidesTableEmptyError() {
        // given
        mockVM.isInitialLoadingRelay.accept(true)
        mockVM.errorRelay.accept(nil)
        mockVM.placesRelay.accept([])
        pump()

        // then
        XCTAssertFalse(sut._test_loadingView.isHidden, "로딩 중에는 로딩뷰가 보여야 함")
        XCTAssertTrue(sut._test_tableView.isHidden, "로딩 중에는 테이블 숨김")
        XCTAssertTrue(sut._test_emptyLabel.isHidden, "로딩 중에는 emptyLabel 숨김")
        XCTAssertTrue(sut._test_errorRetryView.isHidden, "로딩 중에는 에러뷰 숨김")
    }

    func test_errorState_showsErrorRetryViewAndHidesOthers() {
        // given
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(.clientError("테스트 에러"))
        mockVM.placesRelay.accept([])
        pump()

        // then
        XCTAssertFalse(sut._test_errorRetryView.isHidden, "에러 발생 시 에러뷰 표시")
        XCTAssertTrue(sut._test_loadingView.isHidden, "에러 시 로딩뷰 숨김")
        XCTAssertTrue(sut._test_tableView.isHidden, "에러 시 테이블 숨김")
        XCTAssertTrue(sut._test_emptyLabel.isHidden, "에러 시 emptyLabel 숨김")
    }

    func test_emptyState_showsEmptyLabelAndHidesTable() {
        // given: 로딩 X, 에러 X, places 비어있음
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(nil)
        mockVM.placesRelay.accept([])
        pump()

        // then
        XCTAssertFalse(sut._test_emptyLabel.isHidden, "데이터 없으면 emptyLabel 보여야 함")
        XCTAssertTrue(sut._test_tableView.isHidden, "데이터 없으면 테이블 숨김")
    }

    func test_nonEmptyState_showsTableAndHidesEmpty() {
        // given
        let place = Place.mock(id: "1", name: "Alpha")
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(nil)
        mockVM.placesRelay.accept([place])
        pump()

        // then
        XCTAssertTrue(sut._test_emptyLabel.isHidden, "데이터 있으면 emptyLabel 숨김")
        XCTAssertFalse(sut._test_tableView.isHidden, "데이터 있으면 테이블 표시")
        XCTAssertEqual(sut._test_tableView.numberOfRows(inSection: 0), 1)
    }

    // MARK: - isFetchingNext -> footerLoadingView (크래시 안 나는 정도로만 확인)

    func test_isFetchingNext_togglesFooterLoadingView_withoutAffectingTableVisibility() {
        // given: 데이터 1개
        let place = Place.mock(id: "1", name: "Alpha")
        mockVM.isInitialLoadingRelay.accept(false)
        mockVM.errorRelay.accept(nil)
        mockVM.placesRelay.accept([place])
        pump()

        // when: 추가 로딩 시작
        mockVM.isFetchingNextRelay.accept(true)
        pump()

        // then: 테이블은 계속 보여야 함 (하단 로딩만 도는 상황)
        XCTAssertFalse(sut._test_tableView.isHidden)

        // when: 추가 로딩 종료
        mockVM.isFetchingNextRelay.accept(false)
        pump()

        XCTAssertFalse(sut._test_tableView.isHidden)
    }

    // MARK: - Button / 셀 / 스크롤 이벤트 → VM 인풋 전달

    func test_closeButtonTap_triggersViewModelClose() {
        sut._test_closeButton.sendActions(for: .touchUpInside)
        pump()

        XCTAssertEqual(mockVM.closeButtonTapCount, 1)
    }

    func test_didSelectRow_sendsPlaceIdToViewModel() {
        // given
        let place1 = Place.mock(id: "1", name: "Alpha")
        let place2 = Place.mock(id: "2", name: "Beta")
        mockVM.placesRelay.accept([place1, place2])
        pump()

        let indexPath = IndexPath(row: 1, section: 0)

        // when
        sut.tableView(sut._test_tableView, didSelectRowAt: indexPath)
        pump()

        // then
        XCTAssertEqual(mockVM.placeCellTappedIds, ["2"])
    }

    func test_scrollToBottom_emitsBottomReachedToViewModel() {
        // given: 테이블 프레임/컨텐츠 설정
        sut._test_tableView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        sut._test_tableView.contentSize = CGSize(width: 100, height: 300)

        // 스크롤을 맨 아래로
        sut._test_tableView.contentOffset = CGPoint(x: 0, y: 200)

        // when
        sut.scrollViewDidScroll(sut._test_tableView)
        pump(0.2)

        // then
        XCTAssertEqual(mockVM.bottomReachedCallCount, 1)
    }

    func test_errorRetryViewRefetchTap_triggersViewModelRefetch() {
        sut._test_errorRetryView.refetchTapped$.accept(())
        pump()

        XCTAssertEqual(mockVM.refetchButtonTapCount, 1)
    }
}



