//
//  BibleVerseDetailBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/10/25.
//

import XCTest
import RxSwift
import RxRelay

@testable import BibleAtlas

final class BibleVerseDetailBottomSheetViewModelTests: XCTestCase {
    
    var navigator:MockBottomSheetNavigator!
    var placeUsecase:MockPlaceusecase!
    var keyword = "test-keyword"
    var disposeBag:DisposeBag!
    override func setUp(){
        super.setUp();
        navigator = MockBottomSheetNavigator();
        placeUsecase = MockPlaceusecase();
        disposeBag = DisposeBag();
    }
    
    
    func test_viewLoaded_success_setsVerse_setsLoadingFalse_keepsErrorNil(){
        
        let exp = expectation(description: "verse api wait")
        placeUsecase.bibleVerseExp = exp;
        
        let text = "stomach"
        let result: Result<BibleAtlas.BibleVerseResponse, BibleAtlas.NetworkError>? = .success(BibleVerseResponse(text: text))
        placeUsecase.bibleVerseResult = result
        
        let vm = BibleVerseDetailBottomSheetViewModel(navigator: navigator, bibleBook: .Etc, keyword: keyword, placeName: "", placeUsecase: placeUsecase)
        
        let viewLoaded$ = PublishRelay<Void>();
        
        let output = vm.transform(input: BibleVerseDetailBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: .empty(), closeButtonTapped$: .empty()))
        
        var loadingSeq: [Bool] = []
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2
        
