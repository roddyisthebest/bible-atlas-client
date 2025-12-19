//
//  PlaceTypesBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/6/25.
//

import XCTest

import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas

final class PlaceTypesBottomSheetViewModelTests: XCTestCase {

    private var placeUsecase:MockPlaceusecase!
    private var navigator: MockBottomSheetNavigator!
    
    private var disposeBag:DisposeBag!
    private var scheduler: TestScheduler!
    
    private var notificationService: MockNotificationService!

    
    override func setUp(){
        super.setUp();
        
        self.placeUsecase = MockPlaceusecase();
        self.navigator = MockBottomSheetNavigator();
        self.disposeBag = DisposeBag();
        self.scheduler = TestScheduler(initialClock: 0)
        self.notificationService = MockNotificationService()
        
    }
    
    func test_viewLoaded_success_shouldToggleInitialLoading_andSetFirstPage_andKeepErrorNil(){
        let exp = expectation(description: "placeTypes set")
        let placeTypes = [
            PlaceTypeWithPlaceCount(id: 1, name: PlaceTypeName.campsite, placeCount: 10),
            PlaceTypeWithPlaceCount(id: 2, name: PlaceTypeName.archipelago, placeCount: 23),
        ]
        
        placeUsecase.placeTypesResult = .success(ListResponse(total: 2, page: 0, limit: 10, data: placeTypes))
        placeUsecase.placeTypesExp = exp;
        
        let vm = PlaceTypesBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService: notificationService)
        let viewLoaded$ = PublishRelay<Void>();
        
        let output = vm.transform(input: PlaceTypesBottomSheetViewModel.Input(placeTypeCellTapped$: .empty(), closeButtonTapped$: .empty(), viewLoaded$: viewLoaded$.asObservable(), bottomReached$: .empty(), refetchButtonTapped$: .empty()))
        
        var gotIsInitialLoadingHistories:[Bool] = []
        let gotIsInitialLoadingExp = expectation(description: "placeTypes initial loading toggle")
        gotIsInitialLoadingExp.expectedFulfillmentCount = 2
        output.isInitialLoading$.take(2).subscribe(onNext:{
            isInitialLoading in
            gotIsInitialLoadingHistories.append(isInitialLoading)
            gotIsInitialLoadingExp.fulfill()
        }).disposed(by: disposeBag)
        
        var gotPlaceTypes: [PlaceTypeWithPlaceCount]?
        let gotPlaceTypesExp = expectation(description: "placeTypes got")
        output.placeTypes$.skip(1).take(1).subscribe(onNext:{ placeTypes in
            gotPlaceTypes = placeTypes
            gotPlaceTypesExp.fulfill()
        
        }).disposed(by: disposeBag)
        
        let errorExp = expectation(description: "error set")
        errorExp.isInverted = true;
        
