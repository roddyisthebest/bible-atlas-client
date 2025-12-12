//
//  PlacesByBibleBottomSheetViewModelTests.swift
//  BibleAtlasTests
//

import XCTest
import RxSwift
import RxRelay
import RxTest

@testable import BibleAtlas


final class PlacesByBibleBottomSheetViewModelTests: XCTestCase {

    private var sut: PlacesByBibleBottomSheetViewModel!
    private var mockNavigator: MockBottomSheetNavigator!
    private var mockPlaceUsecase: MockPlaceusecase!
    private var mockNotificationService: MockNotificationService!
    private var disposeBag: DisposeBag!

    // input subjects
    private var viewLoadedSubject: PublishSubject<Void>!
    private var closeButtonSubject: PublishSubject<Void>!
    private var placeCellTappedSubject: PublishSubject<String>!
    private var bottomReachedSubject: PublishSubject<Void>!
    private var refetchSubject: PublishSubject<Void>!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        mockNavigator = MockBottomSheetNavigator()
        mockPlaceUsecase = MockPlaceusecase()
        mockNotificationService = MockNotificationService()

        // 기본 sut (필요한 테스트마다 resultQueue만 갈아끼움)
        sut = PlacesByBibleBottomSheetViewModel(
            navigator: mockNavigator,
            bible: .Exod,
            placeUsecase: mockPlaceUsecase,
            notificationService: mockNotificationService
        )

