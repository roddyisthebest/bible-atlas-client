//
//  BibleBookVerseListBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 10/8/25.
//

import XCTest
import RxRelay
import RxTest
import RxBlocking
import RxSwift

@testable import BibleAtlas


final class BibleBookVerseListBottomSheetViewModelTests: XCTestCase {

    var navigator: MockBottomSheetNavigator!
    var placeUsecase: MockPlaceusecase!

    private var placeId:String = "testId"
    private let bibleBook:BibleBook = .Etc
    
    let place = Place(id: "testId", name: "place", koreanName: "플레이스", isModern: false, description: "", koreanDescription: "", stereo: .child, likeCount: 5, types: [])
    
    var disposeBag:DisposeBag!

    
    override func setUp()  {
        super.setUp()
        
        navigator = MockBottomSheetNavigator();
        placeUsecase = MockPlaceusecase();
        
        disposeBag = DisposeBag();
    }
    
    
    func test_isLoading_togglesTrueThenFalse_when_viewLoaded(){
        
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: bibleBook, placeUsecase: placeUsecase)
        
        let viewLoaded$ = PublishRelay<Void>()
        let output = vm.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: .empty(), closeButtonTapped$: .empty(), bibleBookChanged$: .empty(), verseCellTapped$: .empty()))
        
        
        var loadingHistories:[Bool] = []
        let exp = expectation(description: "loading toggle")
        exp.expectedFulfillmentCount = 2
        output.isLoading$.skip(1).take(2).subscribe(onNext:{
            isLoading in
            loadingHistories.append(isLoading)
            exp.fulfill()
        }).disposed(by: disposeBag)
        
        
        viewLoaded$.accept(())
        wait(for: [exp])
        
        XCTAssertEqual(loadingHistories, [true, false])
        
        
    }

    func test_placeAndBibles_emit_when_viewLoaded_success(){
        
        placeUsecase.detailResultToReturn = .success(place)
        placeUsecase.parsedBible = [
            Bible(bookName: .Acts, verses: []),
            Bible(bookName: .Chr1, verses: [])
        ]
        
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: bibleBook, placeUsecase: placeUsecase)
        
        let viewLoaded$ = PublishRelay<Void>()
        let output = vm.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: .empty(), closeButtonTapped$: .empty(), bibleBookChanged$: .empty(), verseCellTapped$: .empty()))
        
        var gotPlace:Place?
        let placeExp = expectation(description: "place set")
        output.place$.skip(1).take(1).subscribe(onNext:{
            place in
            gotPlace = place;
            placeExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        var gotBibles:[Bible]?
        let biblesExp = expectation(description: "bibles set")
        output.bibles$.skip(1).take(1).subscribe(onNext:{
            bibles in
            gotBibles = bibles;
            biblesExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        wait(for:[placeExp, biblesExp])
        XCTAssertEqual(gotPlace?.id, place.id)
        XCTAssertEqual(gotBibles?.count, 2)
        
    }

    func test_selectedBookAndVerses_updates_when_initHasSelectedBook_and_loadSucceeds(){
        placeUsecase.detailResultToReturn = .success(place)
        
        placeUsecase.parsedBible = [
            Bible(bookName: .Acts, verses: ["one", "two", "three"]),
            Bible(bookName: .Chr1, verses: ["one", "two", "three"])
        ]
        
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: .Acts, placeUsecase: placeUsecase)
        
        let viewLoaded$ = PublishRelay<Void>()
        let output = vm.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: .empty(), closeButtonTapped$: .empty(), bibleBookChanged$: .empty(), verseCellTapped$: .empty()))
        
        
        var gotSelectedBookAndVerses: (BibleBook?,[Verse])?
        let exp = expectation(description: "selectedBookAndVerses set")
        
        output.selectedBibleBookAndVerses$.skip(1).take(1).subscribe(onNext:{
            selectedBibleBookAndVerses in
            gotSelectedBookAndVerses = selectedBibleBookAndVerses;
            exp.fulfill()
        }).disposed(by: disposeBag)
        
        
        viewLoaded$.accept(())
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(gotSelectedBookAndVerses?.0, .Acts)
        XCTAssertEqual(gotSelectedBookAndVerses?.1.count, 3)
        
        
    }

    func test_selectedBookAndVerses_notUpdated_when_initHasNoSelectedBook_evenAfterLoad(){
        
        
        placeUsecase.detailResultToReturn = .success(place)
        
        placeUsecase.parsedBible = [
            Bible(bookName: .Acts, verses: ["one", "two", "three"]),
            Bible(bookName: .Chr1, verses: ["one", "two", "three"])
        ]
        
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: nil, placeUsecase: placeUsecase)
        
        let viewLoaded$ = PublishRelay<Void>()
        let output = vm.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: .empty(), closeButtonTapped$: .empty(), bibleBookChanged$: .empty(), verseCellTapped$: .empty()))
        
        
        var gotSelectedBookAndVerses: (BibleBook?,[Verse])?
        let exp = expectation(description: "selectedBookAndVerses set")
        
        exp.isInverted = true
        
        output.selectedBibleBookAndVerses$.skip(1).take(1).subscribe(onNext:{
            selectedBibleBookAndVerses in
            gotSelectedBookAndVerses = selectedBibleBookAndVerses;
            exp.fulfill()
        }).disposed(by: disposeBag)
        
        
        viewLoaded$.accept(())
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(gotSelectedBookAndVerses?.0, nil)
    }

    func test_selectedBookAndVerses_updates_when_bibleBookChanged(){
        
        placeUsecase.detailResultToReturn = .success(place)
        
        placeUsecase.parsedBible = [
            Bible(bookName: .Acts, verses: ["one", "two", "three"]),
            Bible(bookName: .Chr1, verses: ["one", "two", "three"])
        ]
        
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: nil, placeUsecase: placeUsecase)
        

        let bibleBookChanged$ = PublishRelay<BibleBook>()

        let output = vm.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: .empty(), refetchButtonTapped$: .empty(), closeButtonTapped$: .empty(), bibleBookChanged$: bibleBookChanged$.asObservable(), verseCellTapped$: .empty()))
        
        
        var gotSelectedBookAndVerses: (BibleBook?,[Verse])?
        let exp = expectation(description: "selectedBookAndVerses set")
        

        
        output.selectedBibleBookAndVerses$.skip(1).take(1).subscribe(onNext:{
            selectedBibleBookAndVerses in
            gotSelectedBookAndVerses = selectedBibleBookAndVerses
            exp.fulfill()
        }).disposed(by: disposeBag)
        
        
        bibleBookChanged$.accept(.Chr1)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(gotSelectedBookAndVerses?.0, .Chr1)
        
    }

    func test_error_emits_when_getPlaceFails_and_isLoadingEnds(){
        
        let error: NetworkError = .clientError("test-error")
        placeUsecase.detailResultToReturn = .failure(error)
        
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: nil, placeUsecase: placeUsecase)
        
        let viewLoaded$ = PublishRelay<Void>()
        let output = vm.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: .empty(), closeButtonTapped$: .empty(), bibleBookChanged$: .empty(), verseCellTapped$: .empty()))
        
        var gotError:NetworkError?
        let errorExp = expectation(description: "error set")
        
        output.error$.skip(2).take(1).subscribe(onNext:{
            error in
            gotError = error;
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        
        wait(for: [errorExp], timeout: 1.0)
        
        XCTAssertEqual(gotError, error)
        
    }

    func test_error_clearsAndOutputsReload_when_refetch_afterFailure(){
        let error: NetworkError = .clientError("test-error")
        placeUsecase.detailResultToReturn = .failure(error)
        
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: nil, placeUsecase: placeUsecase)
        
        let viewLoaded$ = PublishRelay<Void>()
        let refetchButtonTapped$ = PublishRelay<Void>()

        let output = vm.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: refetchButtonTapped$.asObservable(), closeButtonTapped$: .empty(), bibleBookChanged$: .empty(), verseCellTapped$: .empty()))
        
        var errorHistories:[NetworkError?] = []
        let errorsExp = expectation(description: "errors set")
        
        output.error$.skip(2).take(1).subscribe(onNext:{
            error in
            errorHistories.append(error)
            errorsExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        wait(for: [errorsExp], timeout: 1.0)
        
        let errorsExp2 = expectation(description: "errors reset")
        
        output.error$.skip(1).take(1).subscribe(onNext:{
            error in
            errorHistories.append(error)
            errorsExp2.fulfill()
        }).disposed(by: disposeBag)
        
        
        refetchButtonTapped$.accept(())
        wait(for:[errorsExp2], timeout: 1.0)
        
        XCTAssertEqual(errorHistories.count, 2)
        
    }

    func test_error_emitsClientError_when_parseBibleReturnsNil_and_selectionNotUpdated(){
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: nil, placeUsecase: nil)
        
        let viewLoaded$ = PublishRelay<Void>()

        
        let output = vm.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$:.empty(), closeButtonTapped$: .empty(), bibleBookChanged$: .empty(), verseCellTapped$: .empty()))
        
        var gotError: NetworkError?
        let errorExp = expectation(description: "error set")
        output.error$.skip(2).take(1).subscribe(onNext:{
            error in
            gotError = error
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        viewLoaded$.accept(())
        wait(for: [errorExp], timeout: 1.0)

        XCTAssertEqual(gotError, .clientError(L10n.FatalError.reExec))
        
        
    }

    func test_navigator_dismiss_called_when_closeButtonTapped(){
        
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: nil, placeUsecase: nil)
        
        let closeButtonTapped$ = PublishRelay<Void>()

        
        let _ = vm.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: .empty(), refetchButtonTapped$:.empty(), closeButtonTapped$: closeButtonTapped$.asObservable(), bibleBookChanged$: .empty(), verseCellTapped$: .empty()))
        
        closeButtonTapped$.accept(())
        
        XCTAssertTrue(navigator.isDismissed)
        
        
    }

    func test_navigator_present_calledWithBibleVerseDetail_when_verseCellTapped_and_selectedBookExists(){
        
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: .Acts, placeUsecase: nil)
        
        let verseCellTapped$ = PublishRelay<Verse>()

        
        let _ = vm.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: .empty(), refetchButtonTapped$: .empty(), closeButtonTapped$: .empty(), bibleBookChanged$: .empty(), verseCellTapped$: verseCellTapped$.asObservable()))
        
        verseCellTapped$.accept(.def("12.21"))
        
        XCTAssertEqual(navigator.presentedSheet, .bibleVerseDetail(.Acts, "12.21", nil))
      
        
    }

    func test_navigator_notPresent_when_verseCellTapped_and_noSelectedBook(){
        
        let vm = BibleBookVerseListBottomSheetViewModel(navigator: navigator, placeId: placeId, bibleBook: nil, placeUsecase: nil)
        
        let verseCellTapped$ = PublishRelay<Verse>()

        
        let _ = vm.transform(input: BibleBookVerseListBottomSheetViewModel.Input(viewLoaded$: .empty(), refetchButtonTapped$: .empty(), closeButtonTapped$: .empty(), bibleBookChanged$: .empty(), verseCellTapped$: verseCellTapped$.asObservable()))
        
        verseCellTapped$.accept(.def("12.21"))
        
        XCTAssertNil(navigator.presentedSheet)
        
    }

}
