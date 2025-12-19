//
//  PlaceCharactersBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/9/25.
//

import XCTest

import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas


final class PlaceCharactersBottomSheetViewModelTests: XCTestCase {
    private var placeUsecase:MockPlaceusecase!
    private var navigator: MockBottomSheetNavigator!
    private var disposeBag:DisposeBag!
    private var scheduler: TestScheduler!
    private var notificationService: MockNotificationService!
    
    private var character:String = "A"
    
    override func setUp() {
        super.setUp()
        self.placeUsecase = MockPlaceusecase();
        self.navigator = MockBottomSheetNavigator();
        self.disposeBag = DisposeBag()
    }

    
    func test_viewLoaded_success_emitsData_setsLoadingFalse_andClearsError() {
        // Given
        let apiExp = expectation(description: "api response set")
        placeUsecase.prefixExp = apiExp
        placeUsecase.prefixResult = .success(
            ListResponse(total: 2, page: 0, limit: -1,
                         data: [PlacePrefix(prefix: "A", placeCount: "10"),
                                PlacePrefix(prefix: "B", placeCount: "10")])
        )

        let vm = PlaceCharactersBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService: notificationService)
        let viewLoaded$ = PublishRelay<Void>()

        let output = vm.transform(input: .init(
            placeCharacterCellTapped$: .empty(),
            closeButtonTapped$: .empty(),
            viewLoaded$: viewLoaded$.asObservable(),
            refetchButtonTapped$: .empty()
        
        ))

        // 1) 로딩 토글: [true, false]를 정확히 2번 받도록
        var loadingSeq: [Bool] = []
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2

