//
//  GuardViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/19/25.
//

import RxSwift
import RxRelay

protocol GuardableViewModelProtocol: AnyObject {
    var disposeBag: DisposeBag { get }
    func bindAuthGuard(appState$: Observable<AppState>?, navigator: BottomSheetNavigator?)
}


extension GuardableViewModelProtocol {
    func bindAuthGuard(appState$: Observable<AppState>?, navigator: BottomSheetNavigator?) {
        
        guard let appState$ = appState$ else {
            return;
        }
        
        appState$
            .map { $0.isLoggedIn }
            .bind { isLoggedIn in
                
                
                if !isLoggedIn {
                    navigator?.dismiss(animated: true)
                }
            }
            .disposed(by: disposeBag)
    }
}
