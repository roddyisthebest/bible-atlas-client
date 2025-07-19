//
//  MyPageBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/16/25.
//

import Foundation
import RxSwift
import RxRelay
protocol MyPageBottomSheetViewModelProtocol{
    
    var menuItems: [MenuItem] { get }
    
    func transform(input:MyPageBottomSheetViewModel.Input) -> MyPageBottomSheetViewModel.Output
}

final class MyPageBottomSheetViewModel:MyPageBottomSheetViewModelProtocol{
    
    public let menuItems:[MenuItem] =
    [
        MenuItem(nameText: "계정관리", iconImage: "person.fill", iconBackground: .mainText, bottomSheetType: .accountManagement),
        MenuItem(nameText: "리포트", iconImage: "exclamationmark.bubble.fill", iconBackground: .primaryRed),
        MenuItem(nameText:"앱 버전", iconImage: "v.circle.fill", iconBackground: .primaryViolet, contentText: "1.0.0")
    ]
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private var appStore:AppStoreProtocol?

    private var profile$ = BehaviorRelay<User?>(value:nil)

    
    
    init(navigator: BottomSheetNavigator?, appStore: AppStoreProtocol?) {
        self.navigator = navigator
        self.appStore = appStore
        
        bindAppStore();
    }
    
    
    func transform(input:Input) -> Output {
                
        input.closeButtonTapped$.bind{
            [weak self] in self?.navigator?.dismiss(animated: true)
        }.disposed(by: disposeBag)
        
        input.menuItemCellTapped$.bind{
            [weak self] itemCell in
            
            guard let bottomSheetType = itemCell.bottomSheetType else {
                return;
            }
            
            self?.navigator?.present(bottomSheetType)
        }.disposed(by: disposeBag)
        
        return Output(profile$: profile$.asObservable())
    }
    
    private func bindAppStore(){
        appStore?.state$.bind{
            [weak self] state in
            self?.profile$.accept(state.profile)
                
        }.disposed(by: disposeBag)
    }
    
    public struct Input {
        let closeButtonTapped$:Observable<Void>
        let menuItemCellTapped$:Observable<MenuItem>
    }
    
    public struct Output {
        let profile$:Observable<User?>
    }
    
    
}