        viewLoadedSubject = PublishSubject<Void>()
        closeButtonSubject = PublishSubject<Void>()
        placeCellTappedSubject = PublishSubject<String>()
        bottomReachedSubject = PublishSubject<Void>()
        refetchSubject = PublishSubject<Void>()
    }

    override func tearDown() {
        sut = nil
        mockNavigator = nil
        mockPlaceUsecase = nil
        mockNotificationService = nil
        disposeBag = nil
        super.tearDown()
    }

    private func makeOutput() -> PlacesByBibleBottomSheetViewModel.Output {
        let input = PlacesByBibleBottomSheetViewModel.Input(
            viewLoaded$: viewLoadedSubject.asObservable(),
            closeButtonTapped$: closeButtonSubject.asObservable(),
            placeCellTapped$: placeCellTappedSubject.asObservable(),
            bottomReached$: bottomReachedSubject.asObservable(),
            refetchButtonTapped$: refetchSubject.asObservable()
        )

        return sut.transform(input: input)
    }

    // MARK: - viewLoaded 첫 로딩

    func test_viewLoaded_fetchesFirstPageAndEmitsPlaces() {
        // given
        let places = (1...3).map { Place.mock(id: "\($0)", name: "Place\($0)") }
        let listResponse = ListResponse(total: 3, page: 0, limit: 10, data: places)
        mockPlaceUsecase.resultsQueue = [.success(listResponse)]

        let output = makeOutput()

        let placesExp = expectation(description: "places emitted after fetch")
        var latestPlaces: [Place] = []

        output.places$
            .skip(1) // BehaviorRelay 초기 [] 는 스킵
            .subscribe(onNext: { value in
                latestPlaces = value
                placesExp.fulfill()
            })
            .disposed(by: disposeBag)

        let loadingExp = expectation(description: "initial loading becomes false")
        var finalIsLoading: Bool?

        output.isInitialLoading$
            .subscribe(onNext: { value in
                finalIsLoading = value
                if value == false {
                    loadingExp.fulfill()
                }
            })
            .disposed(by: disposeBag)

        // when
        viewLoadedSubject.onNext(())

        // then
        wait(for: [placesExp, loadingExp], timeout: 1.0)
        XCTAssertEqual(latestPlaces.count, 3)
        XCTAssertEqual(latestPlaces.map { $0.id }, ["1", "2", "3"])
        XCTAssertEqual(finalIsLoading, false)
        XCTAssertEqual(mockPlaceUsecase.listApiCall, 1)
        XCTAssertEqual(mockPlaceUsecase.lastGetPlacesParameters?.bible, .Exod)
    }

    func test_viewLoaded_failureEmitsErrorAndKeepsEmptyPlaces() {
        // given
        mockPlaceUsecase.resultsQueue = [.failure(.serverError(500))]

        let output = makeOutput()

        let errorExp = expectation(description: "error emitted")
        var receivedError: NetworkError?

        output.error$
            .skip(1)
            .subscribe(onNext: { error in
                receivedError = error
                if error != nil {
                    errorExp.fulfill()
                }
            })
            .disposed(by: disposeBag)

        // places 는 여전히 빈 배열이어야 함
        var latestPlaces: [Place] = []
        output.places$
            .subscribe(onNext: { latestPlaces = $0 })
            .disposed(by: disposeBag)

        // when
        viewLoadedSubject.onNext(())

        // then
        wait(for: [errorExp], timeout: 1.0)
        XCTAssertNotNil(receivedError)
        XCTAssertTrue(latestPlaces.isEmpty)
    }

    // MARK: - pagination (bottomReached)

    func test_bottomReached_fetchesNextPageWhenHasMore() {
        // given
        let firstPage = ListResponse(
            total: 20,           // ✅ pageSize(10) 보다 크게
            page: 0,
            limit: 10,
            data: (1...10).map { Place.mock(id: "\($0)", name: "P\($0)") }
        )

        let secondPage = ListResponse(
            total: 20,
            page: 1,
            limit: 10,
            data: (11...20).map { Place.mock(id: "\($0)", name: "P\($0)") }
        )

        mockPlaceUsecase.resultsQueue = [.success(firstPage), .success(secondPage)]

        let output = makeOutput()

        let placesExp = expectation(description: "combined 2 pages emitted")

        var latestPlaces: [Place] = []
        output.places$
            .skip(1) // 초기 [] 스킵
            .subscribe(onNext: { value in
                latestPlaces = value
                if value.count == 20 {
                    placesExp.fulfill()
                }
            })
            .disposed(by: disposeBag)

        // when
        viewLoadedSubject.onNext(())     // 1번째 호출
        bottomReachedSubject.onNext(())  // 2번째 호출 트리거

        // then
        wait(for: [placesExp], timeout: 1.0)

        XCTAssertEqual(mockPlaceUsecase.listApiCall, 2)          // ✅ 2번 호출되었는지
        XCTAssertEqual(latestPlaces.count, 20)
        XCTAssertEqual(latestPlaces.first?.id, "1")
        XCTAssertEqual(latestPlaces.last?.id, "20")
    }

    func test_bottomReached_doesNotFetchWhenNoMore() {
        // given: total 이 pageSize 이하이면 hasMore == false 로 동작하는 Pagination 구현을 가정
        let onlyPage = ListResponse(
            total: 2,
            page: 0,
            limit: 10,
            data: [
                Place.mock(id: "1", name: "P1"),
                Place.mock(id: "2", name: "P2"),
            ]
        )
        mockPlaceUsecase.resultsQueue = [.success(onlyPage)]

        let output = makeOutput()

        let firstCallExp = expectation(description: "first getPlaces")
        mockPlaceUsecase.onGetPlacesReturn = { index, _ in
            if index == 1 { firstCallExp.fulfill() }
        }

        viewLoadedSubject.onNext(())
        wait(for: [firstCallExp], timeout: 1.0)

        // when: 더 이상 가져올 게 없는데 bottomReached 여러 번 호출
        bottomReachedSubject.onNext(())
        bottomReachedSubject.onNext(())

        // then: 여전히 1회 호출이어야 함
        // (Pagination.hasMore 에 따라 실제 구현에 의존하지만, 현재 구조 기대값)
        XCTAssertEqual(mockPlaceUsecase.listApiCall, 1)

        var latestPlaces: [Place] = []
        output.places$
            .subscribe(onNext: { latestPlaces = $0 })
            .disposed(by: disposeBag)

        XCTAssertEqual(latestPlaces.count, 2)
    }

    // MARK: - placeCellTapped & navigation

    func test_placeCellTapped_presentsPlaceDetail() {
        // given
        let output = makeOutput()

        _ = output // unused 경고 방지

        // when
        placeCellTappedSubject.onNext("place-123")

        // then
        guard case let .placeDetail(id)? = mockNavigator.presentedSheet else {
            return XCTFail("Expected .placeDetail route")
        }
        XCTAssertEqual(id, "place-123")
    }

    // MARK: - refetch

    func test_refetch_resetsAndFetchesAgain() {
        // given
        let firstPage = ListResponse(
            total: 2,
            page: 0,
            limit: 10,
            data: [
                Place.mock(id: "1", name: "P1"),
                Place.mock(id: "2", name: "P2"),
            ]
        )
        let secondPage = ListResponse(
            total: 1,
            page: 0,
            limit: 10,
            data: [
                Place.mock(id: "10", name: "New1"),
            ]
        )

        mockPlaceUsecase.resultsQueue = [.success(firstPage), .success(secondPage)]

        let output = makeOutput()

        let firstCallExp = expectation(description: "first fetch")
        let secondCallExp = expectation(description: "second fetch (refetch)")

        mockPlaceUsecase.onGetPlacesReturn = { index, _ in
            if index == 1 { firstCallExp.fulfill() }
            if index == 2 { secondCallExp.fulfill() }
        }

        var latestPlaces: [Place] = []
        let placesExp = expectation(description: "places after refetch")

        output.places$
            .skip(1)
            .subscribe(onNext: { value in
                latestPlaces = value
                if value.count == 1 && value.first?.id == "10" {
                    placesExp.fulfill()
                }
            })
            .disposed(by: disposeBag)

        // when
        viewLoadedSubject.onNext(())
        wait(for: [firstCallExp], timeout: 1.0)

        refetchSubject.onNext(())

        // then
        wait(for: [secondCallExp, placesExp], timeout: 1.0)
        XCTAssertEqual(mockPlaceUsecase.listApiCall, 2)
        XCTAssertEqual(latestPlaces.map { $0.id }, ["10"])
    }

    // MARK: - close button

    func test_closeButtonTapped_dismissesNavigator() {
        // given
        _ = makeOutput()

        // when
        closeButtonSubject.onNext(())

        // then
        XCTAssertTrue(mockNavigator.isDismissed)
    }

    // MARK: - notificationService (forceMedium / restoreDetents)

    func test_notificationService_forceMediumAndRestoreDetentsEmit() {
        // given
        let output = makeOutput()

        let forceExp = expectation(description: "forceMedium emitted")
        let restoreExp = expectation(description: "restoreDetents emitted")

        var forceCount = 0
        var restoreCount = 0

        output.forceMedium$
            .subscribe(onNext: {
                forceCount += 1
                forceExp.fulfill()
            })
            .disposed(by: disposeBag)

        output.restoreDetents$
            .subscribe(onNext: {
                restoreCount += 1
                restoreExp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        mockNotificationService.post(.sheetCommand, object: SheetCommand.forceMedium)
        mockNotificationService.post(.sheetCommand, object: SheetCommand.restoreDetents)

        // then
        wait(for: [forceExp, restoreExp], timeout: 1.0)
        XCTAssertEqual(forceCount, 1)
        XCTAssertEqual(restoreCount, 1)
    }

    // MARK: - bible$ 초기값

    func test_bibleObservable_emitsInitialBible() {
        // given
        let output = makeOutput()
        let bibleExp = expectation(description: "bible emitted")
        var receivedBible: BibleBook?

        // when
        output.bible$
            .subscribe(onNext: { bible in
                receivedBible = bible
                bibleExp.fulfill()
            })
            .disposed(by: disposeBag)

        // then
        wait(for: [bibleExp], timeout: 0.5)
        XCTAssertEqual(receivedBible, .Exod)
    }
}