        output.isInitialLoading$
            .take(2) // 초기 true + 완료 후 false
            .subscribe(onNext: { v in
                loadingSeq.append(v)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)

        // 2) prefix 채워졌는지: 초기 [] 무시하고 한 번만 받기
        var gotPrefixs: [PlacePrefix]?
        let prefixsExp = expectation(description: "prefixs set")

        output.placeCharacter$
            .skip(1)   // 초기 [] 무시
            .take(1)   // 성공 방출 한 번만
            .subscribe(onNext: { list in
                gotPrefixs = list
                prefixsExp.fulfill()   // <- 반드시 fulfill!
            })
            .disposed(by: disposeBag)
        
        
        let errorExp = expectation(description: "error set")
        errorExp.isInverted = true;
        output.error$.compactMap{$0}.take(1).subscribe(onNext:{
            error in
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        

        // When
        viewLoaded$.accept(())

        // Then
        wait(for: [apiExp, loadingExp, prefixsExp, errorExp], timeout: 1.0)

        XCTAssertEqual(loadingSeq, [true, false])
        XCTAssertEqual(gotPrefixs?.count, 2)
    }

    
    func test_viewLoaded_failure_setsError_keepsDataEmpty_setsLoadingFalse(){
        
        let apiExp = expectation(description: "api response set")
        placeUsecase.prefixExp = apiExp
        placeUsecase.prefixResult = .failure(.clientError("test-error"))

        let vm = PlaceCharactersBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService: notificationService)
        let viewLoaded$ = PublishRelay<Void>()

        let output = vm.transform(input: .init(
            placeCharacterCellTapped$: .empty(),
            closeButtonTapped$: .empty(),
            viewLoaded$: viewLoaded$.asObservable(),
            refetchButtonTapped$: .empty()
        ))

        var loadingSeq: [Bool] = []
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2

        output.isInitialLoading$
            .take(2) // 초기 true + 완료 후 false
            .subscribe(onNext: { v in
                loadingSeq.append(v)
                loadingExp.fulfill()
            })
            .disposed(by: disposeBag)

  
        let prefixExp = expectation(description: "prefixs set")
        prefixExp.isInverted = true
        output.placeCharacter$
            .skip(1)
            .take(1)
            .subscribe(onNext: { list in
                prefixExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        
        
        var gotError: NetworkError?
        let errorExp = expectation(description: "error set")
        
        output.error$.skip(1).take(1).subscribe(onNext:{
            error in
            gotError = error
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        

        // When
        viewLoaded$.accept(())

        // Then
        wait(for: [apiExp, loadingExp, errorExp, prefixExp], timeout: 1.0)

        XCTAssertEqual(loadingSeq, [true, false])
        XCTAssertEqual(gotError, .clientError("test-error"))
        
        
        
    }
    
    func test_refetch_success_resetsThenEmitsData_andClearsError(){
        let apiExp = expectation(description: "api response set")
        placeUsecase.prefixExp = apiExp
        placeUsecase.prefixResult = .success(
            ListResponse(total: 2, page: 0, limit: -1,
                         data: [PlacePrefix(prefix: "A", placeCount: "10"),
                                PlacePrefix(prefix: "B", placeCount: "10")])
        )

        let vm = PlaceCharactersBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService: notificationService)
        let refetchButtonTapped$ = PublishRelay<Void>()

        let output = vm.transform(input: .init(
            placeCharacterCellTapped$: .empty(),
            closeButtonTapped$: .empty(),
            viewLoaded$: .empty(),
            refetchButtonTapped$: refetchButtonTapped$.asObservable()
        ))

        // 1) 로딩 토글: [true, false]를 정확히 2번 받도록
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

        // 2) prefix 채워졌는지: 초기 [] 무시하고 한 번만 받기
        var gotPrefixsArr: [[PlacePrefix]] = []
        let prefixsExp = expectation(description: "prefixs set")
        prefixsExp.expectedFulfillmentCount = 2;
        output.placeCharacter$
            .skip(1)   // 초기 [] 무시
            .take(2)   // 성공 방출 한 번만
            .subscribe(onNext: { list in
                gotPrefixsArr.append(list)
                prefixsExp.fulfill()   // <- 반드시 fulfill!
            })
            .disposed(by: disposeBag)
        
        
        let errorExp = expectation(description: "error set")
        errorExp.isInverted = true;
        output.error$.compactMap{$0}.take(1).subscribe(onNext:{
            error in
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        

        // When
        refetchButtonTapped$.accept(())

        // Then
        wait(for: [apiExp, loadingExp, prefixsExp, errorExp], timeout: 1.0)

        XCTAssertEqual(loadingSeq, [true, false])
        XCTAssertEqual(gotPrefixsArr[0].count, 0)
        XCTAssertEqual(gotPrefixsArr[1].count, 2)

    }
    
    func test_refetch_failure_resetsThenSetsError_andKeepsData(){
        let apiExp = expectation(description: "api response set")
        placeUsecase.prefixExp = apiExp
        placeUsecase.prefixResult = .failure(.clientError("test-error"))

        let vm = PlaceCharactersBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService: notificationService)
        let refetchButtonTapped$ = PublishRelay<Void>()

        let output = vm.transform(input: .init(
            placeCharacterCellTapped$: .empty(),
            closeButtonTapped$: .empty(),
            viewLoaded$: .empty(),
            refetchButtonTapped$: refetchButtonTapped$.asObservable()
        ))

        // 1) 로딩 토글: [true, false]를 정확히 2번 받도록
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

        let prefixsExp = expectation(description: "prefixs set")
        prefixsExp.expectedFulfillmentCount = 2;
        prefixsExp.isInverted = true
        output.placeCharacter$
            .skip(1)   // 초기 [] 무시
            .take(2)   // 성공 방출 한 번만
            .subscribe(onNext: { list in
                prefixsExp.fulfill()   // <- 반드시 fulfill!
            })
            .disposed(by: disposeBag)
        
        var gotError:NetworkError?
        let errorExp = expectation(description: "error set")

        output.error$.compactMap{$0}.take(1).subscribe(onNext:{
            error in
            gotError = error;
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        

        // When
        refetchButtonTapped$.accept(())

        // Then
        wait(for: [apiExp, loadingExp, prefixsExp, errorExp], timeout: 1.0)

        XCTAssertEqual(loadingSeq, [true, false])
        XCTAssertEqual(gotError, .clientError("test-error"))

        
    }
    
    
    func test_placeCharacterCellTapped_presentsPlacesByCharacter(){
        let vm = PlaceCharactersBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService: notificationService)
        let placeCharacterCellTapped$ = PublishRelay<String>()

        let _ = vm.transform(input: .init(
            placeCharacterCellTapped$: placeCharacterCellTapped$.asObservable(),
            closeButtonTapped$: .empty(),
            viewLoaded$: .empty(),
            refetchButtonTapped$: .empty()
        ))
        
        
        let character = "A"
        placeCharacterCellTapped$.accept(character)
        
        XCTAssertEqual(navigator.presentedSheet, .placesByCharacter(character))
        
    }
    
    
    func test_closeButtonTapped_dismisses(){
        
        let vm = PlaceCharactersBottomSheetViewModel(navigator: navigator, placeUsecase: placeUsecase, notificationService: notificationService)
        let closeButtonTapped$ = PublishRelay<Void>()

        let _ = vm.transform(input: .init(
            placeCharacterCellTapped$: .empty(),
            closeButtonTapped$: closeButtonTapped$.asObservable(),
            viewLoaded$: .empty(),
            refetchButtonTapped$: .empty()
        ))
        
        
        closeButtonTapped$.accept(())
        XCTAssertTrue(navigator.isDismissed)
        
    }
    
}
