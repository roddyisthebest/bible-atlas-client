//
//  MemoBottomSheetViewModelTests.swift
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


final class MemoBottomSheetViewModelTests: XCTestCase {

    var placeUsecase:MockPlaceusecase!
    var notificationService:MockNotificationService!
    var collectionStore: MockCollectionStore!
    var navigator: MockBottomSheetNavigator!

    var disposeBag:DisposeBag!
    var placeId:String = "test-place-id"
    
    override func setUp() {
        super.setUp();
        
        self.placeUsecase = MockPlaceusecase();
        self.notificationService = MockNotificationService()
        self.collectionStore = MockCollectionStore();
        self.navigator = MockBottomSheetNavigator();
        self.disposeBag = DisposeBag()
    }
    
    func test_viewLoaded_success_shouldToggleLoading_andSetMemo()
    {
        
        let exp = expectation(description: "place from server set")
        let memoText = "hello tester! so what do we do. maybe we have to move to the next step"
        let place = Place(id: placeId, name: "test", isModern: false, description: "hello", koreanDescription: "안녕", stereo: .child, likeCount: 0, types: [], memo:PlaceMemo(user: -1, place: placeId, text: memoText))
        
        placeUsecase.detailResultToReturn = .success(place)
        placeUsecase.completedDetailExp = exp;
        
        
        
        
        let vm = MemoBottomSheetViewModel(navigator: navigator, placeId: placeId, placeUsecase: placeUsecase, collectionStore: collectionStore, notificationService: notificationService)
        
        let viewLoaded$ = PublishRelay<Void>();
        let output = vm.transform(input: MemoBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: .empty(), cancelButtonTapped$: .empty(), confirmButtonTapped$: .empty(), deleteButtonTapped$: .empty()))
        
        
        var gotIsLoadingHistories:[Bool] = []
        let loadingExp = expectation(description: "loading toggle");
        loadingExp.expectedFulfillmentCount = 2;

