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

    override func setUp(){
        super.setUp()
        disposeBag = DisposeBag();
        filter = .like
        userUsecase = MockUserUsecase();
        navigator = MockBottomSheetNavigator();
        scheduler = TestScheduler(initialClock: 0)
    }
    
    func test_initialLoad_success_setsPlaces_andUpdatesPagination() throws {
        // given
        let places = [Place(id: "123", name: "test", isModern: true, description: "test",
                            koreanDescription: "test", stereo: .child, likeCount: 1, types: [])]
        userUsecase.placesResultToReturn = .success(
            ListResponse(total: 1, page: 0, limit: 10, data: places)
        )

        let vm = MyCollectionBottomSheetViewModel(navigator: navigator, filter: filter, userUsecase: userUsecase)
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

        let vm = MyCollectionBottomSheetViewModel(navigator: navigator, filter: filter, userUsecase: userUsecase)
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

    func test_bottomReached_whenHasMore_appendsNextPage_andUpdatesPagination() {
       
        //TODO
    }

    
    
    
}
