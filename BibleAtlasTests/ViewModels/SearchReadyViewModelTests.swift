//
//  SearchReadyViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/9/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas

final class SearchReadyViewModelTests: XCTestCase {

    private var mockPlaceUsecase: MockPlaceusecase!
    private var mockNavigator: MockBottomSheetNavigator!
    private var mockRecentSearchService: MockRecentSearchService!
    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!

    override func setUp() {
        super.setUp()

        disposeBag = DisposeBag()
        mockPlaceUsecase = MockPlaceusecase()
        mockNavigator = MockBottomSheetNavigator()
        mockRecentSearchService = MockRecentSearchService()
        scheduler = TestScheduler(initialClock: 0)
    }

    // MARK: - Popular places

    func test_viewLoaded_fetches_popularPlaces_success() throws {
        let viewModel = SearchReadyViewModel(
            navigator: mockNavigator,
            placeUsecase: mockPlaceUsecase,
            recentSearchService: nil
        )

        let mockPlaces = [
            Place(
                id: "12345",
                name: "test2",
                koreanName: "테스트2",
                isModern: true,
                description: "test2",
                koreanDescription: "테스트2",
                stereo: .child,
                likeCount: 2,
                types: []
            ),
            Place(
                id: "1234",
                name: "test",
                koreanName: "테스트2",
                isModern: true,
                description: "test",
                koreanDescription: "테스트",
                stereo: .child,
                likeCount: 1,
                types: []
            )
        ]

        let exp = expectation(description: "await finished")
        mockPlaceUsecase.completedExp = exp
        mockPlaceUsecase.resultToReturn = .success(
            ListResponse(total: 2, page: 0, limit: 10, data: mockPlaces)
        )

        let viewLoaded$ = PublishRelay<Void>()
        let output = viewModel.transform(input: .init(
            refetchButtonTapped$: .empty(),
            popularPlaceCellTapped$: .empty(),
            recentSearchCellTapped$: .empty(),
            viewLoaded$: viewLoaded$.asObservable(),
            moreRecentSearchesButtonTapped$: .empty(),
            morePopularPlacesButtonTapped$: .empty()
        ))

        let isFetchingObserver = scheduler.createObserver(Bool.self)
        output.isFetching$
            .observe(on: scheduler)
            .bind(to: isFetchingObserver)
            .disposed(by: disposeBag)

        let popularPlacesObserver = scheduler.createObserver([Place].self)
        output.popularPlaces$
            .observe(on: scheduler)
            .bind(to: popularPlacesObserver)
            .disposed(by: disposeBag)

        let errorObserver = scheduler.createObserver(NetworkError?.self)
        output.errorToFetchPlaces$
            .observe(on: scheduler)
            .bind(to: errorObserver)
            .disposed(by: disposeBag)

        // When
        viewLoaded$.accept(())
        // CI 에서 느릴 수 있으니 타임아웃을 넉넉히
        wait(for: [exp], timeout: 5.0)
        scheduler.start()

        // Then
        let isFetchingValues = isFetchingObserver.events.compactMap { $0.value.element }

        // 초기값 false, 중간에 최소 한 번 true, 마지막 false 패턴만 검증
        XCTAssertEqual(isFetchingValues.first, false)
        XCTAssertEqual(isFetchingValues.last, false)
        XCTAssertTrue(isFetchingValues.contains(true), "isFetchingValues: \(isFetchingValues)")

        let placesValues = popularPlacesObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(placesValues.last?.count, 2, "placesValues: \(placesValues)")

        let errorValues = errorObserver.events.compactMap { $0.value.element }
        XCTAssertNil(errorValues.last ?? nil, "errorValues: \(errorValues)")
    }

    func test_viewLoaded_sets_error_when_fetch_popularPlaces_fails() {
        let viewModel = SearchReadyViewModel(
            navigator: mockNavigator,
            placeUsecase: mockPlaceUsecase,
            recentSearchService: nil
        )

        let exp = expectation(description: "await finished")
        mockPlaceUsecase.completedExp = exp
        mockPlaceUsecase.resultToReturn = .failure(.clientError("test-error"))

        let viewLoaded$ = PublishRelay<Void>()
        let output = viewModel.transform(input: .init(
            refetchButtonTapped$: .empty(),
            popularPlaceCellTapped$: .empty(),
            recentSearchCellTapped$: .empty(),
            viewLoaded$: viewLoaded$.asObservable(),
            moreRecentSearchesButtonTapped$: .empty(),
            morePopularPlacesButtonTapped$: .empty()
        ))

        let isFetchingObserver = scheduler.createObserver(Bool.self)
        output.isFetching$
            .observe(on: scheduler)
            .bind(to: isFetchingObserver)
            .disposed(by: disposeBag)

        let popularPlacesObserver = scheduler.createObserver([Place].self)
        output.popularPlaces$
            .observe(on: scheduler)
            .bind(to: popularPlacesObserver)
            .disposed(by: disposeBag)

        let errorObserver = scheduler.createObserver(NetworkError?.self)
        output.errorToFetchPlaces$
            .observe(on: scheduler)
            .bind(to: errorObserver)
            .disposed(by: disposeBag)

        // When
        viewLoaded$.accept(())
        // 여기서도 타임아웃 여유 있게
        wait(for: [exp], timeout: 5.0)
        scheduler.start()

        // Then
        let isFetchingValues = isFetchingObserver.events.compactMap { $0.value.element }

        // 성공 케이스와 동일하게 "토글 패턴"만 검증
        XCTAssertEqual(isFetchingValues.first, false)
        XCTAssertEqual(isFetchingValues.last, false)
        XCTAssertTrue(isFetchingValues.contains(true), "isFetchingValues: \(isFetchingValues)")

        let placesValues = popularPlacesObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(placesValues.last?.count ?? 0, 0, "placesValues: \(placesValues)")

        let errorValues = errorObserver.events.compactMap { $0.value.element }
        XCTAssertNotNil(errorValues.last ?? nil, "errorValues: \(errorValues)")
    }