        output.isLoading$
            .take(2)
            .subscribe(onNext: { v in
                loadingSeq.append(v)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)
        
    
        var bibleVerseText:String?
        let textExp = expectation(description: "text set")
            
        output.bibleVerse$
            .skip(1)
            .take(1)
            .subscribe(onNext: {
                text in
                bibleVerseText = text;
                textExp.fulfill()
            }).disposed(by: disposeBag)
        
        
        let errorExp = expectation(description: "error set")
        errorExp.isInverted = true
        output.error$.skip(1).subscribe(onNext:{
            error in
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        
        viewLoaded$.accept(())
        
        wait(for: [loadingExp, exp, textExp, errorExp], timeout: 1.0)
        
        XCTAssertEqual(bibleVerseText, text)
        XCTAssertEqual(loadingSeq, [true, false])
        
    }
    
    
    
    func test_viewLoaded_failure_setsError_setsLoadingFalse_keepsVerseUnchanged(){
        let exp = expectation(description: "verse api wait")
        placeUsecase.bibleVerseExp = exp;
        
        let error: NetworkError = .clientError("test-error")
        let result: Result<BibleAtlas.BibleVerseResponse, BibleAtlas.NetworkError>? = .failure(error)
        placeUsecase.bibleVerseResult = result
        
        let vm = BibleVerseDetailBottomSheetViewModel(navigator: navigator, bibleBook: .Etc, keyword: keyword, placeName: "", placeUsecase: placeUsecase)
        
        let viewLoaded$ = PublishRelay<Void>();
        
        let output = vm.transform(input: BibleVerseDetailBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: .empty(), closeButtonTapped$: .empty()))
        
        var loadingSeq: [Bool] = []
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2
        
        output.isLoading$
            .take(2)
            .subscribe(onNext: { v in
                loadingSeq.append(v)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)
    
        var gotError:NetworkError?
        let errorExp = expectation(description: "error set")
        output.error$.skip(1).take(1).subscribe(onNext:{
            error in
            gotError = error
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        let bibleVerseExp = expectation(description: "bible verse set")
        bibleVerseExp.isInverted = true
        output.bibleVerse$.skip(1).subscribe(onNext:{
            verse in
            bibleVerseExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        
        wait(for: [loadingExp, exp, errorExp, bibleVerseExp], timeout: 1.0)
        
        XCTAssertEqual(gotError, error)
        XCTAssertEqual(loadingSeq, [true, false])
        
    }
    
    func test_refetch_success_setsLoadingTrueThenFalse_updatesVerse_andClearsError(){
        
        let exp = expectation(description: "verse api wait")
        placeUsecase.bibleVerseExp = exp;
        
        let text = "stomach"
        let result: Result<BibleAtlas.BibleVerseResponse, BibleAtlas.NetworkError>? = .success(BibleVerseResponse(text: text))
        placeUsecase.bibleVerseResult = result
        
        let vm = BibleVerseDetailBottomSheetViewModel(navigator: navigator, bibleBook: .Etc, keyword: keyword, placeName: "", placeUsecase: placeUsecase)
        
        let refetchButtonTapped$ = PublishRelay<Void>();
        
        let output = vm.transform(input: BibleVerseDetailBottomSheetViewModel.Input(viewLoaded$: .empty(), refetchButtonTapped$: refetchButtonTapped$.asObservable(), closeButtonTapped$: .empty()))
        
        var loadingSeq: [Bool] = []
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2
        
        output.isLoading$
            .skip(1)
            .take(2)
            .subscribe(onNext: { v in
                loadingSeq.append(v)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        var gotError:NetworkError?
        let errorExp = expectation(description: "error set")
        output.error$
            .skip(1)
            .take(1)
            .subscribe(onNext:{
                error in
                gotError = error
                errorExp.fulfill()
            }).disposed(by: disposeBag)
        
        
        
        var bibleVerseText:String?
        let textExp = expectation(description: "text set")
                
        output.bibleVerse$
            .skip(1)
            .take(1)
            .subscribe(onNext: {
                text in
                bibleVerseText = text;
                textExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        
        refetchButtonTapped$.accept(())
        
        
        wait(for: [exp, loadingExp, textExp, errorExp], timeout: 1.0)

        
        
        XCTAssertNil(gotError)
        XCTAssertEqual(bibleVerseText, text)
        XCTAssertEqual(loadingSeq, [true, false])
        
    }
    
    func test_refetch_failure_setsLoadingTrueThenFalse_setsError_keepsPreviousVerse(){
        
        // 1) viewLoaded$
        let exp = expectation(description: "verse api wait")
        placeUsecase.bibleVerseExp = exp;
        
        let text = "stomach"
        let result: Result<BibleAtlas.BibleVerseResponse, BibleAtlas.NetworkError>? = .success(BibleVerseResponse(text: text))
        placeUsecase.bibleVerseResult = result
        
        let vm = BibleVerseDetailBottomSheetViewModel(navigator: navigator, bibleBook: .Etc, keyword: keyword, placeName: "", placeUsecase: placeUsecase)
        
        let viewLoaded$ = PublishRelay<Void>();
        let refetchButtonTapped$ = PublishRelay<Void>();
        
        let output = vm.transform(input: BibleVerseDetailBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: refetchButtonTapped$.asObservable(), closeButtonTapped$: .empty()))
        

        
        let bibleVerseExp = expectation(description: "bible verse set")

        output.bibleVerse$.skip(1).subscribe(onNext:{
            verse in
            bibleVerseExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        
        wait(for: [exp, bibleVerseExp], timeout: 1.0)
        
        
        // 2) refetchButtonTapped$
        let reExp = expectation(description: "verse api re wait")
        placeUsecase.bibleVerseExp = reExp;
        
        let error: NetworkError = .clientError("test-error")
        let refetchedResult: Result<BibleAtlas.BibleVerseResponse, BibleAtlas.NetworkError>? = .failure(error)
        placeUsecase.bibleVerseResult = refetchedResult
    

        var loadingSeq: [Bool] = []
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2

        output.isLoading$
            .skip(1)
            .take(2)
            .subscribe(onNext: { v in
                loadingSeq.append(v)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)
    
        var gotError:NetworkError?
        let errorExp = expectation(description: "error set")
        output.error$.skip(2).take(1).subscribe(onNext:{
            error in
            gotError = error
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        let bibleVerseReExp = expectation(description: "bible verse reset")
        bibleVerseReExp.isInverted  = true
        output.bibleVerse$.skip(1).subscribe(onNext:{
            verse in
            bibleVerseReExp.fulfill()
        }).disposed(by: disposeBag)
                

        refetchButtonTapped$.accept(())

        wait(for: [loadingExp, errorExp, reExp, bibleVerseReExp], timeout: 1.0)
        XCTAssertEqual(gotError, error)

        
    }
    
    
    func test_closeButtonTapped_dismisses(){
        let vm = BibleVerseDetailBottomSheetViewModel(navigator: navigator, bibleBook: .Etc, keyword: keyword, placeName: "", placeUsecase: placeUsecase)
        
        let closeButtonTapped$ = PublishRelay<Void>();

        
        let _ = vm.transform(input: BibleVerseDetailBottomSheetViewModel.Input(viewLoaded$: .empty(), refetchButtonTapped$: .empty(), closeButtonTapped$: closeButtonTapped$.asObservable()))
    
        closeButtonTapped$.accept(())
        XCTAssertTrue(navigator.isDismissed)
    
    }

    
    func test_keywordParsing_simpleFormat_usesFirstTokenForBook_andDotSplitForChapterVerse(){
        
        let exp = expectation(description: "verse api wait")
        placeUsecase.bibleVerseExp = exp;
 
        keyword = "1.1"
        
        let vm = BibleVerseDetailBottomSheetViewModel(navigator: navigator, bibleBook: .Gen, keyword: keyword, placeName: "", placeUsecase: placeUsecase)
        
        let viewLoaded$ = PublishRelay<Void>();
        
        let _ = vm.transform(input: BibleVerseDetailBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: .empty(), closeButtonTapped$: .empty()))
        
        viewLoaded$.accept(())
        wait(for:[exp])
    
        XCTAssertEqual(placeUsecase.calledVerseProps?.book, "ge")
        XCTAssertEqual(placeUsecase.calledVerseProps?.chapter, "1")
        XCTAssertEqual(placeUsecase.calledVerseProps?.verse, "1")    
        
    }
    
    func test_errorIsClearedOnRefetchStart_beforeRequestCompletes(){
        // 1) viewLoaded$
        let exp = expectation(description: "verse api wait")
        placeUsecase.bibleVerseExp = exp;
        
        let error: NetworkError = .clientError("test-error")
        let result: Result<BibleAtlas.BibleVerseResponse, BibleAtlas.NetworkError>? = .failure(error)
        placeUsecase.bibleVerseResult = result
        
        let vm = BibleVerseDetailBottomSheetViewModel(navigator: navigator, bibleBook: .Etc, keyword: keyword, placeName: "", placeUsecase: placeUsecase)
        
        let viewLoaded$ = PublishRelay<Void>();
        let refetchButtonTapped$ = PublishRelay<Void>();
        
        let output = vm.transform(input: BibleVerseDetailBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: refetchButtonTapped$.asObservable(), closeButtonTapped$: .empty()))
        

        
        let errorExp = expectation(description: "error set")

        output.error$.skip(1).take(1).subscribe(onNext:{
            verse in
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        
        wait(for: [exp, errorExp], timeout: 1.0)
        
        
        // 2) refetchButtonTapped$
        
        let reExp = expectation(description: "verse api re wait")
        placeUsecase.bibleVerseExp = reExp;
        
        var gotError:NetworkError?
        let errorReExp = expectation(description: "error reset")
        output.error$.skip(1).take(1).subscribe(onNext: {
            error in
            gotError = error;
            errorReExp.fulfill()
        }).disposed(by: disposeBag)

        
        refetchButtonTapped$.accept(())
        
        wait(for:[errorReExp, reExp])
        XCTAssertNil(gotError)
        
    }
    
}
