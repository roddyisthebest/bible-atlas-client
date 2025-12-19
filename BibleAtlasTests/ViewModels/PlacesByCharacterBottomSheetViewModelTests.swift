//
//  PlacesByCharacterBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas

final class PlacesByCharacterBottomSheetViewModelTests: XCTestCase {

    private var navigator: MockBottomSheetNavigator!
    private var placeUsecase: MockPlaceusecase!
    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!

    // 공통으로 돌려쓸 Place 더미
    private let dummyPlaces: [Place] = [
        Place(
            id: "1",
            name: "Place1",
            koreanName: "플레이스1",
            isModern: true,
            description: "desc1",
            koreanDescription: "설명1",
            stereo: .child,
            likeCount: 0,
            types: []
        ),
        Place(
            id: "2",
            name: "Place2",
            koreanName: "플레이스2",
            isModern: true,
            description: "desc2",
            koreanDescription: "설명2",
            stereo: .child,
            likeCount: 0,
            types: []
        )
    ]

    override func setUp() {
        super.setUp()
        navigator = MockBottomSheetNavigator()
        placeUsecase = MockPlaceusecase()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }

    override func tearDown() {
        scheduler = nil
        disposeBag = nil
        placeUsecase = nil
        navigator = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeViewModel(character: String = "A") -> PlacesByCharacterBottomSheetViewModel {
        return PlacesByCharacterBottomSheetViewModel(
            navigator: navigator,
            character: character,
            placeUsecase: placeUsecase,
            notificationService: nil
        )
    }

    private func makeInput(
        viewLoaded$: Observable<Void> = .empty(),
        closeButtonTapped$: Observable<Void> = .empty(),
        placeCellTapped$: Observable<String> = .empty(),
        bottomReached$: Observable<Void> = .empty(),
        refetchButtonTapped$: Observable<Void> = .empty()
    ) -> PlacesByCharacterBottomSheetViewModel.Input {
        return .init(
            viewLoaded$: viewLoaded$,
            closeButtonTapped$: closeButtonTapped$,
            placeCellTapped$: placeCellTapped$,
            bottomReached$: bottomReached$,
            refetchButtonTapped$: refetchButtonTapped$
        )
    }

    // MARK: - viewLoaded: 성공

    func test_viewLoaded_success_setsPlaces_andStopsInitialLoading_andClearsError() {
        // given
        let vm = makeViewModel(character: "T")

        // SearchReadyViewModelTests에서 쓰던 패턴과 동일하게 사용 중이라 가정
        let exp = expectation(description: "await finished")
        placeUsecase.completedExp = exp
        placeUsecase.resultToReturn = .success(
            ListResponse(
                total: 20,
                page: 0,
                limit: 10,
                data: dummyPlaces
            )
        )

        let viewLoadedRelay = PublishRelay<Void>()
        let input = makeInput(
            viewLoaded$: viewLoadedRelay.asObservable()
        )
        let output = vm.transform(input: input)

        let placesObserver = scheduler.createObserver([Place].self)
        output.places$
            .observe(on: scheduler)
            .bind(to: placesObserver)
            .disposed(by: disposeBag)

        let loadingObserver = scheduler.createObserver(Bool.self)
        output.isInitialLoading$
            .observe(on: scheduler)
            .bind(to: loadingObserver)
            .disposed(by: disposeBag)

        let errorObserver = scheduler.createObserver(NetworkError?.self)
        output.error$
            .observe(on: scheduler)
            .bind(to: errorObserver)
            .disposed(by: disposeBag)

        // when
        viewLoadedRelay.accept(())
        wait(for: [exp], timeout: 1.0)
        scheduler.start()

        // then
        let placesValues = placesObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(placesValues.last?.count, dummyPlaces.count)

        let loadingValues = loadingObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(loadingValues.last, false, "초기 로딩은 마지막에 false가 되어야 함")

        let errorValues = errorObserver.events.compactMap { $0.value.element }
        XCTAssertNil(errorValues.last ?? nil, "성공 시 error는 nil이어야 함")
    }

    // MARK: - viewLoaded: 실패

    func test_viewLoaded_failure_setsError_andStopsInitialLoading_keepsPlacesEmpty() {
        // given
        let vm = makeViewModel(character: "T")

        let exp = expectation(description: "await finished")
        placeUsecase.completedExp = exp
        placeUsecase.resultToReturn = .failure(.clientError("test-error"))

        let viewLoadedRelay = PublishRelay<Void>()
        let input = makeInput(
            viewLoaded$: viewLoadedRelay.asObservable()
        )
        let output = vm.transform(input: input)

        let placesObserver = scheduler.createObserver([Place].self)
        output.places$
            .observe(on: scheduler)
            .bind(to: placesObserver)
            .disposed(by: disposeBag)

        let loadingObserver = scheduler.createObserver(Bool.self)
        output.isInitialLoading$
            .observe(on: scheduler)
            .bind(to: loadingObserver)
            .disposed(by: disposeBag)

        let errorObserver = scheduler.createObserver(NetworkError?.self)
        output.error$
            .observe(on: scheduler)
            .bind(to: errorObserver)
            .disposed(by: disposeBag)

        // when
        viewLoadedRelay.accept(())
        wait(for: [exp], timeout: 1.0)
        scheduler.start()

        // then
        let placesValues = placesObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(placesValues.last?.count ?? 0, 0, "실패 시 places는 비어 있어야 함")

        let loadingValues = loadingObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(loadingValues.last, false, "로딩 플래그는 false로 끝나야 함")

        let errorValues = errorObserver.events.compactMap { $0.value.element }
        XCTAssertNotNil(errorValues.last ?? nil, "실패 시 error가 세팅되어야 함")
    }

    // MARK: - bottomReached: 다음 페이지 로드

    func test_bottomReached_success_appendsNextPage_andTogglesFetchingNext() {
        // given
        let vm = makeViewModel(character: "T")

        // 첫 번째/두 번째 호출 모두 같은 dummy 데이터 반환해도
        // append 되기 때문에 총 개수가 4개가 되는 것을 볼 수 있음
        let exp = expectation(description: "two requests finished")
        exp.expectedFulfillmentCount = 2
        placeUsecase.completedExp = exp
        placeUsecase.resultToReturn = .success(
            ListResponse(
                total: 20,      // pageSize 10, total 20 → hasMore = true
                page: 0,
                limit: 10,
                data: [dummyPlaces[0], dummyPlaces[1]]
            )
        )

        let viewLoadedRelay = PublishRelay<Void>()
        let bottomReachedRelay = PublishRelay<Void>()

        let input = makeInput(
            viewLoaded$: viewLoadedRelay.asObservable(),
            bottomReached$: bottomReachedRelay.asObservable()
        )
        let output = vm.transform(input: input)

        let placesObserver = scheduler.createObserver([Place].self)
        output.places$
            .observe(on: scheduler)
            .bind(to: placesObserver)
            .disposed(by: disposeBag)

        let fetchingObserver = scheduler.createObserver(Bool.self)
        output.isFetchingNext$
            .observe(on: scheduler)
            .bind(to: fetchingObserver)
            .disposed(by: disposeBag)

        // when
        viewLoadedRelay.accept(())
        bottomReachedRelay.accept(())

        wait(for: [exp], timeout: 1.0)
        scheduler.start()

        // then
        let placesValues = placesObserver.events.compactMap { $0.value.element }
        // 첫 요청 2개 + 다음 페이지 2개 = 4개
        XCTAssertEqual(placesValues.last?.count, 4)

        let fetchingValues = fetchingObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(fetchingValues.last, false, "마지막에는 isFetchingNext가 false로 끝나야 함")
        XCTAssertTrue(fetchingValues.contains(true), "페이징 중에는 true가 한 번은 나와야 함")
    }

    // MARK: - refetch: 에러/리스트 초기화 후 다시 로드

    func test_refetch_resetsPagination_clearsError_andReloadsPlaces() {
        // given
        let vm = makeViewModel(character: "T")

        let exp = expectation(description: "two requests finished")
        exp.expectedFulfillmentCount = 2
        placeUsecase.completedExp = exp

        // 1차 호출: 실패 → error 세팅
        placeUsecase.resultToReturn = .failure(.clientError("first-error"))

        let viewLoadedRelay = PublishRelay<Void>()
        let refetchRelay = PublishRelay<Void>()

        let input = makeInput(
            viewLoaded$: viewLoadedRelay.asObservable(),
            refetchButtonTapped$: refetchRelay.asObservable()
        )
        let output = vm.transform(input: input)

        let placesObserver = scheduler.createObserver([Place].self)
        output.places$
            .observe(on: scheduler)
            .bind(to: placesObserver)
            .disposed(by: disposeBag)

        let errorObserver = scheduler.createObserver(NetworkError?.self)
        output.error$
            .observe(on: scheduler)
            .bind(to: errorObserver)
            .disposed(by: disposeBag)

        // when - 첫 요청 (실패)
        viewLoadedRelay.accept(())

        // 두 번째 요청 전, 성공 값으로 변경
        placeUsecase.resultToReturn = .success(
            ListResponse(
                total: 2,
                page: 0,
                limit: 10,
                data: dummyPlaces
            )
        )
        // refetch
        refetchRelay.accept(())

        wait(for: [exp], timeout: 1.0)
        scheduler.start()

        // then
        let placesValues = placesObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(placesValues.last?.count, dummyPlaces.count, "refetch 이후에는 places가 다시 세팅되어야 함")

        let errorValues = errorObserver.events.compactMap { $0.value.element }
        XCTAssertNil(errorValues.last ?? nil, "refetch 성공 후에는 error가 nil이어야 함")
    }

    // MARK: - placeCellTapped → navigator.present(.placeDetail)

    func test_placeCellTapped_presentsPlaceDetail() {
        // given
        let vm = makeViewModel(character: "T")

        let placeCellTappedRelay = PublishRelay<String>()
        let input = makeInput(
            placeCellTapped$: placeCellTappedRelay.asObservable()
        )

        _ = vm.transform(input: input)

        // when
        placeCellTappedRelay.accept("place-id-123")

        // then
        XCTAssertEqual(navigator.presentedSheet, .placeDetail("place-id-123"))
    }

    // MARK: - closeButtonTapped → navigator.dismiss

    func test_closeButtonTapped_dismissesNavigator() {
        // given
        let vm = makeViewModel(character: "T")

        let closeRelay = PublishRelay<Void>()
        let input = makeInput(
            closeButtonTapped$: closeRelay.asObservable()
        )

        _ = vm.transform(input: input)

        // when
        closeRelay.accept(())

        // then
        XCTAssertTrue(navigator.isDismissed)
    }
}
