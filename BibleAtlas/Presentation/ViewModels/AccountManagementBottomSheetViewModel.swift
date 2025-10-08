//
//  UserManagementBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/18/25.
//

import Foundation
import RxSwift
import RxRelay

protocol AccountManagementBottomSheetViewModelProtocol{
    func transform(input:AccountManagementBottomSheetViewModel.Input) -> AccountManagementBottomSheetViewModel.Output
    
    var menuItems: [SimpleMenuItem] { get }

}

final class AccountManagementBottomSheetViewModel:AccountManagementBottomSheetViewModelProtocol{
        
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    private weak var appCoordinator: AppCoordinatorProtocol?

    private var appStore:AppStoreProtocol?
    
    
    private var profile$ = BehaviorRelay<User?>(value:nil)
    
    private let cancelButtonTapped$ = PublishRelay<Void>();

    
    private let isWithdrawing$ = BehaviorRelay<Bool>(value:false);
    private let error$ = BehaviorRelay<NetworkError?>(value: nil);
    
    private let menuItemCellTapped$ = PublishRelay<SimpleMenuItem>();
    
    private let showWithdrawConfirm$ = PublishRelay<Void>();
    private let showWithdrawComplete$ = PublishRelay<Void>();

    
    
    private let authUsecase:AuthUsecaseProtocol?

    
    
    
    public let menuItems:[SimpleMenuItem] = [
           SimpleMenuItem(id: .navigateCS,   nameText: L10n.AccountManagement.contactSupport, isMovable: true),
           // SimpleMenuItem(id: .navigatePROFILE, nameText: L10n.AccountManagement.profileEdit, isMovable: true), // 추후 필요시
           SimpleMenuItem(id: .logout,       nameText: L10n.AccountManagement.logout, isMovable: false),
           SimpleMenuItem(id: .withdrawal,   nameText: L10n.AccountManagement.withdraw, isMovable: false, textColor: .primaryRed)
       ]
    
    
    init(navigator: BottomSheetNavigator?, appStore: AppStoreProtocol?, appCoordinator:AppCoordinatorProtocol?, authUsecase:AuthUsecaseProtocol?) {
        self.navigator = navigator
        self.appStore = appStore
        self.appCoordinator = appCoordinator
        self.authUsecase = authUsecase
        bindAppStore();
    }
    
    
    private func bindAppStore(){
        appStore?.state$.bind{
            [weak self] state in
            self?.profile$.accept(state.profile)
                
        }.disposed(by: disposeBag)
    }
    
    
    func transform(input:Input) -> Output {
        input.closeButtonTapped$.bind{
            [weak self] in self?.navigator?.dismiss(animated: true)
        }.disposed(by: disposeBag)
        
        input.menuItemCellTapped$.bind{
            [weak self] menuItem in
            switch(menuItem.id){
                case .logout:
                    self?.appCoordinator?.logout();
                case .withdrawal:
                    self?.showWithdrawConfirm$.accept(())
                case .navigateCS:
                    print("navigateCS")
                case .navigatePROFILE:
                    print("navigatePROFILE")

            }
            
        }.disposed(by: disposeBag)
        
        input.withdrawConfirmButtonTapped$.bind{
            [weak self] in
            self?.withdraw();
            
        }.disposed(by: disposeBag)
        
        input.withdrawCompleteConfirmButtonTapped$.bind{
            [weak self] in
            self?.appCoordinator?.logout();
        }.disposed(by: disposeBag)
        
        
        return Output(error$: error$.asObservable(), isWithdrawing$: isWithdrawing$.asObservable(), showWithdrawConfirm$: showWithdrawConfirm$.asObservable(), showWithdrawComplete$: showWithdrawComplete$.asObservable())
    }
    
    
    private func withdraw(){
        error$.accept(nil)
        isWithdrawing$.accept(true)
        Task{
            defer{
                isWithdrawing$.accept(false)
            }
            
            guard let result = await self.authUsecase?.withdraw() else {
                return
            };
            
            switch(result){
            case .success:
                self.showWithdrawComplete$.accept(());
                
            case .failure(let error):
                self.error$.accept(error)
            }
            
        }
    }
    
    public struct Input {
        let closeButtonTapped$:Observable<Void>
        let menuItemCellTapped$:Observable<SimpleMenuItem>
        let withdrawConfirmButtonTapped$:Observable<Void>
        let withdrawCompleteConfirmButtonTapped$:Observable<Void>

    }
    
    public struct Output{
        let error$:Observable<NetworkError?>
        let isWithdrawing$:Observable<Bool>
        let showWithdrawConfirm$: Observable<Void>
        let showWithdrawComplete$: Observable<Void>
    }
}
