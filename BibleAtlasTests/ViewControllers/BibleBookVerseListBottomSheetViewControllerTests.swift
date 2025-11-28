//
//  BibleBookVerseListBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 10/8/25.
//

import XCTest
@testable import BibleAtlas

final class BibleBookVerseListBottomSheetViewControllerTests: XCTestCase {

    var vm: MockBibleBookVerseListBottomSheetViewModel!
    var vc: BibleBookVerseListBottomSheetViewController!
    var window: UIWindow!
    var host: UIViewController!

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)

        vm = MockBibleBookVerseListBottomSheetViewModel()
        vc = BibleBookVerseListBottomSheetViewController(vm: vm)

        host = UIViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()

        // 시트가 아니어도 괜찮지만, 실제 표시되게 해 레이아웃 안정
        host.present(vc, animated: false)
        pump()
    }

    override func tearDown() {
        host?.dismiss(animated: false)
        window = nil
        host = nil
        vc = nil
        vm = nil
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }

    // MARK: - Tests

    func test_viewLoaded_bindsAndShowsLoading_thenHides() {
        // given
        vm.loadingRelay.accept(true)
        pump(0.1)

        // then (loading visible)
        XCTAssertTrue(vc._test_isLoadingVisible)
        XCTAssertTrue(vc._test_isBodyHidden)

        // when -> finish loading
        vm.loadingRelay.accept(false)
        vm.errorRelay.accept(nil)
        pump()

        // then
        XCTAssertFalse(vc._test_isLoadingVisible)
        XCTAssertFalse(vc._test_isBodyHidden)
    }

    func test_place_emit_updatesHeaderTitle() {
        // given
        let place = Place(id: "p1", name: "Jerusalem", koreanName: "예루살렘", isModern: false,
                          description: "", koreanDescription: "", stereo: .parent,
                          verse: "", likeCount: 0, types: [])
        vm.placeRelay.accept(place)
        pump(0.2)

        // then
        let title = vc._test_headerText ?? ""
        XCTAssertTrue(title.contains("Jerusalem") || title.contains("예루살렘"))
    }

    func test_bibles_emit_buildsSelectMenu() {
        // given
        vm.biblesRelay.accept([
            Bible(bookName: .Gen, verses: []),
            Bible(bookName: .Exod, verses: [])
        ])
        pump()

        // then
        XCTAssertEqual(vc._test_menuItemTitles.count, 2)
        XCTAssertTrue(vc._test_selectTitleText == nil || vc._test_selectTitleText == L10n.VerseListSheet.selectBookPrompt)
    }

    func test_selectedBookAndVerses_updatesCollection_andHidesEmptyLabel() {
        // given
        vm.selectedRelay.accept((.Gen, [Verse.def("Gen 1:1"), Verse.def("Gen 1:2")]))
        pump()

        XCTAssertEqual(vc._test_numberOfVerses, 2)
        XCTAssertFalse(vc._test_isEmptyVisible)
    }

    func test_selectedBookNone_showsEmptyLabel() {
        vm.selectedRelay.accept((nil, []))
        pump()
        XCTAssertTrue(vc._test_isEmptyVisible)
        XCTAssertEqual(vc._test_numberOfVerses, 0)
    }

    func test_error_showsErrorView_andHidesBody() {
        vm.errorRelay.accept(.clientError("oops"))
        vm.loadingRelay.accept(false)
        pump()

        XCTAssertTrue(vc._test_isErrorVisible)
        XCTAssertTrue(vc._test_isBodyHidden)
    }

    func test_selectBook_forwardsToViewModel() {
        vc._test_selectBook(.Isa)
        pump()
        XCTAssertEqual(vm.lastChangedBook, .Isa)
    }

    func test_tapVerse_forwardsToViewModel() {
        let verse = Verse.def("Gen 1:1")
        vc._test_emitVerseTap(verse)
        pump()
        // then
        if case let .def(text1) = verse, case let .def(text2) = vm.lastTappedVerse {
            XCTAssertEqual(text1, text2)
        } else {
            XCTFail("Verse forwarding failed")
        }
    }

    func test_tapClose_forwardsToViewModel() {
        vc._test_tapClose()
        pump()
        XCTAssertEqual(vm.closeTappedCount, 1)
    }
}




