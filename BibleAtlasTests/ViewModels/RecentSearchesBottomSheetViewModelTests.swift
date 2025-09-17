//
//  RecentSearchesBottomSheetViewModel.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/12/25.
//

import XCTest

import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas

final class RecentSearchesBottomSheetViewModelTests: XCTestCase {

    private var navigator:MockBottomSheetNavigator!
    private var recentSearchService:MockRecentSearchService!
    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!

    override func setUp(){
        super.setUp()
        self.navigator = MockBottomSheetNavigator();
        self.recentSearchService = MockRecentSearchService()
        self.disposeBag = DisposeBag()
        self.scheduler = TestScheduler(initialClock: 0)
    }
    
    private var items:[RecentSearchItem] = [
        RecentSearchItem(id: "asdsss", name: "fofo", type: "region"),
        RecentSearchItem(id: "asdsss2", name: "fofo2", type: "region"),
        RecentSearchItem(id: "asdsss3", name: "fofo3", type: "region"),

    ]
    
    func test_viewLoaded_success_replacesList_setsLoadingFalse_clearsFetchError(){
        let result:Result<RecentSearchFetchResult, RecentSearchError> = .success(RecentSearchFetchResult(items: items, total: items.count, page: 0))
        
        let exp = expectation(description: "core data wait")
       
        recentSearchService.resultToReturn = result
        recentSearchService.resultExp = exp;
        
        
        let vm = RecentSearchesBottomSheetViewModel(navigator: navigator, recentSearchService: recentSearchService);
        
        let viewLoaded$ = PublishRelay<Void>();
        
        let output = vm.transform(input: RecentSearchesBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), closeButtonTapped$: .empty(), cellSelected$: .empty(), bottomReached$: .empty(), retryButtonTapped$: .empty(), allClearButtonTapped$: .empty()))
        
        var gotRecentSearches: [RecentSearchItem] = []
        let recentSearchesExp = expectation(description: "recentSearches set")
        
        output.recentSearches$.skip(2).take(1).subscribe(onNext:{
            recentSearches in
            gotRecentSearches = recentSearches
            recentSearchesExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        var loadingSeq: [Bool] = []
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2

        output.isInitialLoading$
            .skip(1)
            .take(2)
            .subscribe(onNext: { v in
                loadingSeq.append(v)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)
        

        let errorExp = expectation(description: "error set")
        errorExp.isInverted = true
        
        output.errorToFetch$
            .skip(2)
            .take(1)
            .subscribe(onNext: { v in
                errorExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        viewLoaded$.accept(())
            
        wait(for: [exp, recentSearchesExp, loadingExp, errorExp], timeout: 1)
        
        XCTAssertEqual(gotRecentSearches.count, 3)
        XCTAssertEqual(loadingSeq, [true , false])
        
    }
    
    func test_viewLoaded_failure_keepsListEmpty_setsLoadingFalse_setsFetchError(){
        
        let error:RecentSearchError = .fetchFailed(NSError(domain: "Test", code: 1))
        let result:Result<RecentSearchFetchResult, RecentSearchError> = .failure(error)
        let exp = expectation(description: "core data wait")
       
        recentSearchService.resultToReturn = result
        recentSearchService.resultExp = exp;
        
        
        let vm = RecentSearchesBottomSheetViewModel(navigator: navigator, recentSearchService: recentSearchService);
        
        let viewLoaded$ = PublishRelay<Void>();
        
        let output = vm.transform(input: RecentSearchesBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), closeButtonTapped$: .empty(), cellSelected$: .empty(), bottomReached$: .empty(), retryButtonTapped$: .empty(), allClearButtonTapped$: .empty()))
        

        let recentSearchesExp = expectation(description: "recentSearches set")
        recentSearchesExp.isInverted = true
        output.recentSearches$.skip(2).take(1).subscribe(onNext:{
            recentSearches in
            recentSearchesExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        var loadingSeq: [Bool] = []
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2

        output.isInitialLoading$
            .skip(1)
            .take(2)
            .subscribe(onNext: { v in
                loadingSeq.append(v)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        var gotError:RecentSearchError?;
        let errorExp = expectation(description: "error set")
        
        
        output.errorToFetch$
            .skip(2)
            .take(1)
            .subscribe(onNext: { error in
                gotError = error;
                errorExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        viewLoaded$.accept(())
            
        wait(for: [exp, recentSearchesExp, loadingExp, errorExp], timeout: 1)
        
        XCTAssertEqual(loadingSeq, [true , false])
        XCTAssertEqual(gotError, error)
        
    }
    
    
    func test_bottomReached_success_appendsNextPage_togglesFetching(){
        let result:Result<RecentSearchFetchResult, RecentSearchError> = .success(RecentSearchFetchResult(items: items, total: 30, page: 0))
        
        let exp = expectation(description: "core data wait")
       
        recentSearchService.resultToReturn = result
        recentSearchService.resultExp = exp;
        
        
        let vm = RecentSearchesBottomSheetViewModel(navigator: navigator, recentSearchService: recentSearchService, schedular: scheduler);
        
        let viewLoaded$ = PublishRelay<Void>();
        let bottomReached$ = PublishRelay<Void>();

        let output = vm.transform(input: RecentSearchesBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), closeButtonTapped$: .empty(), cellSelected$: .empty(), bottomReached$: bottomReached$.asObservable(), retryButtonTapped$: .empty(), allClearButtonTapped$: .empty()))
        
        let recentSearchesExp = expectation(description: "recentSearches set")
        
        output.recentSearches$.skip(2).take(1).subscribe(onNext:{
            recentSearches in
            recentSearchesExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())

        wait(for: [exp, recentSearchesExp], timeout: 1)
        
        
        let nextResult:Result<RecentSearchFetchResult, RecentSearchError> = .success(RecentSearchFetchResult(items: items, total: 30, page: 1))
        
        let reExp = expectation(description: "core data re wait")
       
        recentSearchService.resultToReturn = nextResult
        recentSearchService.resultExp = reExp;
        
        var gotRecentSearches:[RecentSearchItem] = [];
        let recentSearchesReExp = expectation(description: "recentSearches reset")

        
        output.recentSearches$.skip(1).take(1).subscribe(onNext:{
            recentSearches in
            gotRecentSearches = recentSearches;
            recentSearchesReExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        bottomReached$.accept(())
        scheduler.advanceTo(200)
        
        wait(for:[reExp, recentSearchesReExp])
        
        XCTAssertEqual(gotRecentSearches.count, 6)
        
    }
    
    
    func test_bottomReached_ignored_whenNoMorePages(){
        let result:Result<RecentSearchFetchResult, RecentSearchError> = .success(RecentSearchFetchResult(items: items, total: 3, page: 0))
        
        let exp = expectation(description: "core data wait")
       
        recentSearchService.resultToReturn = result
        recentSearchService.resultExp = exp;
        
        
        let vm = RecentSearchesBottomSheetViewModel(navigator: navigator, recentSearchService: recentSearchService, schedular: scheduler);
        
        let viewLoaded$ = PublishRelay<Void>();
        let bottomReached$ = PublishRelay<Void>();

        let output = vm.transform(input: RecentSearchesBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), closeButtonTapped$: .empty(), cellSelected$: .empty(), bottomReached$: bottomReached$.asObservable(), retryButtonTapped$: .empty(), allClearButtonTapped$: .empty()))
        
        let recentSearchesExp = expectation(description: "recentSearches set")
        
        output.recentSearches$.skip(2).take(1).subscribe(onNext:{
            recentSearches in
            recentSearchesExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())

        wait(for: [exp, recentSearchesExp], timeout: 1)
        
        
        
        let reExp = expectation(description: "core data re wait")
        reExp.isInverted = true
        recentSearchService.resultExp = reExp;
            
        bottomReached$.accept(())
        scheduler.advanceTo(200)
        
        wait(for:[reExp], timeout: 1)
    }
    
    func test_cellSelected_presentsPlaceDetail(){
        
        let vm = RecentSearchesBottomSheetViewModel(navigator: navigator, recentSearchService: recentSearchService);
 
        
        let cellSelected$ = PublishRelay<String>();
        let output = vm.transform(input: RecentSearchesBottomSheetViewModel.Input(viewLoaded$: .empty(), closeButtonTapped$: .empty(), cellSelected$: cellSelected$.asObservable(), bottomReached$: .empty(), retryButtonTapped$: .empty(), allClearButtonTapped$: .empty()))
        
        
        let placeId = "test-id"
        cellSelected$.accept(placeId)
        
        XCTAssertEqual( navigator.presentedSheet, .placeDetail(placeId))
        
    }
    
    func test_closeButtonTapped_dismisses(){
        
        
        let vm = RecentSearchesBottomSheetViewModel(navigator: navigator, recentSearchService: recentSearchService);
        
        let closeButtonTapped$ = PublishRelay<Void>();
        
        let output = vm.transform(input: RecentSearchesBottomSheetViewModel.Input(viewLoaded$: .empty(), closeButtonTapped$: closeButtonTapped$.asObservable(), cellSelected$: .empty(), bottomReached$: .empty(), retryButtonTapped$: .empty(), allClearButtonTapped$: .empty()))
        
        
        closeButtonTapped$.accept(())
        
        XCTAssertTrue(navigator.isDismissed)
 
    }
    
    
    func test_allClear_success_clearsList_noInteractError(){
        
        let result:Result<RecentSearchFetchResult, RecentSearchError> = .success(RecentSearchFetchResult(items: items, total: 30, page: 0))
        
        let exp = expectation(description: "core data wait")
       
        recentSearchService.resultToReturn = result
        recentSearchService.resultExp = exp;
        
        
        let vm = RecentSearchesBottomSheetViewModel(navigator: navigator, recentSearchService: recentSearchService, schedular: scheduler);
        
        let viewLoaded$ = PublishRelay<Void>();
        let allClearButtonTapped$ = PublishRelay<Void>();
        
        let output = vm.transform(input: RecentSearchesBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), closeButtonTapped$: .empty(), cellSelected$: .empty(), bottomReached$: .empty(), retryButtonTapped$: .empty(), allClearButtonTapped$: allClearButtonTapped$.asObservable()))
        
        let recentSearchesExp = expectation(description: "recentSearches set")
        
        output.recentSearches$.skip(2).take(1).subscribe(onNext:{
            recentSearches in
            recentSearchesExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())

        wait(for: [exp, recentSearchesExp], timeout: 1)
        
        recentSearchService.clearAllResultToReturn = .success(())
        
        var gotRecentSearches: [RecentSearchItem]?
        let recentSearchResetExp = expectation(description: "recentSearches reset")
        
        output.recentSearches$.skip(1).take(1).subscribe(onNext:{
            recentSearches in
            gotRecentSearches = recentSearches
            recentSearchResetExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        let errorExp = expectation(description: "error set")
        errorExp.isInverted = true
        output.errorToInteract$.skip(1).compactMap{$0}.subscribe(onNext:{
            error in
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        allClearButtonTapped$.accept(())
        
    
        wait(for:[recentSearchResetExp, errorExp], timeout:1)

        XCTAssertEqual(gotRecentSearches?.count, 0)
    }
    
    
    func test_allClear_failure_setsInteractError_keepsList(){
        
        let result:Result<RecentSearchFetchResult, RecentSearchError> = .success(RecentSearchFetchResult(items: items, total: 30, page: 0))
        
        let exp = expectation(description: "core data wait")
       
        recentSearchService.resultToReturn = result
        recentSearchService.resultExp = exp;
        
        
        let vm = RecentSearchesBottomSheetViewModel(navigator: navigator, recentSearchService: recentSearchService, schedular: scheduler);
        
        let viewLoaded$ = PublishRelay<Void>();
        let allClearButtonTapped$ = PublishRelay<Void>();
        
        let output = vm.transform(input: RecentSearchesBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), closeButtonTapped$: .empty(), cellSelected$: .empty(), bottomReached$: .empty(), retryButtonTapped$: .empty(), allClearButtonTapped$: allClearButtonTapped$.asObservable()))
        
        let recentSearchesExp = expectation(description: "recentSearches set")
        
        output.recentSearches$.skip(2).take(1).subscribe(onNext:{
            recentSearches in
            recentSearchesExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())

        wait(for: [exp, recentSearchesExp], timeout: 1)
        
        
        let error = RecentSearchError.clearFailed(NSError(domain: "test", code: -1))
        
        recentSearchService.clearAllResultToReturn = .failure(error)
        

        let recentSearchResetExp = expectation(description: "recentSearches reset")
        
        recentSearchResetExp.isInverted = true
        output.recentSearches$.skip(1).take(1).subscribe(onNext:{
            recentSearches in
            recentSearchResetExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        var gotError:RecentSearchError?
        let errorExp = expectation(description: "error set")

        output.errorToInteract$.skip(1).compactMap{$0}.subscribe(onNext:{
            error in
            gotError = error
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        allClearButtonTapped$.accept(())
        
    
        wait(for:[recentSearchResetExp, errorExp], timeout:1)

        XCTAssertEqual(gotError, error)
        
        
    }
    

}
