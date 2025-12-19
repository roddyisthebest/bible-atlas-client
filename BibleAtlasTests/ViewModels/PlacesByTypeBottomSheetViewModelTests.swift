//
//  PlacesByTypeBottomSheetViewModelTests.swift
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

final class PlacesByTypeBottomSheetViewModelTests: XCTestCase {

    private var disposeBag: DisposeBag!

    private var mockNavigator: MockBottomSheetNavigator!
    private var mockPlaceUsecase: MockPlaceusecase!
    private var mockNotificationService: MockNotificationService!

    private var sut: PlacesByTypeBottomSheetViewModel!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()

        mockNavigator = MockBottomSheetNavigator()
        mockPlaceUsecase = MockPlaceusecase()
        mockNotificationService = MockNotificationService()

        sut = PlacesByTypeBottomSheetViewModel(
            navigator: mockNavigator,
            placeUsecase: mockPlaceUsecase,
            placeTypeName: .river,                 // 존재하는 타입이라고 가정
            notificationService: mockNotificationService
        )
    }

    override func tearDown() {
        sut = nil
        mockNavigator = nil
        mockPlaceUsecase = nil
        mockNotificationService = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - Initial load (getInitialPlaces)

    func test_viewLoaded_fetchesInitialPlaces_success() {
        // given
        let mockPlaces = [
            Place(id: "1", name: "Place1", koreanName: "장소1",
                  isModern: true, description: "desc1", koreanDescription: "설명1",
                  stereo: .child, likeCount: 0, types: []),
            Place(id: "2", name: "Place2", koreanName: "장소2",
                  isModern: true, description: "desc2", koreanDescription: "설명2",
                  stereo: .child, likeCount: 0, types: [])
        ]

        mockPlaceUsecase.resultToReturn = .success(
            ListResponse(total: 30, page: 0, limit: 10, data: mockPlaces)
        )

        let viewLoaded$ = PublishSubject<Void>()
        let placeCellTapped$ = PublishSubject<String>()
        let closeButtonTapped$ = PublishSubject<Void>()
        let bottomReached$ = PublishSubject<Void>()
        let refetchButtonTapped$ = PublishSubject<Void>()

        let input = PlacesByTypeBottomSheetViewModel.Input(
            viewLoaded$: viewLoaded$.asObservable(),
            placeCellTapped$: placeCellTapped$.asObservable(),
            closeButtonTapped$: closeButtonTapped$.asObservable(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: refetchButtonTapped$.asObservable()
        )

        let output = sut.transform(input: input)

        var loadingStates: [Bool] = []
        var lastPlaces: [Place] = []
        var lastError: NetworkError?

        let loadingExp = expectation(description: "initial loading finished")

        output.isInitialLoading$
            .subscribe(onNext: { value in
                loadingStates.append(value)
                if value == false {
                    loadingExp.fulfill()
                }
            })
            .disposed(by: disposeBag)

        output.places$
            .subscribe(onNext: { places in
                lastPlaces = places
            })
            .disposed(by: disposeBag)

        output.error$
            .subscribe(onNext: { error in
                lastError = error
            })
            .disposed(by: disposeBag)

        // when
        viewLoaded$.onNext(())

        // then
        wait(for: [loadingExp], timeout: 1.0)

        // 초기값 true, fetch 끝나면 false
        XCTAssertEqual(loadingStates.first, true)
        XCTAssertEqual(loadingStates.last, false)

        XCTAssertEqual(lastPlaces.count, 2)
        XCTAssertNil(lastError)
    }

    func test_viewLoaded_setsError_whenInitialFetchFails() {
        // given
        mockPlaceUsecase.resultToReturn = .failure(.clientError("test-error"))

        let viewLoaded$ = PublishSubject<Void>()
        let placeCellTapped$ = PublishSubject<String>()
        let closeButtonTapped$ = PublishSubject<Void>()
        let bottomReached$ = PublishSubject<Void>()
        let refetchButtonTapped$ = PublishSubject<Void>()

        let input = PlacesByTypeBottomSheetViewModel.Input(
            viewLoaded$: viewLoaded$.asObservable(),
            placeCellTapped$: placeCellTapped$.asObservable(),
            closeButtonTapped$: closeButtonTapped$.asObservable(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: refetchButtonTapped$.asObservable()
        )

        let output = sut.transform(input: input)

        var loadingStates: [Bool] = []
        var lastPlaces: [Place] = []
        var lastError: NetworkError?

        let loadingExp = expectation(description: "initial loading finished with error")

        output.isInitialLoading$
            .subscribe(onNext: { value in
                loadingStates.append(value)
                if value == false {
                    loadingExp.fulfill()
                }
            })
            .disposed(by: disposeBag)

        output.places$
            .subscribe(onNext: { places in
                lastPlaces = places
            })
            .disposed(by: disposeBag)

        output.error$
            .subscribe(onNext: { error in
                lastError = error
            })
            .disposed(by: disposeBag)

        // when
        viewLoaded$.onNext(())

        // then
        wait(for: [loadingExp], timeout: 1.0)

        XCTAssertEqual(loadingStates.first, true)
        XCTAssertEqual(loadingStates.last, false)

        XCTAssertEqual(lastPlaces.count, 0)
        XCTAssertNotNil(lastError)
    }

    // MARK: - Pagination (getMorePlaces)
    func test_bottomReached_fetchesNextPage_success() {
        // given: 첫 페이지
        let firstPagePlaces = [
            Place(id: "1", name: "P1", koreanName: "장소1",
                  isModern: true, description: "d1", koreanDescription: "s1",
                  stereo: .child, likeCount: 0, types: []),
        ]

        let secondPagePlaces = [
            Place(id: "2", name: "P2", koreanName: "장소2",
                  isModern: true, description: "d2", koreanDescription: "s2",
                  stereo: .child, likeCount: 0, types: []),
            Place(id: "3", name: "P3", koreanName: "장소3",
                  isModern: true, description: "d3", koreanDescription: "s3",
                  stereo: .child, likeCount: 0, types: [])
        ]

        let viewLoaded$ = PublishSubject<Void>()
        let placeCellTapped$ = PublishSubject<String>()
        let closeButtonTapped$ = PublishSubject<Void>()
        let bottomReached$ = PublishSubject<Void>()
        let refetchButtonTapped$ = PublishSubject<Void>()

        let input = PlacesByTypeBottomSheetViewModel.Input(
            viewLoaded$: viewLoaded$.asObservable(),
            placeCellTapped$: placeCellTapped$.asObservable(),
            closeButtonTapped$: closeButtonTapped$.asObservable(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: refetchButtonTapped$.asObservable()
        )

        let output = sut.transform(input: input)

        var lastPlaces: [Place] = []
        var emissionCount = 0

        let paginationExp = expectation(description: "pagination finished (count == 3)")

        output.places$
            .skip(1) // 초기 [] 건너뛰기
            .subscribe(onNext: { [weak self] places in
                guard let self = self else { return }
                emissionCount += 1
                print("emission \(emissionCount):", places.map { $0.name })
                lastPlaces = places

                if emissionCount == 1 {
                    // ✅ 첫 페이지가 실제로 흘러온 이후에
                    //    두 번째 페이지 result를 셋업하고 bottomReached 트리거
                    self.mockPlaceUsecase.resultToReturn = .success(
                        ListResponse(total: 30, page: 1, limit: 10, data: secondPagePlaces)
                    )
                    bottomReached$.onNext(())
                } else if emissionCount == 2 {
                    paginationExp.fulfill()
                }
            })
            .disposed(by: disposeBag)

        // 1) 첫 페이지 로드용 result 셋업 후 viewLoaded 트리거
        mockPlaceUsecase.resultToReturn = .success(
            ListResponse(total: 30, page: 0, limit: 10, data: firstPagePlaces)
        )
        viewLoaded$.onNext(())

        // then
        wait(for: [paginationExp], timeout: 1.0)
        XCTAssertEqual(emissionCount, 2)
        XCTAssertEqual(lastPlaces.count, 3)
    }


    // MARK: - Navigation & close

    func test_placeCellTapped_navigatesToPlaceDetail() {
        // given
        let viewLoaded$ = PublishSubject<Void>()
        let placeCellTapped$ = PublishSubject<String>()
        let closeButtonTapped$ = PublishSubject<Void>()
        let bottomReached$ = PublishSubject<Void>()
        let refetchButtonTapped$ = PublishSubject<Void>()

        let input = PlacesByTypeBottomSheetViewModel.Input(
            viewLoaded$: viewLoaded$.asObservable(),
            placeCellTapped$: placeCellTapped$.asObservable(),
            closeButtonTapped$: closeButtonTapped$.asObservable(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: refetchButtonTapped$.asObservable()
        )

        _ = sut.transform(input: input)

        // when
        placeCellTapped$.onNext("place-id-123")

        // then (동기 처리라 wait 불필요)
        XCTAssertEqual(mockNavigator.presentedSheet, .placeDetail("place-id-123"))
    }

    func test_closeButtonTapped_dismissesSheet() {
        // given
        let viewLoaded$ = PublishSubject<Void>()
        let placeCellTapped$ = PublishSubject<String>()
        let closeButtonTapped$ = PublishSubject<Void>()
        let bottomReached$ = PublishSubject<Void>()
        let refetchButtonTapped$ = PublishSubject<Void>()

        let input = PlacesByTypeBottomSheetViewModel.Input(
            viewLoaded$: viewLoaded$.asObservable(),
            placeCellTapped$: placeCellTapped$.asObservable(),
            closeButtonTapped$: closeButtonTapped$.asObservable(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: refetchButtonTapped$.asObservable()
        )

        _ = sut.transform(input: input)

        // when
        closeButtonTapped$.onNext(())

        // then
        XCTAssertTrue(mockNavigator.isDismissed)
    }

    // MARK: - bindNotificationService (forceMedium / restoreDetents)

    func test_notification_forceMedium_emits_forceMedium$() {
        // given
        let viewLoaded$ = PublishSubject<Void>()
        let placeCellTapped$ = PublishSubject<String>()
        let closeButtonTapped$ = PublishSubject<Void>()
        let bottomReached$ = PublishSubject<Void>()
        let refetchButtonTapped$ = PublishSubject<Void>()

        let input = PlacesByTypeBottomSheetViewModel.Input(
            viewLoaded$: viewLoaded$.asObservable(),
            placeCellTapped$: placeCellTapped$.asObservable(),
            closeButtonTapped$: closeButtonTapped$.asObservable(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: refetchButtonTapped$.asObservable()
        )

        let output = sut.transform(input: input)

        let exp = expectation(description: "forceMedium emitted")

        output.forceMedium$
            .take(1)
            .subscribe(onNext: { _ in
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        mockNotificationService.emit(.sheetCommand, object: SheetCommand.forceMedium)

        // then
        wait(for: [exp], timeout: 1.0)
    }

    func test_notification_restoreDetents_emits_restoreDetents$() {
        // given
        let viewLoaded$ = PublishSubject<Void>()
        let placeCellTapped$ = PublishSubject<String>()
        let closeButtonTapped$ = PublishSubject<Void>()
        let bottomReached$ = PublishSubject<Void>()
        let refetchButtonTapped$ = PublishSubject<Void>()

        let input = PlacesByTypeBottomSheetViewModel.Input(
            viewLoaded$: viewLoaded$.asObservable(),
            placeCellTapped$: placeCellTapped$.asObservable(),
            closeButtonTapped$: closeButtonTapped$.asObservable(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: refetchButtonTapped$.asObservable()
        )

        let output = sut.transform(input: input)

        let exp = expectation(description: "restoreDetents emitted")

        output.restoreDetents$
            .take(1)
            .subscribe(onNext: { _ in
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        mockNotificationService.emit(.sheetCommand, object: SheetCommand.restoreDetents)

        // then
        wait(for: [exp], timeout: 1.0)
    }
}
