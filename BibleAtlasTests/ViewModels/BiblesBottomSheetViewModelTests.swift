//
//  BiblesBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/9/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
@testable import BibleAtlas

final class BiblesBottomSheetViewModelTests: XCTestCase {

    private var disposeBag: DisposeBag!
    private var testScheduler: TestScheduler!

    private var mockNavigator: MockBottomSheetNavigator!
    private var mockPlaceUsecase: MockPlaceusecase!
    private var mockNotificationService: MockNotificationService!

    private var sut: BiblesBottomSheetViewModel!

    // Input subjects
    private var cellTappedSubject: PublishSubject<BibleBook>!
    private var closeButtonTappedSubject: PublishSubject<Void>!
    private var viewLoadedSubject: PublishSubject<Void>!
    private var refetchButtonTappedSubject: PublishSubject<Void>!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        testScheduler = TestScheduler(initialClock: 0)

        mockNavigator = MockBottomSheetNavigator()
        mockPlaceUsecase = MockPlaceusecase()
        mockNotificationService = MockNotificationService()

        sut = BiblesBottomSheetViewModel(
            navigator: mockNavigator,
            placeUsecase: mockPlaceUsecase,
            notificationService: mockNotificationService
        )

        cellTappedSubject = PublishSubject<BibleBook>()
        closeButtonTappedSubject = PublishSubject<Void>()
        viewLoadedSubject = PublishSubject<Void>()
        refetchButtonTappedSubject = PublishSubject<Void>()
    }

    override func tearDown() {
        sut = nil
        mockNavigator = nil
        mockPlaceUsecase = nil
        mockNotificationService = nil
        disposeBag = nil
        super.tearDown()
    }

    private func makeInputOutput() -> BiblesBottomSheetViewModel.Output {
        let input = BiblesBottomSheetViewModel.Input(
            cellTapped$: cellTappedSubject.asObservable(),
            closeButtonTapped$: closeButtonTappedSubject.asObservable(),
            viewLoaded$: viewLoadedSubject.asObservable(),
            refetchButtonTapped$: refetchButtonTappedSubject.asObservable()
        )

        return sut.transform(input: input)
    }

    // MARK: - Tests

    /// viewLoaded$ 가 들어오면 usecase에서 bibleBookCounts 를 가져와 스트림에 반영하고
    /// isInitialLoading$ 이 false 로 바뀌는지 확인
    func test_viewLoaded_fetchesBibleBookCounts_success() {
        // given
        let output = makeInputOutput()

        let bibleObserver = testScheduler.createObserver([BibleBookCount].self)
        let loadingObserver = testScheduler.createObserver(Bool.self)
        let errorObserver = testScheduler.createObserver(NetworkError?.self)

        output.bibleBookCounts$
            .subscribe(bibleObserver)
            .disposed(by: disposeBag)

        output.isInitialLoading$
            .subscribe(loadingObserver)
            .disposed(by: disposeBag)

        output.error$
            .subscribe(errorObserver)
            .disposed(by: disposeBag)

        // 더미 응답 데이터
        let dummyCounts = [
            BibleBookCount(bible: .Gen, placeCount: 3),
            BibleBookCount(bible: .Exod, placeCount: 5)
        ]

        let response = ListResponse(
            total: dummyCounts.count,
            page: 0,
            limit: dummyCounts.count,
            data: dummyCounts
        )

        mockPlaceUsecase.bibleBookCountsResult = .success(response)

        let fetchExp = expectation(description: "fetch bible book counts")

        // bibleBookCounts$ 가 한 번이라도 업데이트 되면 fulfill
        output.bibleBookCounts$
            .skip(1) // 초기 [] 스킵
            .take(1)
            .subscribe(onNext: { _ in
                fetchExp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        viewLoadedSubject.onNext(())

        wait(for: [fetchExp], timeout: 1.0)

        // then
        let bibleEvents = bibleObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(bibleEvents.last ?? [], dummyCounts)

        let loadingEvents = loadingObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(loadingEvents.first, true)          // 초기값
        XCTAssertEqual(loadingEvents.last, false)          // 로딩 끝났는지

        let errorEvents = errorObserver.events.compactMap { $0.value.element }
        XCTAssertNil(errorEvents.last ?? nil)
    }

    /// viewLoaded$ 에서 usecase 가 실패하면 error$ 에 값이 들어가고, 목록은 비어 있는지
    func test_viewLoaded_whenUsecaseFails_setsError() {
        // given
        let output = makeInputOutput()

        let bibleObserver = testScheduler.createObserver([BibleBookCount].self)
        let errorObserver = testScheduler.createObserver(NetworkError?.self)

        output.bibleBookCounts$
            .subscribe(bibleObserver)
            .disposed(by: disposeBag)

        output.error$
            .subscribe(errorObserver)
            .disposed(by: disposeBag)

        mockPlaceUsecase.bibleBookCountsResult = .failure(.clientError("test-error"))

        let exp = expectation(description: "fetch failed")
        output.error$
            .skip(1)
            .take(1)
            .subscribe(onNext: { _ in
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        viewLoadedSubject.onNext(())

        wait(for: [exp], timeout: 1.0)

        // then
        let errorEvents = errorObserver.events.compactMap { $0.value.element }
        guard case .clientError(let message)? = errorEvents.last ?? nil else {
            return XCTFail("Expected clientError, got \(String(describing: errorEvents.last ?? nil))")
        }
        XCTAssertEqual(message, "test-error")
    }

    /// refetchButtonTapped$ 가 들어오면 state 를 초기화하고 다시 fetch 하는지
    func test_refetchButtonTapped_resetsStateAndRefetches() {
        // given
        let output = makeInputOutput()

        let bibleObserver = testScheduler.createObserver([BibleBookCount].self)
        let loadingObserver = testScheduler.createObserver(Bool.self)
        let errorObserver = testScheduler.createObserver(NetworkError?.self)

        output.bibleBookCounts$
            .subscribe(bibleObserver)
            .disposed(by: disposeBag)

        output.isInitialLoading$
            .subscribe(loadingObserver)
            .disposed(by: disposeBag)

        output.error$
            .subscribe(errorObserver)
            .disposed(by: disposeBag)

        // 첫 응답
        let firstCounts = [
            BibleBookCount(bible: .Gen, placeCount: 1)
        ]
        let firstResponse = ListResponse(
            total: 1,
            page: 0,
            limit: 1,
            data: firstCounts
        )

        // 두 번째 응답
        let secondCounts = [
            BibleBookCount(bible: .Gen, placeCount: 2),
            BibleBookCount(bible: .Exod, placeCount: 3)
        ]
        let secondResponse = ListResponse(
            total: 2,
            page: 0,
            limit: 2,
            data: secondCounts
        )

        // 1차: viewLoaded 에 대한 성공
        mockPlaceUsecase.bibleBookCountsResult = .success(firstResponse)

        let firstFetchExp = expectation(description: "first fetch")
        output.bibleBookCounts$
            .skip(1)
            .take(1)
            .subscribe(onNext: { _ in
                firstFetchExp.fulfill()
            })
            .disposed(by: disposeBag)

        viewLoadedSubject.onNext(())

        wait(for: [firstFetchExp], timeout: 1.0)

        // 2차: refetch 에 대해 다른 응답 세팅
        mockPlaceUsecase.bibleBookCountsResult = .success(secondResponse)

        let refetchExp = expectation(description: "refetch")
        output.bibleBookCounts$
            .skip(2) // [](초기), firstCounts 이후 두 번째 emit
            .take(1)
            .subscribe(onNext: { _ in
                refetchExp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        refetchButtonTappedSubject.onNext(())

        wait(for: [refetchExp], timeout: 1.0)

        // then
        let bibleEvents = bibleObserver.events.compactMap { $0.value.element }
        XCTAssertEqual(bibleEvents.last ?? [], secondCounts)

        // 에러는 nil 이어야 함
        let errorEvents = errorObserver.events.compactMap { $0.value.element }
        XCTAssertNil(errorEvents.last ?? nil)
    }

    /// cellTapped$ -> navigator.present(.placesByBible)
    func test_cellTapped_presentsPlacesByBible() {
        // given
        _ = makeInputOutput()

        // when
        cellTappedSubject.onNext(.Gen)

        // then
        XCTAssertEqual(mockNavigator.presentedSheet, .placesByBible(.Gen))
    }

    /// closeButtonTapped$ -> navigator.dismiss
    func test_closeButtonTapped_dismissesBottomSheet() {
        // given
        _ = makeInputOutput()

        // when
        closeButtonTappedSubject.onNext(())

        // then
        XCTAssertTrue(mockNavigator.isDismissed)
    }

    /// notificationService 가 .forceMedium 을 보내면 forceMedium$ 에 이벤트가 전달되는지
    func test_sheetCommand_forceMedium_emitsOnForceMediumStream() {
        // given
        let output = makeInputOutput()

        let forceObserver = testScheduler.createObserver(Void.self)

        output.forceMedium$
            .subscribe(forceObserver)
            .disposed(by: disposeBag)

        // when
        mockNotificationService.post(.sheetCommand, object: SheetCommand.forceMedium)

        // then
        // 약간의 시간 흘려주기
        testScheduler.start()
        XCTAssertEqual(forceObserver.events.count, 1)
    }

    /// notificationService 가 .restoreDetents 를 보내면 restoreDetents$ 에 이벤트가 전달되는지
    func test_sheetCommand_restoreDetents_emitsOnRestoreDetentsStream() {
        // given
        let output = makeInputOutput()

        let restoreObserver = testScheduler.createObserver(Void.self)

        output.restoreDetents$
            .subscribe(restoreObserver)
            .disposed(by: disposeBag)

        // when
        mockNotificationService.post(.sheetCommand, object: SheetCommand.restoreDetents)

        // then
        testScheduler.start()
        XCTAssertEqual(restoreObserver.events.count, 1)
    }
}
