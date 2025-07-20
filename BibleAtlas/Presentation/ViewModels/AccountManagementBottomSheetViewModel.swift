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
    private let withdrawalButtonTapped$ = PublishRelay<Void>();

    private let menuItemCellTapped$ = PublishRelay<SimpleMenuItem>();
    
    
    public let menuItems:[SimpleMenuItem] = [
        SimpleMenuItem(id: .navigateCS, nameText: "고객센터 문의하기", isMovable: true),
        SimpleMenuItem(id: .navigatePROFILE, nameText: "프로필 수정", isMovable: true),
        SimpleMenuItem(id: .logout, nameText: "로그아웃", isMovable: false),
        SimpleMenuItem(id: .withdrawal, nameText: "회원탈퇴", isMovable: false)
    ]
    
    
    init(navigator: BottomSheetNavigator?, appStore: AppStoreProtocol?, appCoordinator:AppCoordinatorProtocol?) {
        self.navigator = navigator
        self.appStore = appStore
        self.appCoordinator = appCoordinator
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
                    self?.withdrawalButtonTapped$.accept(())
                case .navigateCS:
                    print("navigateCS")
                case .navigatePROFILE:
                    print("navigatePROFILE")

            }
            
        }.disposed(by: disposeBag)
        
        return Output(profile$: profile$.asObservable(), withdrawalButtonTapped$: withdrawalButtonTapped$.asObservable())
    }
    
    public struct Input {
        let closeButtonTapped$:Observable<Void>
        let menuItemCellTapped$:Observable<SimpleMenuItem>
    }
    
    public struct Output{
        let profile$:Observable<User?>
        let withdrawalButtonTapped$:Observable<Void>
    }
}
