//
//  PlaceModificationBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/16/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas


final class PlaceModificationBottomSheetViewModelTests:XCTestCase{
    
    var navigator: MockBottomSheetNavigator!
    var placeUsecase: MockPlaceusecase!
    var schedular: TestScheduler!
    var disposeBag: DisposeBag!
    
    override func setUp()  {
        super.setUp();
        
        self.navigator = MockBottomSheetNavigator();
        self.placeUsecase = MockPlaceusecase();
        self.schedular = TestScheduler(initialClock: 0);
        self.disposeBag = DisposeBag();
    }
    
    
    func test_confirm_success_togglesCreating_setsSuccessTrue_and_noError(){
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 1, types: [])
        
        let proposalExp = expectation(description: "create proposal")
        
        placeUsecase.proposalExp = proposalExp;
        placeUsecase.proposalResultToReturn = .success(PlaceProposalResponse(createdAt: "", id: 1, type: 2, comment: "test-proposal"))
        
        
        let vm = PlaceModificationBottomSheetViewModel(navigator: navigator, placeId: place.id, placeUsecase: placeUsecase)
        
        let confirmButtonTapped$ = PublishRelay<String>();
        
        let output = vm.transform(input: PlaceModificationBottomSheetViewModel.Input(cancelButtonTapped$: .empty(), confirmButtonTapped$: confirmButtonTapped$.asObservable()))
        
        var gotIsSuccess:Bool?
        let isSuccessSetExp = expectation(description: "isSuccess set")
        
        output.isSuccess$
            .skip(until:confirmButtonTapped$)
            .subscribe(onNext:{
            isSuccess in
                gotIsSuccess = isSuccess
                isSuccessSetExp.fulfill()
            })
            .disposed(by: disposeBag)
    
        
        let errSetExp = expectation(description: "error set")
        errSetExp.isInverted = true;
        
