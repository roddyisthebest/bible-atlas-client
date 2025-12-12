//
//  BibleVerseDetailBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//

import XCTest
import RxSwift
@testable import BibleAtlas

final class BibleVerseDetailBottomSheetViewControllerTests: XCTestCase {

    private var sut: BibleVerseDetailBottomSheetViewController!
    private var mockVM: MockBibleVerseDetailBottomSheetViewModel!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        mockVM = MockBibleVerseDetailBottomSheetViewModel()
        sut = BibleVerseDetailBottomSheetViewController(
            bibleVerseDetailBottomSheetViewModel: mockVM
        )

        // viewDidLoad + bindViewModel + viewLoaded$.accept()
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

    // MARK: - Title 바인딩

    func test_titleBinding_updatesHeaderLabel() {
        // given
        mockVM.titleRelay.accept("출애굽기 1:1")

        // when
        pump()

        // then
        XCTAssertEqual(sut._test_headerLabel.text, "출애굽기 1:1")
    }

    // MARK: - bibleVerse + placeName 하이라이트 바인딩

    func test_bibleVerseAndPlaceNameBinding_setsAttributedTextWithVerseString() {
        // given
        let verse = "Egyptian is living in Egypt."
        mockVM.bibleVerseRelay.accept(verse)
        mockVM.placeNameRelay.accept("Egypt")   // 부분 매치 모드

        // when
        pump()

        // then: underline/색상 같은 attribute는 신경 안 쓰고, string만 확인
        XCTAssertEqual(sut._test_textView.attributedText?.string, verse)
    }

    func test_bibleVerseWithoutPlaceName_setsPlainAttributedText() {
        // given
        let verse = "In the beginning God created the heavens and the earth."
        mockVM.bibleVerseRelay.accept(verse)
        mockVM.placeNameRelay.accept(nil)

        // when
        pump()

        // then
        XCTAssertEqual(sut._test_textView.attributedText?.string, verse)
    }

    // MARK: - Loading / Error 상태 UI 토글

    func test_loadingState_showsLoadingAndHidesTextAndError() {
        // given
        mockVM.isLoadingRelay.accept(true)
        mockVM.errorRelay.accept(nil)

        // when
        pump()

        // then
        XCTAssertTrue(sut._test_textView.isHidden, "로딩 중에는 문단 숨김")
        XCTAssertTrue(sut._test_errorRetryView.isHidden, "로딩 중에는 에러뷰 숨김")
        XCTAssertFalse(sut._test_loadingView.isHidden, "로딩뷰는 보여야 함(기본값 false)")
    }

    func test_errorState_showsErrorRetryAndHidesTextAndLoading() {
        // given
        mockVM.isLoadingRelay.accept(false)
        mockVM.errorRelay.accept(.clientError("테스트 에러"))

        // when
        pump()

        // then
        XCTAssertTrue(sut._test_textView.isHidden, "에러 시 텍스트 숨김")
        XCTAssertFalse(sut._test_errorRetryView.isHidden, "에러 시 에러뷰 표시")
        XCTAssertTrue(sut._test_loadingView.isHidden, "에러 시 로딩뷰 숨김")
    }

    func test_loadedState_showsTextAndHidesLoadingAndError() {
        // given
        mockVM.isLoadingRelay.accept(false)
        mockVM.errorRelay.accept(nil)
        mockVM.bibleVerseRelay.accept("some verse")

        // when
        pump()

        // then
        XCTAssertFalse(sut._test_textView.isHidden, "정상 로드 시 텍스트 표시")
        XCTAssertTrue(sut._test_errorRetryView.isHidden, "정상 로드 시 에러뷰 숨김")
        // loadingView는 stop만 호출되고 isHidden은 건드리지 않지만,
        // 에러도 아니고 로딩도 아니니 true/false 모두 크게 상관 없어서 강한 단정은 안함
    }

    // MARK: - Button / Retry 이벤트 전달

    func test_closeButtonTap_triggersViewModelClose() {
        // when
        sut._test_closeButton.sendActions(for: .touchUpInside)
        pump()

        // then
        XCTAssertEqual(mockVM.closeButtonTapCount, 1)
    }

    func test_errorRetryViewRefetchTap_triggersViewModelRefetch() {
        // when
        sut._test_errorRetryView.refetchTapped$.accept(())
        pump()

        // then
        XCTAssertEqual(mockVM.refetchButtonTapCount, 1)
    }
}
