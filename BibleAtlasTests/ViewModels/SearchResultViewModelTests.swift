//
//  SearchResultViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 2026/01/18.
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

    private var screenModeSubject: BehaviorSubject<HomeScreenMode>!
    private var keywordSubject: BehaviorSubject<String>!

    private var refetchSubject: PublishSubject<Void>!
    private var bottomReachedSubject: PublishSubject<Void>!
    private var placeSelectedSubject: PublishSubject<Place>!

    private var output: SearchResultViewModel.Output!

    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!

    override func setUp() {
        super.setUp()

        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)

        mockUsecase = MockPlaceusecase()
        mockNavigator = MockBottomSheetNavigator()
        mockRecentSearch = MockRecentSearchService()

        screenModeSubject = BehaviorSubject<HomeScreenMode>(value: .home)
        keywordSubject = BehaviorSubject<String>(value: "")

        refetchSubject = PublishSubject<Void>()
        bottomReachedSubject = PublishSubject<Void>()
        placeSelectedSubject = PublishSubject<Place>()

        sut = SearchResultViewModel(
            navigator: mockNavigator,
            placeUsecase: mockUsecase,
            screenMode$: screenModeSubject.asObservable(),
            keyword$: keywordSubject.asObservable(),
            recentSearchService: mockRecentSearch,
            schedular: scheduler
        )

        output = sut.transform(
            input: .init(
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

        screenModeSubject = nil
        keywordSubject = nil

        refetchSubject = nil
        bottomReachedSubject = nil
        placeSelectedSubject = nil

        output = nil
        disposeBag = nil
        scheduler = nil

        super.tearDown()
    }

    // MARK: - Helpers

    private func enqueueSuccess(count: Int, total: Int = 40, page: Int = 0, limit: Int = 20) {
        let places = (0..<count).map { Place.mock(id: "\($0)", name: "p\($0)") }
        let response = ListResponse(total: total, page: page, limit: limit, data: places)
        mockUsecase.resultsQueue.append(.success(response))
    }

    private func enqueueFailure(_ error: NetworkError) {
        mockUsecase.resultsQueue.append(.failure(error))
    }

    /// places 배열의 마지막 count가 기대값이 될 때까지 기다림
    private func waitPlacesCount(_ expected: Int, timeout: TimeInterval = 1.0, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "places count == \(expected)")
        output.places$
            .map { $0.count }
            .distinctUntilChanged()
            .filter { $0 == expected }
            .take(1)
            .subscribe(onNext: { _ in exp.fulfill() })
            .disposed(by: disposeBag)

        wait(for: [exp], timeout: timeout)
    }

    /// isSearching == false가 될 때까지 기다림 (Task defer 반영)
    private func waitSearchingStops(timeout: TimeInterval = 1.0, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "isSearching == false")
        output.isSearching$
            .distinctUntilChanged()
            .filter { $0 == false }
            .take(1)
            .subscribe(onNext: { _ in exp.fulfill() })
            .disposed(by: disposeBag)

        wait(for: [exp], timeout: timeout)
    }

    // MARK: - Tests

    func test_searchingMode_withNonEmptyKeyword_triggersGetPlaces_andUpdatesPlaces() {
        // given
        enqueueSuccess(count: 2, total: 40, page: 0, limit: 20)

        // when
        screenModeSubject.onNext(.searching)
        keywordSubject.onNext("  Jerusalem  ")

        // debounce 250ms 통과
        scheduler.advanceTo(300)

        // then (실제 상태 변화로 기다림)
        waitPlacesCount(2)
        waitSearchingStops()

        XCTAssertEqual(mockUsecase.listApiCall, 1)
        XCTAssertEqual(mockUsecase.lastGetPlacesParameters?.name, "Jerusalem")
        XCTAssertEqual(mockUsecase.lastGetPlacesParameters?.page, 0)
        XCTAssertEqual(mockUsecase.lastGetPlacesParameters?.limit, 20)
    }

    func test_searchingMode_withEmptyKeyword_resetsToIdle_andDoesNotCallUsecase() {
        // given
        // (usecase 응답은 넣지 않음)

        // when
        screenModeSubject.onNext(.searching)
        keywordSubject.onNext("   ")   // empty로 trim됨
        scheduler.advanceTo(300)

        // then: 호출 없음 + 결과 clear
        XCTAssertEqual(mockUsecase.listApiCall, 0)
        waitPlacesCount(0)
    }

    func test_homeMode_resetsToIdle_andClearsResults() {
        // given: 먼저 searching으로 데이터 만들어둠
        enqueueSuccess(count: 1)
        screenModeSubject.onNext(.searching)
        keywordSubject.onNext("AAA")
        scheduler.advanceTo(300)

        waitPlacesCount(1)
        waitSearchingStops()

        // when: home으로 전환
        screenModeSubject.onNext(.home)
        scheduler.advanceTo(400)

        // then: clear
        waitPlacesCount(0)
        XCTAssertEqual(mockUsecase.listApiCall, 1)
    }

    func test_searchReadyMode_resetsToIdle_andClearsResults() {
        // given: 먼저 searching으로 데이터 만들어둠
        enqueueSuccess(count: 1)
        screenModeSubject.onNext(.searching)
        keywordSubject.onNext("BBB")
        scheduler.advanceTo(300)

        waitPlacesCount(1)
        waitSearchingStops()

        // when: searchReady로 전환
        screenModeSubject.onNext(.searchReady)
        scheduler.advanceTo(400)

        // then: clear
        waitPlacesCount(0)
        XCTAssertEqual(mockUsecase.listApiCall, 1)
    }

    func test_bottomReached_inSearchingMode_fetchesNextPage_andAppends() {
        // given
        // 첫 페이지 20개, total 40 => hasMore true
        let first = (0..<20).map { Place.mock(id: "\($0)", name: "p\($0)") }
        mockUsecase.resultsQueue.append(.success(ListResponse(total: 40, page: 0, limit: 20, data: first)))

        // 두 번째 페이지 20개
        let second = (20..<40).map { Place.mock(id: "\($0)", name: "p\($0)") }
        mockUsecase.resultsQueue.append(.success(ListResponse(total: 40, page: 1, limit: 20, data: second)))

        // when: 최초 검색
        screenModeSubject.onNext(.searching)
        keywordSubject.onNext("Jericho")
        scheduler.advanceTo(300)

        waitPlacesCount(20)
        waitSearchingStops()
        XCTAssertEqual(mockUsecase.listApiCall, 1)

        // when: bottomReached (debounce 200ms)
        bottomReachedSubject.onNext(())
        scheduler.advanceTo(600)

        // then: append되어 40개
        waitPlacesCount(40)
        XCTAssertEqual(mockUsecase.listApiCall, 2)
        XCTAssertEqual(mockUsecase.lastGetPlacesParameters?.page, 1)
    }

    func test_bottomReached_whenNotSearching_doesNotFetchMore() {
        // given
        screenModeSubject.onNext(.searchReady)
        keywordSubject.onNext("ABC")
        scheduler.advanceTo(300)

        // when
        bottomReachedSubject.onNext(())
        scheduler.advanceTo(600)

        // then
        XCTAssertEqual(mockUsecase.listApiCall, 0)
    }

    func test_refetchButtonTapped_usesDebouncedKeyword_andCallsGetPlaces() {
        // given
        enqueueSuccess(count: 1)
        screenModeSubject.onNext(.searching)

        keywordSubject.onNext("  Galilee  ")
        scheduler.advanceTo(300) // debouncedKeyword 확정

        // when (refetch는 debouncedKeyword 기준)
        refetchSubject.onNext(())

        // then
        waitPlacesCount(1)
        waitSearchingStops()

        XCTAssertEqual(mockUsecase.listApiCall, 1)
        XCTAssertEqual(mockUsecase.lastGetPlacesParameters?.name, "Galilee")
    }

    func test_getPlacesFailure_emitsErrorToFetchPlaces() {
        // given
        enqueueFailure(.clientError("network fail"))

        let exp = expectation(description: "error emitted")
        var last: NetworkError?

        output.errorToFetchPlaces$
            .compactMap { $0 }
            .take(1)
            .subscribe(onNext: { err in
                last = err
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        screenModeSubject.onNext(.searching)
        keywordSubject.onNext("ErrorCase")
        scheduler.advanceTo(300)

        wait(for: [exp], timeout: 1.0)

        // then
        guard let last else { return XCTFail("Expected error") }
        if case .clientError(let message) = last {
            XCTAssertEqual(message, "network fail")
        } else {
            XCTFail("Expected .clientError")
        }
    }

    func test_placeCellSelected_whenSaveSuccess_presentsDetail() {
        // given
        mockRecentSearch.saveResultToReturn = .success(())
        let place = Place.mock(id: "123", name: "X")

        // when
        placeSelectedSubject.onNext(place)
        scheduler.advanceTo(1)   // ✅ observe(on:) flush

        // then
        XCTAssertEqual(mockRecentSearch.savedPlaces.count, 1)
        XCTAssertEqual(mockNavigator.presentedSheet, .placeDetail("123"))
    }


    func test_placeCellSelected_whenSaveFails_emitsError() {
        // given
        struct DummyError: LocalizedError {
            var errorDescription: String? { "fail" }
        }

        mockRecentSearch.saveResultToReturn = .failure(.saveFailed(DummyError()))
        let place = Place.mock(id: "123", name: "X")

        let exp = expectation(description: "save error emitted")
        var received: RecentSearchError?

        output.errorToSaveRecentSearch$
            .compactMap { $0 }
            .take(1)
            .subscribe(onNext: { err in
                received = err
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        placeSelectedSubject.onNext(place)
        scheduler.advanceTo(1)   // ✅ observe(on:) flush

        // then
        wait(for: [exp], timeout: 1.0)

        guard let received else { return XCTFail("Expected RecentSearchError") }
        if case .saveFailed(let err) = received {
            XCTAssertEqual(err.localizedDescription, "fail")
        } else {
            XCTFail("Expected .saveFailed")
        }
    }


    func test_debouncedKeyword_emitsTrimmedLastValue() {
        // given: 검색 트리거랑 섞이지 않게 searchReady로 고정
        screenModeSubject.onNext(.searchReady)

        let keywordObserver = scheduler.createObserver(String.self)
        output.debouncedKeyword$
            .subscribe(keywordObserver)
            .disposed(by: disposeBag)

        // when
        keywordSubject.onNext("  A ")
        scheduler.advanceTo(200)

        keywordSubject.onNext("  AB ")
        scheduler.advanceTo(600)

        // then
        let values = keywordObserver.events.compactMap { $0.value.element }
        XCTAssertTrue(values.allSatisfy { $0 == $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        XCTAssertEqual(values.last, "AB")
    }
}
