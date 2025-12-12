//
//  MyCollectionBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/13/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas


final class MyCollectionBottomSheetViewModelTests: XCTestCase{
    
    private var navigator:BottomSheetNavigator!
    private var filter:PlaceFilter!
    private var userUsecase:MockUserUsecase!
    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!
    private var notificationService: MockNotificationService!

    override func setUp(){
        super.setUp()
        disposeBag = DisposeBag();
        filter = .like
        userUsecase = MockUserUsecase();
        navigator = MockBottomSheetNavigator();
        scheduler = TestScheduler(initialClock: 0)
        notificationService = MockNotificationService();
    }
    
    func test_initialLoad_success_setsPlaces_andUpdatesPagination() throws {
        // given
        let places = [Place(id: "123", name: "test", koreanName: "장소이름", isModern: true, description: "test",
                            koreanDescription: "test", stereo: .child, likeCount: 1, types: [])]
        userUsecase.placesResultToReturn = .success(
            ListResponse(total: 1, page: 0, limit: 10, data: places)
        )

        let vm = MyCollectionBottomSheetViewModel(navigator: navigator, filter: filter, userUsecase: userUsecase, notificationService: notificationService)
        let viewLoaded$ = PublishRelay<Void>()
        let output = vm.transform(input: .init(
            myCollectionViewLoaded$: viewLoaded$.asObservable(),
            closeButtonTapped$: .empty(),
            placeTabelCellSelected$: .empty(),
            bottomReached$: .empty(),
            refetchButtonTapped$: .empty()
        ))

        // places$: 초기 [] 스킵하고 첫 업데이트만 기다림
        let placeExp = expectation(description: "places updated")
        var capturedPlaces: [Place]?
        output.places$
            .skip(1)
            .take(1)
            .subscribe(onNext: { ps in
                capturedPlaces = ps
                placeExp.fulfill()
            })
            .disposed(by: disposeBag)

        // isInitialLoading$: true -> false 두 번을 모두 기다림
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2
        var capturedLoading: [Bool] = []
        output.isInitialLoading$
            .take(2) // ✅ 두 이벤트만 받고 자동 완료
            .subscribe(onNext: { isLoading in
                capturedLoading.append(isLoading)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        viewLoaded$.accept(())

        // then
        wait(for: [placeExp, loadingExp], timeout: 2.0)
        XCTAssertEqual(capturedPlaces?.count, places.count)
        XCTAssertEqual(capturedLoading, [true, false])
    }

    
    func test_initialLoad_failure_setsError_andStopsLoading(){
        
        userUsecase.placesResultToReturn = .failure(.clientError("test-error"))

        let vm = MyCollectionBottomSheetViewModel(navigator: navigator, filter: filter, userUsecase: userUsecase, notificationService: notificationService)
        let viewLoaded$ = PublishRelay<Void>()
        let output = vm.transform(input: .init(
            myCollectionViewLoaded$: viewLoaded$.asObservable(),
            closeButtonTapped$: .empty(),
            placeTabelCellSelected$: .empty(),
            bottomReached$: .empty(),
            refetchButtonTapped$: .empty()
        ))



        // isInitialLoading$: true -> false 두 번을 모두 기다림
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2
        var capturedLoading: [Bool] = []
        output.isInitialLoading$
            .take(2) // ✅ 두 이벤트만 받고 자동 완료
            .subscribe(onNext: { isLoading in
                capturedLoading.append(isLoading)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)

        
        
        let errorExp = expectation(description: "error updated")
        var capturedError: NetworkError? = nil
        
        output.error$
            .skip(1)
            .take(1)
            .subscribe(onNext: { error in
                capturedError = error;
                errorExp.fulfill()
            })
            .disposed(by: disposeBag)

        
        // when
        viewLoaded$.accept(())

        // then
        wait(for: [loadingExp, errorExp], timeout: 2.0)
        XCTAssertEqual(capturedLoading, [true, false])
        XCTAssertEqual(capturedError, .clientError("test-error"))
        
    }

    // MARK: - bottomReached 페이징 성공

    func test_bottomReached_whenHasMore_appendsNextPage_andUpdatesPlaces() {
        // given
        // pageSize = 10 기준
        let firstPagePlaces = (0..<10).map { i in
            Place.mock(id: "\(i)", name: "P\(i)")
        }
        let secondPagePlaces = (10..<15).map { i in
            Place.mock(id: "\(i)", name: "P\(i)")
        }

        userUsecase.placesResultsQueue = [
            .success(ListResponse(total: 15, page: 0, limit: 10, data: firstPagePlaces)),
            .success(ListResponse(total: 15, page: 1, limit: 10, data: secondPagePlaces))
        ]

        let vm = MyCollectionBottomSheetViewModel(
            navigator: navigator,
            filter: filter,
            userUsecase: userUsecase,
            notificationService: notificationService
        )

        let viewLoaded$ = PublishRelay<Void>()
        let bottomReached$ = PublishRelay<Void>()

        let output = vm.transform(input: .init(
            myCollectionViewLoaded$: viewLoaded$.asObservable(),
            closeButtonTapped$: .empty(),
            placeTabelCellSelected$: .empty(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: .empty()
        ))

        var snapshots: [[Place]] = []
        let placesExp = expectation(description: "places updated twice")
        placesExp.expectedFulfillmentCount = 2

        output.places$
            .skip(1)  // 초기 [] 스킵
            .take(2)  // 1) 첫 로딩  2) 페이징 후
            .subscribe(onNext: { ps in
                snapshots.append(ps)
                placesExp.fulfill()
            })
            .disposed(by: disposeBag)

        // when
        viewLoaded$.accept(())

        // 첫 페이지 로딩 조금 끝나게 한 뒤 bottomReached 날려주기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            bottomReached$.accept(())
        }

        // then
        wait(for: [placesExp], timeout: 2.0)

        XCTAssertEqual(snapshots.count, 2)
        XCTAssertEqual(snapshots[0].map { $0.id }, (0..<10).map { "\($0)" })
        XCTAssertEqual(snapshots[1].map { $0.id }, (0..<15).map { "\($0)" })
        XCTAssertEqual(userUsecase.getPlacesCallCount, 2)
    }


    // MARK: - bottomReached: hasMore == false 이면 추가 호출 안함

    func test_bottomReached_whenHasNoMore_doesNotFetch() {
        // total == firstPage.count → hasMore false 라고 가정
        let firstPagePlaces = [
            Place.mock(id: "1", name: "A"),
            Place.mock(id: "2", name: "B")
        ]
        
        userUsecase.placesResultToReturn = .success(
            ListResponse(total: 2, page: 0, limit: 10, data: firstPagePlaces)
        )
        
        let vm = MyCollectionBottomSheetViewModel(
            navigator: navigator,
            filter: filter,
            userUsecase: userUsecase,
            notificationService: notificationService
        )
        
        let viewLoaded$ = PublishRelay<Void>()
        let bottomReached$ = PublishRelay<Void>()
        
        _ = vm.transform(input: .init(
            myCollectionViewLoaded$: viewLoaded$.asObservable(),
            closeButtonTapped$: .empty(),
            placeTabelCellSelected$: .empty(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: .empty()
        ))
        
        let firstLoadExp = expectation(description: "first load")
        
        // 첫 호출 끝날 때까지 기다리기 위해 places$ 구독
        vm.transform(input: .init(
            myCollectionViewLoaded$: .empty(),
            closeButtonTapped$: .empty(),
            placeTabelCellSelected$: .empty(),
            bottomReached$: .empty(),
            refetchButtonTapped$: .empty()
        )).places$
            .skip(1)
            .take(1)
            .subscribe(onNext: { _ in
                firstLoadExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        wait(for: [firstLoadExp], timeout: 1.0)
        
        // when: hasMore = false 상황에서 bottomReached 여러 번
        bottomReached$.accept(())
        bottomReached$.accept(())
        
        // then
        // getPlaces는 초기 로딩 1번만 호출
        XCTAssertEqual(userUsecase.getPlacesCallCount, 1)
    }

    // MARK: - closeButtonTapped → dismiss 호출

    func test_closeButtonTapped_dismissesNavigator() {
        let vm = MyCollectionBottomSheetViewModel(
            navigator: navigator,
            filter: filter,
            userUsecase: userUsecase,
            notificationService: notificationService
        )
        
        let close$ = PublishRelay<Void>()
        
        _ = vm.transform(input: .init(
            myCollectionViewLoaded$: .empty(),
            closeButtonTapped$: close$.asObservable(),
            placeTabelCellSelected$: .empty(),
            bottomReached$: .empty(),
            refetchButtonTapped$: .empty()
        ))
        
        let mockNav = navigator as! MockBottomSheetNavigator
        XCTAssertFalse(mockNav.isDismissed)
        
        // when
        close$.accept(())
        
        // then
        XCTAssertTrue(mockNav.isDismissed)
    }

    // MARK: - placeTabelCellSelected → placeDetail present

    func test_placeCellSelected_presentsPlaceDetail() {
        let vm = MyCollectionBottomSheetViewModel(
            navigator: navigator,
            filter: filter,
            userUsecase: userUsecase,
            notificationService: notificationService
        )
        
        let placeSelected$ = PublishRelay<String>()
        
        _ = vm.transform(input: .init(
            myCollectionViewLoaded$: .empty(),
            closeButtonTapped$: .empty(),
            placeTabelCellSelected$: placeSelected$.asObservable(),
            bottomReached$: .empty(),
            refetchButtonTapped$: .empty()
        ))
        
        let mockNav = navigator as! MockBottomSheetNavigator
        
        // when
        placeSelected$.accept("123")
        
        // then
        guard case .placeDetail(let placeId)? = mockNav.presentedSheet else {
            return XCTFail("Expected .placeDetail route")
        }
        XCTAssertEqual(placeId, "123")
    }

    // MARK: - refetchButtonTapped 성공: pagination reset + 재로딩

    func test_refetchButtonTapped_success_resetsAndReloads() {
        // given
        let firstPage = [Place.mock(id: "1", name: "A")]
        let refetched = [Place.mock(id: "2", name: "B")]

        userUsecase.placesResultsQueue = [
            .success(ListResponse(total: 2, page: 0, limit: 10, data: firstPage)),
            .success(ListResponse(total: 2, page: 0, limit: 10, data: refetched))
        ]

        let vm = MyCollectionBottomSheetViewModel(
            navigator: navigator,
            filter: filter,
            userUsecase: userUsecase,
            notificationService: notificationService
        )

        let viewLoaded$ = PublishRelay<Void>()
        let refetch$ = PublishRelay<Void>()

        let output = vm.transform(input: .init(
            myCollectionViewLoaded$: viewLoaded$.asObservable(),
            closeButtonTapped$: .empty(),
            placeTabelCellSelected$: .empty(),
            bottomReached$: .empty(),
            refetchButtonTapped$: refetch$.asObservable()
        ))

        let firstLoadExp = expectation(description: "first non-empty load")
        let refetchExp = expectation(description: "refetch non-empty load")

        var firstIds: [String]?
        var secondIds: [String]?

        output.places$
            .skip(1)                // 초기 [] 스킵
            .filter { !$0.isEmpty } // clear 이벤트([])는 무시
            .take(2)                // 1) 처음 로딩 2) refetch 이후
            .subscribe(onNext: { places in
                let ids = places.map { $0.id }
                if firstIds == nil {
                    firstIds = ids
                    firstLoadExp.fulfill()
                    // 첫 로딩 완료된 시점에 refetch
                    refetch$.accept(())
                } else {
                    secondIds = ids
                    refetchExp.fulfill()
                }
            })
            .disposed(by: disposeBag)

        // when
        viewLoaded$.accept(())

        // then
        wait(for: [firstLoadExp, refetchExp], timeout: 2.0)

        XCTAssertEqual(firstIds, ["1"])
        XCTAssertEqual(secondIds, ["2"])
        XCTAssertEqual(userUsecase.getPlacesCallCount, 2)
    }


    // MARK: - refetchButtonTapped 실패: error 설정 + isInitialLoading 토글

    func test_refetchButtonTapped_failure_setsError() {
        let firstPage = [
            Place.mock(id: "1", name: "A")
        ]
        
        userUsecase.placesResultsQueue = [
            .success(ListResponse(total: 1, page: 0, limit: 10, data: firstPage)),
            .failure(.clientError("refetch-error"))
        ]
        
        let vm = MyCollectionBottomSheetViewModel(
            navigator: navigator,
            filter: filter,
            userUsecase: userUsecase,
            notificationService: notificationService
        )
        
        let viewLoaded$ = PublishRelay<Void>()
        let refetch$ = PublishRelay<Void>()
        
        let output = vm.transform(input: .init(
            myCollectionViewLoaded$: viewLoaded$.asObservable(),
            closeButtonTapped$: .empty(),
            placeTabelCellSelected$: .empty(),
            bottomReached$: .empty(),
            refetchButtonTapped$: refetch$.asObservable()
        ))
        
        let errorExp = expectation(description: "error set after refetch")
        
        output.error$
            .skip(1) // 초기 nil 스킵
            .take(2) // 1) 초기 로드 성공 nil, 2) refetch 실패
            .subscribe(onNext: { err in
                if case .clientError("refetch-error")? = err {
                    errorExp.fulfill()
                }
            })
            .disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            refetch$.accept(())
        }
        
        wait(for: [errorExp], timeout: 2.0)
    }

    // MARK: - filter$ 초기값 노출 확인

    func test_output_filter_showsInitialFilter() {
        let vm = MyCollectionBottomSheetViewModel(
            navigator: navigator,
            filter: .save,
            userUsecase: userUsecase,
            notificationService: notificationService
        )
        
        let output = vm.transform(input: .init(
            myCollectionViewLoaded$: .empty(),
            closeButtonTapped$: .empty(),
            placeTabelCellSelected$: .empty(),
            bottomReached$: .empty(),
            refetchButtonTapped$: .empty()
        ))
        
        let filter = try? output.filter$.toBlocking(timeout: 1.0).first()
        XCTAssertEqual(filter, .save)
    }

    // MARK: - SheetCommand .forceMedium → forceMedium$ emit

    func test_sheetCommand_forceMedium_emits() {
        let vm = MyCollectionBottomSheetViewModel(
            navigator: navigator,
            filter: filter,
            userUsecase: userUsecase,
            notificationService: notificationService
        )
        
        let output = vm.transform(input: .init(
            myCollectionViewLoaded$: .empty(),
            closeButtonTapped$: .empty(),
            placeTabelCellSelected$: .empty(),
            bottomReached$: .empty(),
            refetchButtonTapped$: .empty()
        ))
        
        let exp = expectation(description: "forceMedium emitted")
        
        output.forceMedium$
            .take(1)
            .subscribe(onNext: { _ in
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        
        // when
        notificationService.post(.sheetCommand, object: SheetCommand.forceMedium)
        
        // then
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - SheetCommand .restoreDetents → restoreDetents$ emit

    func test_sheetCommand_restoreDetents_emits() {
        let vm = MyCollectionBottomSheetViewModel(
            navigator: navigator,
            filter: filter,
            userUsecase: userUsecase,
            notificationService: notificationService
        )
        
        let output = vm.transform(input: .init(
            myCollectionViewLoaded$: .empty(),
            closeButtonTapped$: .empty(),
            placeTabelCellSelected$: .empty(),
            bottomReached$: .empty(),
            refetchButtonTapped$: .empty()
        ))
        
        let exp = expectation(description: "restoreDetents emitted")
        
        output.restoreDetents$
            .take(1)
            .subscribe(onNext: { _ in
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        
        // when
        notificationService.post(.sheetCommand, object: SheetCommand.restoreDetents)
        
        // then
        wait(for: [exp], timeout: 1.0)
    }
    
    
    
}
