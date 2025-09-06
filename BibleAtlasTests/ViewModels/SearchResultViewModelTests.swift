//
//  SearchResultViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/8/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas


final class SearchResultViewModelTests: XCTestCase {
    
    private var mockPlaceUsecase:MockPlaceusecase!
    private var mockNavigator: MockBottomSheetNavigator!
    private var disposeBag: DisposeBag!
    private var mockRecentSearchService:MockRecentSearchService!
    private var scheduler: TestScheduler!

    override func setUp()  {
        super.setUp();
        
        disposeBag = DisposeBag();
        mockPlaceUsecase = MockPlaceusecase();
        mockNavigator = MockBottomSheetNavigator();
        mockRecentSearchService = MockRecentSearchService();
        scheduler = TestScheduler(initialClock: 0);
    }
    
    func test_search_starts_when_keyword_and_searchMode_are_valid(){
        
        let expectation = XCTestExpectation(description: "wait for async task")
        mockPlaceUsecase.invokedExp = expectation

        let isSearchingMode$ = BehaviorRelay<Bool>(value: false);
        let keyword$ = BehaviorRelay<String>(value: "");
        let cancelButtonTapped$ = PublishRelay<Void>();
        
        
        let viewModel = SearchResultViewModel(navigator: mockNavigator, placeUsecase: mockPlaceUsecase, isSearchingMode$: isSearchingMode$.asObservable(), keyword$: keyword$.asObservable(), cancelButtonTapped$: cancelButtonTapped$.asObservable(), recentSearchService: mockRecentSearchService, schedular: scheduler)
        
        
        let _ = viewModel.transform(input: SearchResultViewModel.Input(refetchButtonTapped$: .empty(), bottomReached$: .empty(), placeCellSelected$: .empty()))
        
        
        isSearchingMode$.accept(true)
        keyword$.accept("test")
        scheduler.start();
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockPlaceUsecase.isCalled, true)
        
    }
    
    func test_search_clears_when_keyword_is_empty() throws{
        let isSearchingMode$ = BehaviorRelay<Bool>(value: false);
        let keyword$ = BehaviorRelay<String>(value: "");
        let cancelButtonTapped$ = PublishRelay<Void>();
        
        
        let viewModel = SearchResultViewModel(navigator: mockNavigator, placeUsecase: mockPlaceUsecase, isSearchingMode$: isSearchingMode$.asObservable(), keyword$: keyword$.asObservable(), cancelButtonTapped$: cancelButtonTapped$.asObservable(), recentSearchService: mockRecentSearchService, schedular: scheduler)
        
        
        let output = viewModel.transform(input: SearchResultViewModel.Input(refetchButtonTapped$: .empty(), bottomReached$: .empty(), placeCellSelected$: .empty()))
        
        
        
        
        isSearchingMode$.accept(true)
        keyword$.accept("test")
        let mockPlaces = [
            Place(id: "1233", name: "test", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 5, types: [])]
        
        mockPlaceUsecase.resultToReturn = .success(ListResponse(
        total: 1, page: 0, limit: 10, data: mockPlaces))
        
        scheduler.start();
        
        let places1 = try output.places$.toBlocking().first();
        XCTAssertEqual(places1?.count, 1)

        keyword$.accept("")
        scheduler.start();

        let places2 = try output.places$.toBlocking().first();
        XCTAssertEqual(places2?.count, 0)
        
    }
    
    
    func test_getMorePlaces_triggers_on_bottomReached_with_keyword(){
        let isSearchingMode$ = BehaviorRelay<Bool>(value: true);
        let keyword$ = BehaviorRelay<String>(value: "test");
        
        
        let viewModel = SearchResultViewModel(navigator: mockNavigator, placeUsecase: mockPlaceUsecase, isSearchingMode$: isSearchingMode$.asObservable(), keyword$: keyword$.asObservable(), cancelButtonTapped$: .empty(), recentSearchService: mockRecentSearchService, schedular: scheduler)
        
        let bottomReached$ = PublishRelay<Void>()
        
        let output = viewModel.transform(input: SearchResultViewModel.Input(refetchButtonTapped$: .empty(), bottomReached$: bottomReached$.asObservable(), placeCellSelected$: .empty()))
            
        let isFetchingNextObserver = scheduler.createObserver(Bool.self);
        
        output.isFetchingNext$
            .observe(on: scheduler)
            .bind(to: isFetchingNextObserver)
            .disposed(by: disposeBag)
        
        
        bottomReached$.accept(())
        scheduler.start();
        
        let actualEvents = isFetchingNextObserver.events.compactMap { $0.value.element }
        XCTAssertTrue(actualEvents.contains(true))
        
    }
    
    
    func test_placeCellSelected_saves_recent_and_navigates_to_detail(){
        
        let viewModel = SearchResultViewModel(navigator: mockNavigator, placeUsecase: mockPlaceUsecase, isSearchingMode$: .empty(), keyword$: .empty(), cancelButtonTapped$: .empty(), recentSearchService: mockRecentSearchService)
        
        let placeCelSelected$ = PublishRelay<Place>()
        let _ = viewModel.transform(input: SearchResultViewModel.Input(refetchButtonTapped$: .empty(), bottomReached$: .empty(), placeCellSelected$: placeCelSelected$.asObservable() ))
        
        
        mockRecentSearchService.saveResultToReturn = .success(())
        
        let place = Place(id: "test", name: "test", isModern: true, description: "test", koreanDescription: "test", stereo: .child, likeCount: 10, types: [])
        placeCelSelected$.accept(place)
        
        XCTAssertEqual(mockNavigator.presentedSheet, .placeDetail("test"))
        
        
        
    }

    

    func test_placeCellSelected_emits_error_when_recent_save_fails() throws {
        let viewModel = SearchResultViewModel(navigator: mockNavigator, placeUsecase: mockPlaceUsecase, isSearchingMode$: .empty(), keyword$: .empty(), cancelButtonTapped$: .empty(), recentSearchService: mockRecentSearchService)
        
        let placeCelSelected$ = PublishRelay<Place>()
        let output = viewModel.transform(input: SearchResultViewModel.Input(refetchButtonTapped$: .empty(), bottomReached$: .empty(), placeCellSelected$: placeCelSelected$.asObservable() ))
        
        
        
        let dummyError = NSError(domain: "Test", code: 1)
        mockRecentSearchService.saveResultToReturn = .failure(.saveFailed(dummyError))
        
        let place = Place(id: "test", name: "test", isModern: true, description: "test", koreanDescription: "test", stereo: .child, likeCount: 10, types: [])
        placeCelSelected$.accept(place)
        
        let errorToSaveRecentSearch = try output.errorToSaveRecentSearch$.toBlocking().first()
    
        XCTAssertNotNil(errorToSaveRecentSearch!)
        
        
    }
    
    
    func test_refetchButtonTapped_retriggers_search_with_current_keyword(){
        let keyword$ = BehaviorRelay<String>(value: "test");

        
        let viewModel = SearchResultViewModel(placeUsecase: mockPlaceUsecase, isSearchingMode$: .empty(), keyword$: keyword$.asObservable(), cancelButtonTapped$: .empty(), recentSearchService: mockRecentSearchService)
        
        let refetchButtonTapped$ = PublishRelay<Void>()

        
        let _ = viewModel.transform(input: SearchResultViewModel.Input(refetchButtonTapped$: refetchButtonTapped$.asObservable(), bottomReached$: .empty(), placeCellSelected$: .empty()))

        refetchButtonTapped$.accept(())
        
        
        XCTAssertEqual(mockPlaceUsecase.isCalled, true)
        
        
    }


}
