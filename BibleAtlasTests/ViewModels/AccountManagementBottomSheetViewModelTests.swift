//
//  AccountManagementBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/18/25.
//

import XCTest
import RxRelay
import RxTest
import RxBlocking
import RxSwift

@testable import BibleAtlas

final class AccountManagementBottomSheetViewModelTests: XCTestCase {
        
    var navigator: MockBottomSheetNavigator!
    var appStore: MockAppStore!
    var authUsecase:MockAuthUsecase!
    var appCoordinator: MockAppCoordinator!
    
    var disposeBag:DisposeBag!
    
    override func setUp()  {
        super.setUp()
        
        navigator = MockBottomSheetNavigator();
        appStore = MockAppStore(state: AppState(profile: nil, isLoggedIn: false))
        authUsecase = MockAuthUsecase();
        appCoordinator = MockAppCoordinator()
        disposeBag = DisposeBag();
    }
    
    
    
    func test_closeButtonTapped_dismisses(){
        let vm = AccountManagementBottomSheetViewModel(navigator: navigator, appStore: appStore, appCoordinator: appCoordinator, authUsecase: authUsecase)
        
        let closeButtonTapped$ = PublishRelay<Void>();
        
        let _ = vm.transform(input: AccountManagementBottomSheetViewModel.Input(closeButtonTapped$: closeButtonTapped$.asObservable(), menuItemCellTapped$: .empty(), withdrawConfirmButtonTapped$: .empty(), withdrawCompleteConfirmButtonTapped$: .empty()))
        
        closeButtonTapped$.accept(())
        
        
        XCTAssertTrue(navigator.isDismissed)
        
        
    }
    
    
    func test_menuItemCellTapped_logout_callsAppCoordinatorLogout(){
        authUsecase.logoutResultToReturn = .success(())
        let vm = AccountManagementBottomSheetViewModel(navigator: navigator, appStore: appStore, appCoordinator: appCoordinator, authUsecase: authUsecase)
        
        let menuItemCellTapped$ = PublishRelay<SimpleMenuItem>()
        let _ = vm.transform(input: AccountManagementBottomSheetViewModel.Input(closeButtonTapped$: .empty(), menuItemCellTapped$: menuItemCellTapped$.asObservable(), withdrawConfirmButtonTapped$: .empty(), withdrawCompleteConfirmButtonTapped$: .empty()))
        
        menuItemCellTapped$.accept(SimpleMenuItem(id:.logout, nameText: "logout", isMovable: false))
        
        XCTAssertTrue(appCoordinator.didLogout)
        
    }
    
    func test_menuItemCellTapped_withdrawal_emitsShowWithdrawConfirm(){
        
        let vm = AccountManagementBottomSheetViewModel(navigator: navigator, appStore: appStore, appCoordinator: appCoordinator, authUsecase: authUsecase)
            
        let menuItemCellTapped$ = PublishRelay<SimpleMenuItem>()
        
        let output = vm.transform(input: AccountManagementBottomSheetViewModel.Input(closeButtonTapped$: .empty(), menuItemCellTapped$: menuItemCellTapped$.asObservable(), withdrawConfirmButtonTapped$: .empty(), withdrawCompleteConfirmButtonTapped$: .empty()))
        
        let exp = expectation(description: "showWithdrawConfirm emit")
        
        output.showWithdrawConfirm$.subscribe(onNext:{
            exp.fulfill()
        }).disposed(by: disposeBag)
        
        
        menuItemCellTapped$.accept(SimpleMenuItem(id:.withdrawal, nameText: "withdrawal", isMovable: false))
    
        
        wait(for: [exp],timeout: 1.0)
        
    }
        