        output.isLoading$.skip(1).take(2).subscribe(onNext:{
            isLoading in
            gotIsLoadingHistories.append(isLoading)
            loadingExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        var gotMemo:String?
        let memoExp = expectation(description: "memo set");

        
        output.memo$.skip(1).take(1).subscribe(onNext:{
            memo in
            gotMemo = memo
            memoExp.fulfill()
        }).disposed(by: disposeBag)
            
        
        viewLoaded$.accept(())
        
        wait(for:[exp, loadingExp, memoExp], timeout: 1.0)
        
        
        XCTAssertEqual(gotIsLoadingHistories, [true, false])
        XCTAssertEqual(gotMemo, memoText)
        
        
    }
    

    func test_viewLoaded_failure_shouldToggleLoading_andEmitLoadError(){
        
        let exp = expectation(description: "error from server set")

        
        let error:NetworkError = .clientError("test-error")
        placeUsecase.detailResultToReturn = .failure(error)
        placeUsecase.completedDetailExp = exp;
        
        let vm = MemoBottomSheetViewModel(navigator: navigator, placeId: placeId, placeUsecase: placeUsecase, collectionStore: collectionStore, notificationService: notificationService)
        
        let viewLoaded$ = PublishRelay<Void>();
        let output = vm.transform(input: MemoBottomSheetViewModel.Input(viewLoaded$: viewLoaded$.asObservable(), refetchButtonTapped$: .empty(), cancelButtonTapped$: .empty(), confirmButtonTapped$: .empty(), deleteButtonTapped$: .empty()))
        
        
        var gotIsLoadingHistories:[Bool] = []
        let loadingExp = expectation(description: "loading toggle");
        loadingExp.expectedFulfillmentCount = 2;

        output.isLoading$.skip(1).take(2).subscribe(onNext:{
            isLoading in
            gotIsLoadingHistories.append(isLoading)
            loadingExp.fulfill()
        }).disposed(by: disposeBag)
        
        
   
        var gotError:NetworkError?
        let errorExp = expectation(description: "error set");

        
        output.loadError$.skip(2).take(1).subscribe(onNext:{
            error in
            gotError = error
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        viewLoaded$.accept(())
        
        wait(for:[exp, loadingExp, errorExp], timeout: 1.0)
        
        XCTAssertEqual(gotIsLoadingHistories, [true, false])
        XCTAssertEqual(gotError, error)
        
        
    }
    
    
    func test_confirm_success_shouldToggleCreating_postRefetch_dispatchAddMemo_andDismiss(){
    
        let text = "yoyo representing gwangjingu yo"
        placeUsecase.createMemoResult = .success(PlaceMemoResponse(text: text))
        let exp = expectation(description: "place memo response set")
        placeUsecase.memoExp = exp;
        
        let vm = MemoBottomSheetViewModel(navigator: navigator, placeId: placeId, placeUsecase: placeUsecase, collectionStore: collectionStore, notificationService: notificationService)
        
        let confirmButtonTapped$ = PublishRelay<String>();
        let output = vm.transform(input: MemoBottomSheetViewModel.Input(viewLoaded$: .empty(), refetchButtonTapped$: .empty(), cancelButtonTapped$: .empty(), confirmButtonTapped$: confirmButtonTapped$.asObservable(), deleteButtonTapped$: .empty()))
        
        
        var gotIsCreatingOrUpdatingHistories:[Bool] = []
        let loadingExp = expectation(description: "isCreatingOrUpdating toggle");
        loadingExp.expectedFulfillmentCount = 2;

        output.isCreatingOrUpdating$.skip(1).take(2).subscribe(onNext:{
            isLoading in
            gotIsCreatingOrUpdatingHistories.append(isLoading)
            loadingExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        confirmButtonTapped$.accept(text)
        
        wait(for:[exp, loadingExp]);
        
        
        
        XCTAssertEqual(gotIsCreatingOrUpdatingHistories, [true, false])
        XCTAssertTrue(navigator.isDismissed)
        XCTAssertEqual(collectionStore.lastAction, .addMemo(placeId))
        XCTAssertEqual(notificationService.calledNotificationName, .refetchRequired)
    }
    
    func test_confirm_failure_shouldToggleCreating_andEmitInteractionError_withoutSideEffects(){
        
        let text = "yoyo representing gwangjingu yo"
        let error:NetworkError = .clientError("test-error")
        placeUsecase.createMemoResult = .failure(error)
        let exp = expectation(description: "place memo error set")
        placeUsecase.memoExp = exp;
        
        let vm = MemoBottomSheetViewModel(navigator: navigator, placeId: placeId, placeUsecase: placeUsecase, collectionStore: collectionStore, notificationService: notificationService)
        
        let confirmButtonTapped$ = PublishRelay<String>();
        let output = vm.transform(input: MemoBottomSheetViewModel.Input(viewLoaded$: .empty(), refetchButtonTapped$: .empty(), cancelButtonTapped$: .empty(), confirmButtonTapped$: confirmButtonTapped$.asObservable(), deleteButtonTapped$: .empty()))
        
        
        var gotIsCreatingOrUpdatingHistories:[Bool] = []
        let loadingExp = expectation(description: "isCreatingOrUpdating toggle");
        loadingExp.expectedFulfillmentCount = 2;

        output.isCreatingOrUpdating$.skip(1).take(2).subscribe(onNext:{
            isLoading in
            gotIsCreatingOrUpdatingHistories.append(isLoading)
            loadingExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        var gotError:NetworkError?
        let errorExp = expectation(description: "error set");

        
        output.interactionError$.skip(1).take(1).subscribe(onNext:{
            error in
            gotError = error
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        confirmButtonTapped$.accept(text)
        
        wait(for:[exp, loadingExp, errorExp], timeout: 1.0);
        
        XCTAssertEqual(gotIsCreatingOrUpdatingHistories, [true, false])
        XCTAssertEqual(gotError, error)
        
    }
    
    
    func test_delete_success_shouldToggleDeleting_postRefetch_dispatchRemoveMemo_andDismiss(){
        
        let exp = expectation(description: "deleting memo request wait")
        
        placeUsecase.deletePlaceMemoExp = exp;
        placeUsecase.deletePlaceMemoResult = .success(PlaceMemoDeleteResponse(memo:"whoa ha"))
        
        
        let vm = MemoBottomSheetViewModel(navigator: navigator, placeId: placeId, placeUsecase: placeUsecase, collectionStore: collectionStore, notificationService: notificationService)
        
        let deleteButtonTapped$ = PublishRelay<Void>();
        
        let output = vm.transform(input: MemoBottomSheetViewModel.Input(viewLoaded$: .empty(), refetchButtonTapped$: .empty(), cancelButtonTapped$: .empty(), confirmButtonTapped$: .empty(), deleteButtonTapped$: deleteButtonTapped$.asObservable()))
        
        var gotIsDeletingHistories:[Bool] = []
        let deletingExp = expectation(description: "isDeleting toggle");
        deletingExp.expectedFulfillmentCount = 2;

        output.isDeleting$.skip(1).take(2).subscribe(onNext:{
            isLoading in
            gotIsDeletingHistories.append(isLoading)
            deletingExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        
        deleteButtonTapped$.accept(())
        
        
        wait(for:[exp, deletingExp])
        
        
        XCTAssertEqual(gotIsDeletingHistories, [true, false])
        XCTAssertEqual(notificationService.calledNotificationName, .refetchRequired)
        XCTAssertEqual(collectionStore.lastAction, .removeMemo(placeId))
        XCTAssertTrue(navigator.isDismissed)
    }


}