    // MARK: - Recent searches

    func test_init_loads_recentSearches_immediately() {

        mockRecentSearchService.resultToReturn = .success(
            RecentSearchFetchResult(
                items: [
                    RecentSearchItem(id: "test1", name: "test", koreanName: "테스트1", type: "test"),
                    RecentSearchItem(id: "test2", name: "test", koreanName: "테스트2", type: "test"),
                    RecentSearchItem(id: "test3", name: "test", koreanName: "테스트3", type: "test"),
                    RecentSearchItem(id: "test4", name: "test", koreanName: "테스트4", type: "test"),
                    RecentSearchItem(id: "test5", name: "test", koreanName: "테스트5", type: "test")
                ],
                total: 5,
                page: 0
            )
        )

        let viewModel = SearchReadyViewModel(
            navigator: mockNavigator,
            placeUsecase: mockPlaceUsecase,
            recentSearchService: mockRecentSearchService
        )

        let output = viewModel.transform(input: SearchReadyViewModel.Input(
            refetchButtonTapped$: .empty(),
            popularPlaceCellTapped$: .empty(),
            recentSearchCellTapped$: .empty(),
            viewLoaded$: .empty(),
            moreRecentSearchesButtonTapped$: .empty(),
            morePopularPlacesButtonTapped$: .empty()
        ))

        let recentSearchesObserver = scheduler.createObserver([RecentSearchItem].self)

        output.recentSearches$
            .observe(on: scheduler)
            .bind(to: recentSearchesObserver)
            .disposed(by: disposeBag)

        let errorToFetchRecentSearchesObserver = scheduler.createObserver(RecentSearchError?.self)

        output.errorToFetchRecentSearches$
            .observe(on: scheduler)
            .bind(to: errorToFetchRecentSearchesObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        let recentSearchesValues = recentSearchesObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(recentSearchesValues.last?.count, 5)

        let errorValues = errorToFetchRecentSearchesObserver.events.compactMap { $0.value.element }
        XCTAssertNil(errorValues.last ?? nil)
    }

    func test_recentSearchItems_sets_error_when_fetch_fails() {
        let dummyError = NSError(domain: "Test", code: 1)

        mockRecentSearchService.resultToReturn = .failure(.fetchFailed(dummyError))

        let viewModel = SearchReadyViewModel(
            navigator: mockNavigator,
            placeUsecase: mockPlaceUsecase,
            recentSearchService: mockRecentSearchService
        )

        let output = viewModel.transform(input: SearchReadyViewModel.Input(
            refetchButtonTapped$: .empty(),
            popularPlaceCellTapped$: .empty(),
            recentSearchCellTapped$: .empty(),
            viewLoaded$: .empty(),
            moreRecentSearchesButtonTapped$: .empty(),
            morePopularPlacesButtonTapped$: .empty()
        ))

        let recentSearchesObserver = scheduler.createObserver([RecentSearchItem].self)

        output.recentSearches$
            .observe(on: scheduler)
            .bind(to: recentSearchesObserver)
            .disposed(by: disposeBag)

        let errorToFetchRecentSearchesObserver = scheduler.createObserver(RecentSearchError?.self)

        output.errorToFetchRecentSearches$
            .observe(on: scheduler)
            .bind(to: errorToFetchRecentSearchesObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        let recentSearchesValues = recentSearchesObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(recentSearchesValues.last?.count ?? 0, 0)

        let errorValues = errorToFetchRecentSearchesObserver.events.compactMap { $0.value.element }
        XCTAssertNotNil(errorValues.last ?? nil)
    }

    // MARK: - Navigation

    func test_popularPlaceCellTapped_navigates_to_placeDetail() {

        let viewModel = SearchReadyViewModel(
            navigator: mockNavigator,
            placeUsecase: nil,
            recentSearchService: nil
        )

        let popularPlaceCellTapped$ = PublishRelay<String>()

        _ = viewModel.transform(input: SearchReadyViewModel.Input(
            refetchButtonTapped$: .empty(),
            popularPlaceCellTapped$: popularPlaceCellTapped$.asObservable(),
            recentSearchCellTapped$: .empty(),
            viewLoaded$: .empty(),
            moreRecentSearchesButtonTapped$: .empty(),
            morePopularPlacesButtonTapped$: .empty()
        ))

        popularPlaceCellTapped$.accept("test")
        XCTAssertEqual(mockNavigator.presentedSheet, .placeDetail("test"))
    }

    func test_recentSearchCellTapped_navigates_to_placeDetail() {

        let viewModel = SearchReadyViewModel(
            navigator: mockNavigator,
            placeUsecase: nil,
            recentSearchService: nil
        )

        let recentSearchCellTapped$ = PublishRelay<String>()

        _ = viewModel.transform(input: SearchReadyViewModel.Input(
            refetchButtonTapped$: .empty(),
            popularPlaceCellTapped$: .empty(),
            recentSearchCellTapped$: recentSearchCellTapped$.asObservable(),
            viewLoaded$: .empty(),
            moreRecentSearchesButtonTapped$: .empty(),
            morePopularPlacesButtonTapped$: .empty()
        ))

        recentSearchCellTapped$.accept("test")
        XCTAssertEqual(mockNavigator.presentedSheet, .placeDetail("test"))
    }
}