        output.interactionError$
            .skip(until: confirmButtonTapped$)
            .subscribe(onNext:{
                error in
                errSetExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        let creatingSetExp = expectation(description: "isCreating set")
        creatingSetExp.expectedFulfillmentCount = 2
        
        var gotCreating:[Bool] = []
        output.isCreating$.skip(1).take(2).subscribe(onNext:{
            isCreating in
            gotCreating.append(isCreating)
            creatingSetExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        confirmButtonTapped$.accept(place.id)
        
        wait(for: [isSuccessSetExp, proposalExp, errSetExp, creatingSetExp], timeout: 1);
        XCTAssertEqual(gotIsSuccess, true)
        XCTAssertEqual(gotCreating, [true, false])
        
    }
    
    
    
    func test_confirm_failure_togglesCreating_emitsInteractionError_and_successRemainsNil(){
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 1, types: [])
        
        let proposalExp = expectation(description: "create proposal")
        
        placeUsecase.proposalExp = proposalExp;
        placeUsecase.proposalResultToReturn = .failure(.clientError("test-error"))
        
        
        let vm = PlaceModificationBottomSheetViewModel(navigator: navigator, placeId: place.id, placeUsecase: placeUsecase)
        
        let confirmButtonTapped$ = PublishRelay<String>();
        
        let output = vm.transform(input: PlaceModificationBottomSheetViewModel.Input(cancelButtonTapped$: .empty(), confirmButtonTapped$: confirmButtonTapped$.asObservable()))
        

        let isSuccessSetExp = expectation(description: "isSuccess set")
        isSuccessSetExp.isInverted = true
        
        output.isSuccess$
            .skip(until:confirmButtonTapped$)
            .subscribe(onNext:{
            isSuccess in
                isSuccessSetExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        let errorSetExp = expectation(description: "error set")
        var gotErr:NetworkError?
        
        output.interactionError$
            .skip(until: confirmButtonTapped$)
            .subscribe(onNext:{
                error in
                gotErr = error
                errorSetExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        
        let creatingSetExp = expectation(description: "isCreating set")
        creatingSetExp.expectedFulfillmentCount = 2
        
        var gotCreating:[Bool] = []
        output.isCreating$
            .skip(1)
            .take(2).subscribe(onNext:{
            isCreating in
            gotCreating.append(isCreating)
            creatingSetExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        confirmButtonTapped$.accept(place.id)
        
        
        wait(for: [errorSetExp, isSuccessSetExp, proposalExp, creatingSetExp], timeout: 1)
        
        
        XCTAssertEqual(gotErr, .clientError("test-error"))
        XCTAssertEqual(gotCreating, [true, false])
    }
    
    func test_cancelButton_dismisses_and_noSideEffects(){
        
        let vm = PlaceModificationBottomSheetViewModel(navigator: navigator, placeId: "test", placeUsecase: placeUsecase)
        
        let cancelButtonTapped$ = PublishRelay<Void>();
        
        let _ = vm.transform(input: PlaceModificationBottomSheetViewModel.Input(cancelButtonTapped$: cancelButtonTapped$.asObservable(), confirmButtonTapped$: .empty()))
        
        cancelButtonTapped$.accept(())
        
        XCTAssertEqual(navigator.isDismissed, true)
        
    }
    
    func test_confirm_callsCreatePlaceProposal_withCorrectArguments(){
        let proposalExp = expectation(description: "create proposal")
        placeUsecase.proposalExp = proposalExp
        
        let placeId = "test"
        
        let vm = PlaceModificationBottomSheetViewModel(navigator: navigator, placeId: placeId, placeUsecase: placeUsecase)
        let confirmButtonTapped$ = PublishRelay<String>();
        
        let _ = vm.transform(input: PlaceModificationBottomSheetViewModel.Input(cancelButtonTapped$: .empty(), confirmButtonTapped$: confirmButtonTapped$.asObservable()))
        
        let comment = "test-comment"
        confirmButtonTapped$.accept(comment)
        
        wait(for: [proposalExp], timeout: 1);
        
        XCTAssertEqual(placeUsecase.createProposalCallCount, 1)
        XCTAssertEqual(placeUsecase.lastProposalComment, comment)
        XCTAssertEqual(placeUsecase.lastProposalPlaceId, placeId)
        
        
    }
    
    
    func test_confirm_multipleTaps_whileCreating_callsUsecaseOnce() {

        let exp = expectation(description: "proposal called once")
        placeUsecase.proposalExp = exp
        placeUsecase.proposalResultToReturn = .success(
            PlaceProposalResponse(createdAt: "", id: 1, type: 2, comment: "c")
        )

        let vm = PlaceModificationBottomSheetViewModel(
            navigator: navigator, placeId: "test", placeUsecase: placeUsecase
        )
        let cancelButtonTapped$ = PublishRelay<String>()
        let _ = vm.transform(input: .init(
            cancelButtonTapped$: .empty(),
            confirmButtonTapped$: cancelButtonTapped$.asObservable()
        ))

        cancelButtonTapped$.accept("c")
        cancelButtonTapped$.accept("c")

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(placeUsecase.createProposalCallCount, 1)
    }
    
    
    func test_confirm_withEmptyComment_doesNotCallUsecase_andEmitsValidationError() {
   
        let vm = PlaceModificationBottomSheetViewModel(
            navigator: navigator, placeId: "test", placeUsecase: placeUsecase
        )

        let cancelButtonTapped$ = PublishRelay<String>()
        let output = vm.transform(input: .init(
            cancelButtonTapped$: .empty(),
            confirmButtonTapped$: cancelButtonTapped$.asObservable()
        ))


        let errExp = expectation(description: "validation error")
        var got: NetworkError?
        output.interactionError$
            .compactMap { $0 }
            .take(1)
            .subscribe(onNext: { e in got = e; errExp.fulfill() })
            .disposed(by: disposeBag)

        // 실행
        cancelButtonTapped$.accept("   ") // 빈/공백

        wait(for: [errExp], timeout: 1)


        XCTAssertEqual(placeUsecase.createProposalCallCount, 0)
        XCTAssertEqual(got, .clientError("Please enter a comment."))
    }

    
    func test_confirm_retry_afterFailure_succeeds_and_setsSuccessTrue(){
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "test", koreanDescription: "테스트", stereo: .child, likeCount: 1, types: [])
        
        let proposalExp1 = expectation(description: "create proposal1")
        
        placeUsecase.proposalExp = proposalExp1;
        placeUsecase.proposalResultToReturn = .failure(.clientError("test-error"))
        
        
        let vm = PlaceModificationBottomSheetViewModel(navigator: navigator, placeId: place.id, placeUsecase: placeUsecase)
        
        let confirmButtonTapped$ = PublishRelay<String>();
        
        let output = vm.transform(input: PlaceModificationBottomSheetViewModel.Input(cancelButtonTapped$: .empty(), confirmButtonTapped$: confirmButtonTapped$.asObservable()))
    
        
        let errorSetExp = expectation(description: "error set")
        var gotErr:NetworkError?
        
        output.interactionError$
            .skip(until: confirmButtonTapped$)
            .subscribe(onNext:{
                error in
                gotErr = error
                errorSetExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        

        confirmButtonTapped$.accept(place.id)
        
        
        wait(for: [errorSetExp, proposalExp1], timeout: 1)
        XCTAssertEqual(gotErr, .clientError("test-error"))

        let proposalExp2 = expectation(description: "create proposal2")
        
        placeUsecase.proposalExp = proposalExp2;
        placeUsecase.proposalResultToReturn = .success(PlaceProposalResponse(createdAt: "", id: 1, type: 1, comment: "hello"));
        
        
        var gotIsSuccess:Bool?
        let isSuccessSetExp = expectation(description: "isSuccess set")
        
        output.isSuccess$
            .compactMap { $0 }
            .skip(until: confirmButtonTapped$)
            .subscribe(onNext:{
                success in
                gotIsSuccess = success
                isSuccessSetExp.fulfill()
            })
            .disposed(by: disposeBag)
        
        
        confirmButtonTapped$.accept(place.id)

        
        wait(for: [isSuccessSetExp, proposalExp2], timeout: 1)
        XCTAssertEqual(gotIsSuccess, true)

        
    }

    
}
