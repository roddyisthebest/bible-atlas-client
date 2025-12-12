//
//  SearchResultViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/8/25.
//

import XCTest
import RxSwift
import RxTest
import RxBlocking

@testable import BibleAtlas

final class SearchResultViewModelTests: XCTestCase {
    
    private var sut: SearchResultViewModel!
    private var mockUsecase: MockPlaceusecase!
    private var mockNavigator: MockBottomSheetNavigator!
    private var mockRecentSearch: MockRecentSearchService!
    
    private var isSearchingModeSubject: BehaviorSubject<Bool>!
    private var keywordSubject: BehaviorSubject<String>!
    private var cancelSubject: PublishSubject<Void>!
    
    private var refetchSubject: PublishSubject<Void>!
    private var bottomReachedSubject: PublishSubject<Void>!
    private var placeSelectedSubject: PublishSubject<Place>!
    
    private var output: SearchResultViewModel.Output!
    
    private var disposeBag: DisposeBag!
    private var testScheduler: TestScheduler!
    
    override func setUp() {
        super.setUp()
        
        disposeBag = DisposeBag()
        testScheduler = TestScheduler(initialClock: 0)
        
        mockUsecase = MockPlaceusecase()
        mockNavigator = MockBottomSheetNavigator()
        mockRecentSearch = MockRecentSearchService()
        
        isSearchingModeSubject = BehaviorSubject<Bool>(value: true)
        keywordSubject = BehaviorSubject<String>(value: "")
        cancelSubject = PublishSubject<Void>()
        
        refetchSubject = PublishSubject<Void>()
        bottomReachedSubject = PublishSubject<Void>()
        placeSelectedSubject = PublishSubject<Place>()
        
        sut = SearchResultViewModel(
            navigator: mockNavigator,
            placeUsecase: mockUsecase,
            isSearchingMode$: isSearchingModeSubject.asObservable(),
            keyword$: keywordSubject.asObservable(),
            cancelButtonTapped$: cancelSubject.asObservable(),
            recentSearchService: mockRecentSearch,
            schedular: testScheduler   // 🔥 여기서만 TestScheduler 주입
        )
        
        output = sut.transform(
            input: SearchResultViewModel.Input(
                refetchButtonTapped$: refetchSubject.asObservable(),
                bottomReached$: bottomReachedSubject.asObservable(),
                placeCellSelected$: placeSelectedSubject.asObservable()
            )
        )
    }
    
