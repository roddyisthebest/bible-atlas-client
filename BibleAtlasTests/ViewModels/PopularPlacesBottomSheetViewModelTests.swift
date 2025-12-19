//
//  PopularPlacesBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/14/25.
//

import XCTest
import RxRelay
import RxTest
import RxBlocking
import RxSwift

@testable import BibleAtlas

final class PopularPlacesBottomSheetViewModelTests: XCTestCase {

    
    private var placeUsecase:MockPlaceusecase!
    private var navigator: MockBottomSheetNavigator!
    private var disposeBag:DisposeBag!
    private var scheduler: TestScheduler!
    private var notificationService: MockNotificationService!

    private let places:[Place] = [
        Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "hello", koreanDescription: "test", stereo: .parent, likeCount: 5, types: [PlaceType(id: 3, name: .altar)]),
        Place(id: "test1", name: "test", koreanName: "테스트", isModern: true, description: "hello", koreanDescription: "test", stereo: .parent, likeCount: 5, types: [PlaceType(id: 3, name: .altar)]),
        Place(id: "test2", name: "test", koreanName: "테스트", isModern: true, description: "hello", koreanDescription: "test", stereo: .parent, likeCount: 5, types: [PlaceType(id: 3, name: .altar)])
    ]
    
    override func setUp(){
        super.setUp()
        self.placeUsecase = MockPlaceusecase();
        self.navigator = MockBottomSheetNavigator();
        self.disposeBag = DisposeBag();
        self.scheduler = TestScheduler(initialClock: 0)
        self.notificationService = MockNotificationService()
    }
    
    func test_viewLoaded_success_replacesPlaces_setsLoadingFalse_clearsError_updatesTotal(){
        
        let result:Result<ListResponse<Place>,NetworkError> = .success(ListResponse(total: 3, page: 0, limit: 10, data: places))
        let exp = expectation(description: "api request wait");
        
        placeUsecase.completedExp = exp;
        placeUsecase.resultToReturn = result;
        
        let vm = PopularPlacesBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService: notificationService);
        
        let viewLoaded$ = PublishRelay<Void>();
        
        let output = vm.transform(input: PopularPlacesBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), closeButtonTapped$: .empty(), cellSelected$: .empty(), bottomReached$: .empty(), refetchButtonTapped$: .empty()))
        
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
        
        var gotPlaces:[Place]?
        let placesExp = expectation(description: "places set");
        
        
        output.places$.skip(1).subscribe(onNext:{
            places in
            gotPlaces = places;
            placesExp.fulfill()
        }).disposed(by: disposeBag)
        
            
        let errorExp = expectation(description: "error set")
        errorExp.isInverted = true
        
        output.error$.skip(1).compactMap{$0}.subscribe(onNext:{
            error in
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        
        wait(for:[exp, placesExp, errorExp, loadingExp], timeout: 1.0);
        
        XCTAssertEqual(gotPlaces?.count, 3)
        XCTAssertEqual(loadingSeq, [true ,false])
    }
    
    func test_viewLoaded_failure_keepsListEmpty_setsLoadingFalse_setsError(){
        
        let error:NetworkError = .clientError("test-error")
        let result:Result<ListResponse<Place>,NetworkError> = .failure(error)
        let exp = expectation(description: "api request wait");
        
        placeUsecase.completedExp = exp;
        placeUsecase.resultToReturn = result;
        
        let vm = PopularPlacesBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService:notificationService);
        
        let viewLoaded$ = PublishRelay<Void>();
        
        let output = vm.transform(input: PopularPlacesBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), closeButtonTapped$: .empty(), cellSelected$: .empty(), bottomReached$: .empty(), refetchButtonTapped$: .empty()))
        
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
        
        let placesExp = expectation(description: "places set");
        placesExp.isInverted = true
        
        output.places$.skip(1).subscribe(onNext:{
            places in
            placesExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        var gotError:NetworkError?
        let errorExp = expectation(description: "error set")
        
        output.error$.skip(1).compactMap{$0}.subscribe(onNext:{
            error in
            gotError = error
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        
        wait(for:[exp, placesExp, errorExp, loadingExp], timeout: 1.0);
        
        XCTAssertEqual(gotError, error)
        XCTAssertEqual(loadingSeq, [true ,false])
        
        
        
    }
    
    
    func test_bottomReached_success_appendsNextPage_togglesFetching_andAdvancesPage(){
        
        let result:Result<ListResponse<Place>,NetworkError> = .success(ListResponse(total: 30, page: 0, limit: 15, data: places))
        let exp = expectation(description: "api request wait");
        
        placeUsecase.completedExp = exp;
        placeUsecase.resultToReturn = result;
        
        let vm = PopularPlacesBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, schedular: scheduler, notificationService: notificationService);
        
        let viewLoaded$ = PublishRelay<Void>();
        let bottomReached$ = PublishRelay<Void>();

        let output = vm.transform(input: PopularPlacesBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), closeButtonTapped$: .empty(), cellSelected$: .empty(), bottomReached$: bottomReached$.asObservable(), refetchButtonTapped$: .empty()))
        
        let placesExp = expectation(description: "places set");
        
        output.places$.skip(1).take(1).subscribe(onNext:{
            places in
            placesExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        
        wait(for:[exp, placesExp], timeout: 1.0);
        
        let nextResult:Result<ListResponse<Place>,NetworkError> = .success(ListResponse(total: 30, page: 1, limit: 15, data: places))
        let nextExp = expectation(description: "api request re wait");
        
        placeUsecase.completedExp = nextExp;
        placeUsecase.resultToReturn = nextResult;
        
        
        var gotPlaces: [Place]?
        let nextPlacesExp = expectation(description: "places set")
        
        output.places$.skip(1).take(1).subscribe(onNext:{ places in
            gotPlaces = places;
            nextPlacesExp.fulfill()
        }).disposed(by: disposeBag)
        
        var fetchingSeq:[Bool] = []
        let fetchingExp = expectation(description: "isFetching toggled")
        fetchingExp.expectedFulfillmentCount = 2
        
        output.isFetchingNext$.skip(1).take(2).subscribe(onNext:{
            isFetching in
            fetchingSeq.append(isFetching)
            fetchingExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        bottomReached$.accept(())
        scheduler.advanceTo(150)
        
        wait(for:[nextPlacesExp, nextExp, fetchingExp], timeout: 1.0);
        
        XCTAssertEqual(gotPlaces?.count, 6)
        XCTAssertEqual(fetchingSeq, [true, false])
        
        
    }
    
    func test_bottomReached_ignored_whenAlreadyFetching() {
        // Given
        // pageSize = 15로 가정. hasMore = true가 되도록 total은 크게.
        let firstPage = makePlaces(count: 15, start: 0)
        let nextPage  = makePlaces(count: 15, start: 15)

        placeUsecase.resultsQueue = [
            .success(ListResponse(total: 100, page: 0, limit: 15, data: firstPage)), // 초기 로드
            .success(ListResponse(total: 100, page: 1, limit: 15, data: nextPage))   // 다음 페이지
        ]
        placeUsecase.delaysQueue = [
            0.0,   // 초기 로드는 지연 없음
            0.2    // 다음 페이지 로드는 200ms 지연 -> 이 동안 연타 무시 검증
        ]

        let vm = PopularPlacesBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, schedular: scheduler, notificationService: notificationService)

        let viewLoaded$    = PublishRelay<Void>()
        let bottomReached$ = PublishRelay<Void>()

        let output = vm.transform(input: .init(
            viewLoaded$: viewLoaded$.asObservable(),
            closeButtonTapped$: .empty(),
            cellSelected$: .empty(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: .empty()
        ))

        // 초기 리스트 세팅 도착 (BehaviorRelay 초기 [] 한 번 + 성공 데이터 한 번 → skip(1))
        var initialCount = 0
        let initialListExp = expectation(description: "initial list set")
        output.places$
            .skip(1)
            .take(1)
            .subscribe(onNext: { list in
                initialCount = list.count
                initialListExp.fulfill()
            })
            .disposed(by: disposeBag)

        viewLoaded$.accept(())
        wait(for: [initialListExp], timeout: 1.0)

        // isFetchingNext$ 토글은 한 번만 [true, false]
        var fetchingSeq: [Bool] = []
        let fetchingExp = expectation(description: "fetching toggled once")
        fetchingExp.expectedFulfillmentCount = 2
        output.isFetchingNext$
            .skip(1)   // 현재 false 스킵
            .take(2)   // true -> false
            .subscribe(onNext: { v in
                fetchingSeq.append(v)
                fetchingExp.fulfill()
            })
            .disposed(by: disposeBag)

        // inflight 동안 3번째 호출(= 총 3회 호출) 시도를 금지
        let noThirdCallDuringInflight = expectation(description: "no third getPlaces call while inflight")
        noThirdCallDuringInflight.isInverted = true
        placeUsecase.onGetPlacesCall = { callIndex, _ in
            // 1: 초기 viewLoaded, 2: 첫 bottomReached(inflight), 3: 금지!
            if callIndex >= 3 { noThirdCallDuringInflight.fulfill() }
        }

        // append는 한 번만 발생
        var finalCount = 0
        let appendedExp = expectation(description: "list appended once")
        output.places$
            .skip(1)   // 구독 즉시 현재값 재방출 스킵
            .take(1)
            .subscribe(onNext: { list in
                finalCount = list.count
                appendedExp.fulfill()
            })
            .disposed(by: disposeBag)

        // When: 첫 bottomReached → 다음 페이지 fetch(inflight)
        bottomReached$.accept(())
        // 디바운스(100µs)보다 길게, inflight 중에 한 번 더 연타
        scheduler.advanceTo(1_000)

        bottomReached$.accept(()) // 이미 fetching 중이므로 무시되어야 함

        // inflight 중에는 3번째 호출이 없어야 함 (관찰 윈도우는 0.1s < 0.2s 지연)
        wait(for: [noThirdCallDuringInflight], timeout: 0.1)

        // inflight 끝나면 append와 토글 종료가 관측되어야 함
        wait(for: [appendedExp, fetchingExp], timeout: 1.0)

        // Then
        XCTAssertEqual(fetchingSeq, [true, false], "fetching 토글은 한 번만 발생해야 함")
        XCTAssertEqual(placeUsecase.listApiCall, 2, "초기 로드 1회 + 다음 페이지 1회 = 총 2회여야 함")
        XCTAssertEqual(finalCount, initialCount + nextPage.count, "한 번만 append 되어야 함")
    }
    
    func test_bottomReached_ignored_whenNoMorePages(){
        
        placeUsecase.resultToReturn =  .success(ListResponse(total: 10, page: 0, limit: 15, data: []))

        let vm = PopularPlacesBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, schedular: scheduler, notificationService: notificationService)


        let viewLoaded$ = PublishRelay<Void>()
        let bottomReached$ = PublishRelay<Void>()

        let output = vm.transform(input: .init(
            viewLoaded$: viewLoaded$.asObservable(),
            closeButtonTapped$: .empty(),
            cellSelected$: .empty(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: .empty()
        ))

        // 초기 리스트 세팅 도착 (BehaviorRelay 초기 [] 한 번 + 성공 데이터 한 번 → skip(1))
        let initialListExp = expectation(description: "initial list set")
        output.places$
            .skip(1)
            .take(1)
            .subscribe(onNext: { list in
                initialListExp.fulfill()
            })
            .disposed(by: disposeBag)

        scheduler.scheduleAt(10) { viewLoaded$.accept(()) }
        scheduler.start()
        wait(for: [initialListExp], timeout: 1.0)
        
        // 1) 추가 API 호출 없음 (inverted)
        let noSecondFetchExp = expectation(description: "no second getPlaces call")
        noSecondFetchExp.isInverted = true
        placeUsecase.invokedExp = noSecondFetchExp

           // 2) places$ 추가 방출 없음 (inverted)
        let noAppendExp = expectation(description: "no append on noMore")
        noAppendExp.isInverted = true
        output.places$
               .skip(1)
               .take(1)
               .subscribe(onNext: { _ in noAppendExp.fulfill() })
               .disposed(by: disposeBag)

        // 3) isFetchingNext$ 토글 없음 (inverted)
        let noToggleExp = expectation(description: "isFetchingNext not toggled")
        noToggleExp.isInverted = true
        output.isFetchingNext$
               .skip(1)   // 현재 false 스킵
               .take(1)   // 어떤 변화라도 잡으면 실패
               .subscribe(onNext: { _ in noToggleExp.fulfill() })
               .disposed(by: disposeBag)

        // bottomReached 트리거 → debounce 통과시키기 위해 가상시간 전진
        scheduler.scheduleAt(20) { bottomReached$.accept(()) }
        scheduler.advanceTo(200) // 100µs 디바운스 넘기기

        wait(for: [noSecondFetchExp, noAppendExp, noToggleExp], timeout: 1.0)

        XCTAssertEqual(placeUsecase.listApiCall, 1, "API는 초기 로드 1회만 호출되어야 함")

    }
    
    func test_cellSelected_presentsPlaceDetail(){
        
        let vm = PopularPlacesBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService: notificationService);
        
        let cellSelected$ = PublishRelay<String>();
        
        let _ = vm.transform(input: PopularPlacesBottomSheetViewModel.Input(viewLoaded$: .empty(), closeButtonTapped$: .empty(), cellSelected$: cellSelected$.asObservable(), bottomReached$: .empty(), refetchButtonTapped$: .empty()))
        
        let placeId = "test"
        cellSelected$.accept(placeId)
        
        XCTAssertEqual(navigator.presentedSheet, .placeDetail(placeId))
        
        
        
    }
    
    func test_closeButtonTapped_dismisses(){
        let vm = PopularPlacesBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService: notificationService);
        
        let closeButtonTapped$ = PublishRelay<Void>();
        
        let _ = vm.transform(input: PopularPlacesBottomSheetViewModel.Input(viewLoaded$: .empty(), closeButtonTapped$: closeButtonTapped$.asObservable(), cellSelected$: .empty(), bottomReached$: .empty(), refetchButtonTapped$: .empty()))
        
        closeButtonTapped$.accept(())
        
        XCTAssertTrue(navigator.isDismissed)
    }

    // MARK: - Helpers
    private func makePlaces(count: Int, start: Int) -> [Place] {
        return (0..<count).map { i in
            Place(    id: "p\(start + i)",
                      name: "Place \(start + i)", koreanName: "테스트2", isModern: false, description: "hallo", koreanDescription: "안녕", stereo: .child, verse: "ㅁㄴ", likeCount: 22, unknownPlacePossibility: 12, types: [PlaceType(id: 1, name: .altar)], childRelations: [], parentRelations: [], isLiked: false, isSaved: false, memo: nil, imageTitle: nil)
        }
    }

    
    
}