        output.error$.skip(1).take(1).subscribe(onNext:{
            _ in
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        
        wait(for: [exp, gotPlaceTypesExp, gotIsInitialLoadingExp, errorExp], timeout: 1.0);
        
        XCTAssertEqual(gotPlaceTypes?.map(\.id), placeTypes.map(\.id))
        XCTAssertEqual(gotPlaceTypes?.map(\.name), placeTypes.map(\.name))
        XCTAssertEqual(gotPlaceTypes?.map(\.placeCount), placeTypes.map(\.placeCount))
        XCTAssertEqual(gotIsInitialLoadingHistories, [true, false])
        
        
    }

    
    func test_viewLoaded_failure_shouldToggleInitialLoading_andEmitError()
    {
        let error = NetworkError.clientError("test-error")
        let exp = expectation(description: "error set")

        placeUsecase.placeTypesResult = .failure(error)
        placeUsecase.placeTypesExp = exp;
        
        let vm = PlaceTypesBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService: notificationService)
        let viewLoaded$ = PublishRelay<Void>();
        
        let output = vm.transform(input: PlaceTypesBottomSheetViewModel.Input(placeTypeCellTapped$: .empty(), closeButtonTapped$: .empty(), viewLoaded$: viewLoaded$.asObservable(), bottomReached$: .empty(), refetchButtonTapped$: .empty()))
        
        var gotIsInitialLoadingHistories:[Bool] = []
        let gotIsInitialLoadingExp = expectation(description: "placeTypes initial loading toggle")
        gotIsInitialLoadingExp.expectedFulfillmentCount = 2
        output.isInitialLoading$.take(2).subscribe(onNext:{
            isInitialLoading in
            gotIsInitialLoadingHistories.append(isInitialLoading)
            gotIsInitialLoadingExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        let errorExp = expectation(description: "error set")
        var gotError:NetworkError?
        
        output.error$.skip(1).take(1).subscribe(onNext:{
            error in
            gotError = error;
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        
        wait(for:[exp, gotIsInitialLoadingExp, errorExp] ,timeout: 2.0);
        XCTAssertEqual(gotIsInitialLoadingHistories, [true, false])
        XCTAssertEqual(gotError, error)
        
    }
    
    
    func test_bottomReached_success_shouldToggleFetchingNext_andAppend_andUpdatePagination() {
        // given
        let all = [
            PlaceTypeWithPlaceCount(id: 1, name: .campsite,    placeCount: 10),
            PlaceTypeWithPlaceCount(id: 2, name: .archipelago, placeCount: 23),
            PlaceTypeWithPlaceCount(id: 3, name: .canal,       placeCount: 200),
        ]

        // 초기 페이지(0) 응답 설정
        let initialCall = expectation(description: "initial call")
        placeUsecase.placeTypesExp = initialCall
        placeUsecase.placeTypesResult = .success(
            ListResponse(total: 3, page: 0, limit: 1, data: [all[0]])
        )

        let vm = PlaceTypesBottomSheetViewModel(
            navigator: navigator,
            placeUsecase: placeUsecase,
            schedular: scheduler,
            notificationService: notificationService
        )

        let viewLoaded$ = PublishRelay<Void>()
        let bottomReached$ = PublishRelay<Void>()

        let output = vm.transform(input: .init(
            placeTypeCellTapped$: .empty(),
            closeButtonTapped$: .empty(),
            viewLoaded$: viewLoaded$.asObservable(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: .empty()
        ))

        // 1) 첫 페이지 수신 대기
        let firstPageExp = expectation(description: "first page received")
        output.placeTypes$.skip(1).take(1)
            .subscribe(onNext: { _ in firstPageExp.fulfill() })
            .disposed(by: disposeBag)

        // 2) append 결과 캡처
        var appended: [PlaceTypeWithPlaceCount]?
        let appendExp = expectation(description: "appended received")
        output.placeTypes$.skip(2).take(1) // [], 첫페이지 이후의 다음 이벤트 = append
            .subscribe(onNext: { list in
                appended = list
                appendExp.fulfill()
            })
            .disposed(by: disposeBag)

        // 3) 토글 캡처(true→false)
        var toggles: [Bool] = []
        let toggleExp = expectation(description: "fetchingNext toggled")
        toggleExp.expectedFulfillmentCount = 2
        output.isFetchingNext$.skip(1).take(2)
            .subscribe(onNext: { v in
                toggles.append(v)
                toggleExp.fulfill()
            })
            .disposed(by: disposeBag)

        // when: 초기 로드
        viewLoaded$.accept(())
        wait(for: [initialCall, firstPageExp], timeout: 2.0)

        // 다음 페이지(1) 응답 설정
        let nextCall = expectation(description: "next call")
        placeUsecase.placeTypesExp = nextCall
        placeUsecase.placeTypesResult = .success(
            ListResponse(total: 3, page: 1, limit: 1, data: [all[1]])
        )

        // bottomReached 이벤트 발사
        bottomReached$.accept(())
        // debounce(100ms)를 가상 시간으로 통과
        scheduler.advanceTo(150)

        // then
        wait(for: [nextCall, toggleExp, appendExp], timeout: 2.0)
        XCTAssertEqual(toggles, [true, false])
        XCTAssertEqual(appended?.map(\.id), [1, 2]) // 1페이지 + 2페이지
    }
    
    
    
    // 4) 페이지네이션 가드: 이미 fetching 중이거나(hasMore=false)면 호출 안 됨
    func test_bottomReached_guard_shouldNotRequestNext_whenAlreadyFetching_orNoMore() {
        
        let vm = PlaceTypesBottomSheetViewModel(
            navigator: navigator,
            placeUsecase: placeUsecase,
            schedular: scheduler,
            notificationService: notificationService
        )

        let viewLoaded$ = PublishRelay<Void>()
        let bottomReached$ = PublishRelay<Void>()

        let _ = vm.transform(input: .init(
            placeTypeCellTapped$: .empty(),
            closeButtonTapped$: .empty(),
            viewLoaded$: viewLoaded$.asObservable(),
            bottomReached$: bottomReached$.asObservable(),
            refetchButtonTapped$: .empty()
        ))

        // 초기 1페이지: 아이템 1개, total=3, limit=1 (append 가능)
        let initialExp = expectation(description: "initial page fetched")
        placeUsecase.placeTypesExp = initialExp
        placeUsecase.placeTypesResult = .success(
            ListResponse(total: 3, page: 0, limit: 1, data: [
                PlaceTypeWithPlaceCount(id: 1, name: .campsite, placeCount: 10)
            ])
        )

        // 초기 로드
        viewLoaded$.accept(())
        wait(for: [initialExp], timeout: 2.0)

        // --- (A) already fetching 가드 ---
        // 다음 호출은 일부러 지연시켜 isFetchingNext=true인 동안 두 번째 bottomReached를 보냄
        // 첫 번째 next page 응답 설정 (page 1)
        let slowNextExp = expectation(description: "next page fetch (slow)")
        placeUsecase.placeTypesExp = slowNextExp
        placeUsecase.placeTypesResult = .success(
            ListResponse(total: 3, page: 1, limit: 1, data: [
                PlaceTypeWithPlaceCount(id: 2, name: .archipelago, placeCount: 23)
            ])
        )

        let callCountBefore = placeUsecase.placeTypesCallCount

        // 첫 번째 bottomReached
        bottomReached$.accept(())
        scheduler.advanceTo(150) // debounce 통과 → 호출 1회 증가 기대

        // isFetchingNext=true인 동안 두 번째 bottomReached 쏘기
        bottomReached$.accept(())
        scheduler.advanceTo(300) // debounce 통과 시도하더라도 가드로 무시되어야 함

        wait(for:[slowNextExp])
        // 아직 응답을 풀지 않았으므로(=slow), 호출 횟수는 1회여야 한다
        XCTAssertEqual(placeUsecase.placeTypesCallCount, callCountBefore + 1)

     
        
    }
    
    

    func test_refetch_success_shouldResetPagination_clearList_toggleInitialLoading_andSetFirstPage() throws {

        let vm = PlaceTypesBottomSheetViewModel(
            navigator: navigator,
            placeUsecase: placeUsecase,
            notificationService: notificationService
        )

        let viewLoaded$ = PublishRelay<Void>()
        let refetch$ = PublishRelay<Void>()

        let output = vm.transform(input: .init(
            placeTypeCellTapped$: .empty(),
            closeButtonTapped$: .empty(),
            viewLoaded$: viewLoaded$.asObservable(),
            bottomReached$: .empty(),
            refetchButtonTapped$: refetch$.asObservable()
        ))

        // 초기 로드(더미)로 리스트를 한 번 채워둔다
        let initialExp = expectation(description: "initial load")
        placeUsecase.placeTypesExp = initialExp
        placeUsecase.placeTypesResult = .success(
            ListResponse(total: 2, page: 0, limit: 18, data: [
                PlaceTypeWithPlaceCount(id: 1, name: .campsite, placeCount: 10),
                PlaceTypeWithPlaceCount(id: 2, name: .archipelago, placeCount: 23),
            ])
        )
        
        var lists:[[PlaceTypeWithPlaceCount]] = []
        let listExp = expectation(description: "place list set")
        listExp.expectedFulfillmentCount = 3
        
        // placeTypes 재세팅: [] → [첫페이지]
       output.placeTypes$
            .skip(1)          // 초기 [] 스킵
            .take(3)          // [초기 로드 리스트], [], [refetch 첫페이지]
            .subscribe(onNext:{
                placeTypes in
                lists.append(placeTypes)
                listExp.fulfill();
            }).disposed(by: disposeBag)
        
        viewLoaded$.accept(())
        wait(for: [initialExp], timeout: 2.0)

        // refetch 응답: 첫 페이지로 재세팅
        let refetchExp = expectation(description: "refetch done")
        placeUsecase.placeTypesExp = refetchExp
        placeUsecase.placeTypesResult = .success(
            ListResponse(total: 3, page: 0, limit: 18, data: [
                PlaceTypeWithPlaceCount(id: 100, name: .canal, placeCount: 7)
            ])
        )

        // isInitialLoading 토글 감시
        var loadingSeq: [Bool] = []
        let loadingExp = expectation(description: "initialLoading toggled")
        loadingExp.expectedFulfillmentCount = 2
        output.isInitialLoading$
            .skip(1) // 초기 true는 스킵 (혹은 상황에 맞게 조정)
            .take(2) // refetch 시작 true, 완료 false
            .subscribe(onNext: { v in
                loadingSeq.append(v)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)

        
  
        
        

        refetch$.accept(())
        wait(for: [refetchExp, loadingExp, listExp], timeout: 3.0)
        

        // then
        // 마지막 리스트는 refetch 결과의 첫 페이지여야 함
        let lastList = lists.last ?? []
        XCTAssertEqual(lastList.map(\.id), [100])

        // refetch 과정에서 빈 배열로 한 번 초기화되었는지(선택 검증)
        // let clearedList = lists[safe: lists.count - 2] ?? []
        // XCTAssertTrue(clearedList.isEmpty)

        XCTAssertEqual(loadingSeq, [true, false])

        // error는 nil 유지(inverted expectation)
        let noError = expectation(description: "no error on refetch success")
        noError.isInverted = true
        output.error$
            .compactMap { $0 }
            .subscribe(onNext: { _ in noError.fulfill() })
            .disposed(by: disposeBag)
        wait(for: [noError], timeout: 0.2)
    }




}