    func test_withdrawConfirm_success_togglesWithdrawing_andEmitsComplete_andClearsError(){
        
        authUsecase.withdrawResultToReturn = .success(123)
        
        let vm = AccountManagementBottomSheetViewModel(navigator: navigator, appStore: appStore, appCoordinator: appCoordinator, authUsecase: authUsecase)
        
        let withdrawConfirmButtonTapped$ = PublishRelay<Void>();
        
        
        let output = vm.transform(input: AccountManagementBottomSheetViewModel.Input(closeButtonTapped$: .empty(), menuItemCellTapped$: .empty(), withdrawConfirmButtonTapped$: withdrawConfirmButtonTapped$.asObservable(), withdrawCompleteConfirmButtonTapped$: .empty()))
        
        let showWithdrawCompleteExp = expectation(description: "showWithdrawComplete emit")
        
        var isEmitted = false
        
        output.showWithdrawComplete$.subscribe(onNext:{
            isEmitted = true
            showWithdrawCompleteExp.fulfill()

        }).disposed(by: disposeBag)
        
        let errorExp = expectation(description: "error emit")
        errorExp.isInverted = true
        output.error$.skip(2).subscribe(onNext:{ error in
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        let isWithdrawingExp = expectation(description: "isWithdrawing toggle")
        var withdrawingSeq:[Bool] = []
        isWithdrawingExp.expectedFulfillmentCount = 2
        
        output.isWithdrawing$.skip(1).take(2).subscribe(onNext:{ isWithdrawing in
            withdrawingSeq.append(isWithdrawing)
            isWithdrawingExp.fulfill()
        }).disposed(by: disposeBag)
        
        withdrawConfirmButtonTapped$.accept(())
        
        wait(for:[showWithdrawCompleteExp, isWithdrawingExp, errorExp], timeout: 1.0)
        
        XCTAssertEqual(withdrawingSeq, [true, false])
        XCTAssertTrue(isEmitted)
    }
    
    func test_withdrawConfirm_failure_togglesWithdrawing_andEmitsError(){
        
        let error = NetworkError.clientError("test-error")
        authUsecase.withdrawResultToReturn = .failure(error)
        
        let vm = AccountManagementBottomSheetViewModel(navigator: navigator, appStore: appStore, appCoordinator: appCoordinator, authUsecase: authUsecase)
        
        let withdrawConfirmButtonTapped$ = PublishRelay<Void>();
        
        
        let output = vm.transform(input: AccountManagementBottomSheetViewModel.Input(closeButtonTapped$: .empty(), menuItemCellTapped$: .empty(), withdrawConfirmButtonTapped$: withdrawConfirmButtonTapped$.asObservable(), withdrawCompleteConfirmButtonTapped$: .empty()))
        
        let showWithdrawCompleteExp = expectation(description: "showWithdrawComplete emit")
        showWithdrawCompleteExp.isInverted = true
        var isEmitted = false
        
        output.showWithdrawComplete$.subscribe(onNext:{
            isEmitted = true
            showWithdrawCompleteExp.fulfill()

        }).disposed(by: disposeBag)
        
        var gotError:NetworkError?
        let errorExp = expectation(description: "error emit")
        
        output.error$.skip(2).subscribe(onNext:{ error in
            gotError = error
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        let isWithdrawingExp = expectation(description: "isWithdrawing toggle")
        var withdrawingSeq:[Bool] = []
        isWithdrawingExp.expectedFulfillmentCount = 2
        
        output.isWithdrawing$.skip(1).take(2).subscribe(onNext:{ isWithdrawing in
            withdrawingSeq.append(isWithdrawing)
            isWithdrawingExp.fulfill()
        }).disposed(by: disposeBag)
        
        withdrawConfirmButtonTapped$.accept(())
        
        wait(for:[showWithdrawCompleteExp, isWithdrawingExp, errorExp], timeout: 1.0)
        
        XCTAssertEqual(withdrawingSeq, [true, false])
        XCTAssertFalse(isEmitted)
        XCTAssertEqual(gotError, error)
        
        
    }
    
    
    func test_withdrawCompleteConfirm_callsAppCoordinatorLogout(){
        
        
        let vm = AccountManagementBottomSheetViewModel(navigator: navigator, appStore: appStore, appCoordinator: appCoordinator, authUsecase: authUsecase)
            
        let withdrawCompleteConfirmButtonTapped$ = PublishRelay<Void>()
        
        let _ = vm.transform(input: AccountManagementBottomSheetViewModel.Input(closeButtonTapped$: .empty(), menuItemCellTapped$: .empty(), withdrawConfirmButtonTapped$: .empty(), withdrawCompleteConfirmButtonTapped$: withdrawCompleteConfirmButtonTapped$.asObservable()))
        
        withdrawCompleteConfirmButtonTapped$.accept(())
        
        XCTAssertTrue(appCoordinator.didLogout)
        
        
    }
    
    
    func test_withdraw_startsByClearingPreviousError(){
        let error = NetworkError.clientError("test-error")
        authUsecase.withdrawResultToReturn = .failure(error)
        
        let vm = AccountManagementBottomSheetViewModel(navigator: navigator, appStore: appStore, appCoordinator: appCoordinator, authUsecase: authUsecase)
        
        let withdrawConfirmButtonTapped$ = PublishRelay<Void>();
        
        
        let output = vm.transform(input: AccountManagementBottomSheetViewModel.Input(closeButtonTapped$: .empty(), menuItemCellTapped$: .empty(), withdrawConfirmButtonTapped$: withdrawConfirmButtonTapped$.asObservable(), withdrawCompleteConfirmButtonTapped$: .empty()))
        
        var gotError:NetworkError?
        let errorExp = expectation(description: "error emit")
        
        output.error$.skip(2).take(1).subscribe(onNext:{ error in
            gotError = error
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
    
        withdrawConfirmButtonTapped$.accept(())
        
        wait(for:[errorExp], timeout: 1.0)
        
        XCTAssertEqual(gotError, error)
        
        let errorExp2 = expectation(description: "nil emit")

        output.error$.skip(1).take(1).subscribe(onNext:{ error in
            gotError = error
            errorExp2.fulfill()
        }).disposed(by: disposeBag)
        
        
        withdrawConfirmButtonTapped$.accept(())
        wait(for:[errorExp2], timeout: 1.0)

        XCTAssertNil(gotError)
    }
    
    func test_withdraw_usecaseNil_togglesWithdrawingOnly_noError_noComplete(){
        
        let vm = AccountManagementBottomSheetViewModel(navigator: navigator, appStore: appStore, appCoordinator: appCoordinator, authUsecase: nil)
        
        let withdrawConfirmButtonTapped$ = PublishRelay<Void>();
            
        
        let output = vm.transform(input: AccountManagementBottomSheetViewModel.Input(closeButtonTapped$: .empty(), menuItemCellTapped$: .empty(), withdrawConfirmButtonTapped$: withdrawConfirmButtonTapped$.asObservable(), withdrawCompleteConfirmButtonTapped$: .empty()))
        
        
        let isWithdrawingExp = expectation(description: "isWithdrawing toggle")
        var withdrawingSeq:[Bool] = []
        isWithdrawingExp.expectedFulfillmentCount = 2
        
        output.isWithdrawing$.skip(1).take(2).subscribe(onNext:{ isWithdrawing in
            withdrawingSeq.append(isWithdrawing)
            isWithdrawingExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        let showWithdrawCompleteExp = expectation(description: "showWithdrawComplete emit")
        showWithdrawCompleteExp.isInverted = true
        var isEmitted = false
        
        output.showWithdrawComplete$.subscribe(onNext:{
            isEmitted = true
            showWithdrawCompleteExp.fulfill()

        }).disposed(by: disposeBag)
        
        let errorExp = expectation(description: "error emit")
        errorExp.isInverted = true
        output.error$.skip(2).subscribe(onNext:{ error in
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        
        withdrawConfirmButtonTapped$.accept(())
        wait(for:[showWithdrawCompleteExp, errorExp, isWithdrawingExp], timeout: 1.0)
        XCTAssertEqual(withdrawingSeq, [true ,false])
        XCTAssertFalse(isEmitted)
        
        
    }
}