    override func tearDown() {
        sut = nil
        mockUsecase = nil
        mockNavigator = nil
        mockRecentSearch = nil
        
        isSearchingModeSubject = nil
        keywordSubject = nil
        cancelSubject = nil
        
        refetchSubject = nil
        bottomReachedSubject = nil
        placeSelectedSubject = nil
        
        output = nil
        disposeBag = nil
        testScheduler = nil
        
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    private func stubFirstSearchResult(count: Int = 1, total: Int = 40, page: Int = 0) {
        let places = (0..<count).map { index in
            Place.mock(id: String(index), name: "")
        }
        let response = ListResponse(total: total, page: page, limit:40, data: places)
        mockUsecase.resultsQueue.append(.success(response))
    }
    
    // MARK: - Tests
    
    /// 검색 모드 + 키워드 입력 → debounce 이후 getPlaces 호출 & places / isSearching 값 업데이트
    func test_search_withNonEmptyKeywordAndSearchingMode_callsGetPlaces_andUpdatesPlaces() {
        // given
        stubFirstSearchResult(count: 2, total: 40)
        
        // 호출 완료 감시용 expectation
        let exp = expectation(description: "getPlaces completed")
        mockUsecase.completedExp = exp
        
        let placesObserver = testScheduler.createObserver([Place].self)
        let searchingObserver = testScheduler.createObserver(Bool.self)
        
        output.places$
            .subscribe(placesObserver)
            .disposed(by: disposeBag)
        
        output.isSearching$
            .subscribe(searchingObserver)
            .disposed(by: disposeBag)
        
        // when
        keywordSubject.onNext("  Jerusalem ")
        isSearchingModeSubject.onNext(true)
        
        // debounce 250ms 이후 시점까지 진행
        testScheduler.advanceTo(300)
        
        wait(for: [exp], timeout: 1.0)
        
        // then
        XCTAssertEqual(mockUsecase.listApiCall, 1)
        XCTAssertEqual(mockUsecase.lastGetPlacesParameters?.name, "Jerusalem")
        
        // places 이벤트 중 마지막 값 확인
        let placesEvents = placesObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(placesEvents.last?.count, 2)
        
        // isSearching 마지막 값은 false 여야 함
        let searchingEvents = searchingObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(searchingEvents.last, false)
    }
    
    /// 키워드가 빈 문자열이 되면 places 클리어 & error nil & isSearching false, 추가 호출 없음
    func test_keywordEmpty_clearsPlacesAndStopsSearching_andDoesNotCallUsecaseSecondTime() {
        // given: 첫 검색 한 번
        stubFirstSearchResult(count: 1, total: 40)
        let firstExp = expectation(description: "first getPlaces completed")
        mockUsecase.completedExp = firstExp
        
        let placesObserver = testScheduler.createObserver([Place].self)
        let searchingObserver = testScheduler.createObserver(Bool.self)
        
        output.places$
            .subscribe(placesObserver)
            .disposed(by: disposeBag)
        
        output.isSearching$
            .subscribe(searchingObserver)
            .disposed(by: disposeBag)
        
        // when: 1차 검색
        keywordSubject.onNext("Ab")
        isSearchingModeSubject.onNext(true)
        testScheduler.advanceTo(300)
        wait(for: [firstExp], timeout: 1.0)
        
        // when: 빈 키워드로 변경
        keywordSubject.onNext("   ")
        testScheduler.advanceTo(600)   // 두 번째 debounce 지점 뒤로
        
        // then: getPlaces는 딱 한 번만
        XCTAssertEqual(mockUsecase.listApiCall, 1)
        
        let placesEvents = placesObserver.events.compactMap { $0.value.element }
        // 마지막 값은 빈 배열
        XCTAssertEqual(placesEvents.last?.count, 0)
        
        let searchingEvents = searchingObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(searchingEvents.last, false)
    }
    
    /// 검색 모드가 false면 검색이 발생하지 않음
    func test_whenSearchingModeIsFalse_doesNotTriggerSearch() {
        // given
        isSearchingModeSubject.onNext(false)
        
        // when
        keywordSubject.onNext("Some Keyword")
        testScheduler.advanceTo(300)
        
        // then
        XCTAssertEqual(mockUsecase.listApiCall, 0)
    }
    
    /// bottomReached + hasMore → 추가 페이지 fetch
    func test_bottomReached_withKeyword_fetchesMorePlaces() {
        // given
        // 첫 페이지
        let firstPlaces = (0..<20).map { Place.mock(id: String($0), name: "") }
//        (total: 100, page: total, limit:40, data: places)
        mockUsecase.resultsQueue.append(.success(ListResponse(total:40, page:0, limit: 20,data: firstPlaces)))
        
        // 두 번째 페이지
        let secondPlaces = (20..<40).map { Place.mock(id: String($0), name: "") }
        mockUsecase.resultsQueue.append(.success(ListResponse(total:40, page:1, limit: 20,data: secondPlaces)))
        
        let firstExp = expectation(description: "first getPlaces")
        let secondExp = expectation(description: "second getPlaces")
        
        // 첫 호출 완료 후 두 번째 호출 완료 감시
        mockUsecase.completedExp = firstExp
        
        let placesObserver = testScheduler.createObserver([Place].self)
        output.places$
            .subscribe(placesObserver)
            .disposed(by: disposeBag)
        
        // 1) 최초 검색
        keywordSubject.onNext("Jericho")
        isSearchingModeSubject.onNext(true)
        testScheduler.advanceTo(300)
        wait(for: [firstExp], timeout: 1.0)
        
        XCTAssertEqual(mockUsecase.listApiCall, 1)
        
        // 2) bottomReached → 추가 로드
        mockUsecase.completedExp = secondExp
        
        bottomReachedSubject.onNext(())
        // bottomReached debounce 500 microseconds 를 커버할 만큼 시간 전진
        testScheduler.advanceTo(800)
        
        wait(for: [secondExp], timeout: 1.0)
        
        // then
        XCTAssertEqual(mockUsecase.listApiCall, 2)
        
        let placesEvents = placesObserver.events.compactMap { $0.value.element }
        // 마지막 값은 40개
        XCTAssertEqual(placesEvents.last?.count, 40)
    }
    
    /// bottomReached 시 keyword 가 비어있으면 추가 fetch 안 함
    func test_bottomReached_withEmptyKeyword_doesNotFetchMore() {
        // given
        isSearchingModeSubject.onNext(true)
        keywordSubject.onNext("")
        
        // when
        bottomReachedSubject.onNext(())
        testScheduler.advanceTo(800)
        
        // then
        XCTAssertEqual(mockUsecase.listApiCall, 0)
    }
    
    /// placeCell 선택 시, 최근 검색 저장 성공이면 detail 로 이동
    func test_placeCellSelected_whenSaveSuccess_presentsDetail() {
        // given
        mockRecentSearch.saveResultToReturn = .success(())
        let place = Place.mock(id: "123", name: "")
        
        // when
        placeSelectedSubject.onNext(place)
        
        // then
        XCTAssertEqual(mockRecentSearch.savedPlaces.count, 1)
        XCTAssertEqual(mockNavigator.presentedSheet, .placeDetail(place.id))

    }
    
    struct CustomStringError: LocalizedError {
        let message: String
        
        // LocalizedError를 채택하면 errorDescription을 통해 메시지를 전달합니다.
        var errorDescription: String? {
            return message
        }
        
        init(_ message: String) {
            self.message = message
        }
    }
    
    /// placeCell 선택 시, 최근 검색 저장 실패 → errorToSaveRecentSearch$ 에 에러 emit
    func test_placeCellSelected_whenSaveFails_emitsError() {
        // given
        mockRecentSearch.saveResultToReturn = .failure(.saveFailed(CustomStringError("test")))
        let place = Place.mock(id: "123", name: "")
        
        let errorObserver = testScheduler.createObserver(RecentSearchError?.self)
        output.errorToSaveRecentSearch$
            .subscribe(errorObserver)
            .disposed(by: disposeBag)
        
        // when
        placeSelectedSubject.onNext(place)
        
        // then
        let errors = errorObserver.events.compactMap { $0.value.element }.compactMap { $0 }
        guard let last = errors.last else {
            XCTFail("Expected some error event")
            return
        }
        
        if case .saveFailed(let error) = last {
            XCTAssertEqual(error.localizedDescription, "test")
        } else {
            XCTFail("Expected .saveFailed")
        }
    }
    
    /// refetchButtonTapped + non-empty keyword → getPlaces 호출
    func test_refetchButtonTapped_withNonEmptyKeyword_callsGetPlaces() {
        // given
        // combineLatest(debouncedKeyword$, isSearchingMode$) 경로 안 타도록 검색 모드는 false
        isSearchingModeSubject.onNext(false)
        
        keywordSubject.onNext("  Galilee ")
        
        let exp = expectation(description: "refetch getPlaces")
        stubFirstSearchResult(count: 1, total: 20)
        mockUsecase.completedExp = exp
        
        // when
        refetchSubject.onNext(())
        
        wait(for: [exp], timeout: 1.0)
        
        // then
        XCTAssertEqual(mockUsecase.listApiCall, 1)
        XCTAssertEqual(mockUsecase.lastGetPlacesParameters?.name, "Galilee")
    }
    
    func test_debouncedKeyword_emitsTrimmedLastValue() {
        // given
        let keywordObserver = testScheduler.createObserver(String.self)
        output.debouncedKeyword$
            .subscribe(keywordObserver)
            .disposed(by: disposeBag)
        
        // when
        keywordSubject.onNext("  A ")
        testScheduler.advanceTo(200)
        
        keywordSubject.onNext("  AB ")
        testScheduler.advanceTo(600)
        
        // then
        let values = keywordObserver.events.compactMap { $0.value.element }
        
        // 1) 모든 값이 trim 되어 있는지 검증
        XCTAssertTrue(
            values.allSatisfy { $0 == $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            "모든 debouncedKeyword$ 값은 공백이 trim 되어 있어야 한다"
        )
        
        // 2) 최종 값이 "AB" 인지만 보장
        XCTAssertEqual(values.last, "AB")
    }

    
    /// getPlaces 실패 시 errorToFetchPlaces$ 에 에러 emit
    func test_getPlaces_failure_setsErrorToFetchPlaces() {
        // given
        mockUsecase.resultsQueue.append(.failure(.clientError("network fail")))
        
        let exp = expectation(description: "getPlaces failure")
        mockUsecase.completedExp = exp
        
        let errorObserver = testScheduler.createObserver(NetworkError?.self)
        output.errorToFetchPlaces$
            .subscribe(errorObserver)
            .disposed(by: disposeBag)
        
        // when
        keywordSubject.onNext("ErrorCase")
        isSearchingModeSubject.onNext(true)
        testScheduler.advanceTo(300)
        
        wait(for: [exp], timeout: 1.0)
        
        // then
        let errors = errorObserver.events.compactMap { $0.value.element }
        guard let last = errors.last as? NetworkError else {
            XCTFail("Expected NetworkError")
            return
        }
        
        if case .clientError(let message) = last {
            XCTAssertEqual(message, "network fail")
        } else {
            XCTFail("Expected .clientError")
        }
    }
}
