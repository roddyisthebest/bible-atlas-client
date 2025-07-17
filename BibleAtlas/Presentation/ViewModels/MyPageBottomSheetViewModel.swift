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
    func transform(input:MyPageBottomSheetViewModel.Input) -> MyPageBottomSheetViewModel.Output
}

final class MyPageBottomSheetViewModel:MyPageBottomSheetViewModelProtocol{
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private var appStore:AppStoreProtocol?

    private var profile$ = BehaviorRelay<User?>(value:nil)
    public let cancelButtonTapped$ = PublishRelay<Void>();

    init(navigator: BottomSheetNavigator?, appStore: AppStoreProtocol?) {
        self.navigator = navigator
        self.appStore = appStore
        
        bindAppStore();
    }
    
    
    func transform(input:Input) -> Output {
                
        input.closeButtonTapped$.bind{
            [weak self] in self?.navigator?.dismiss(animated: true)
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
    }
    
    public struct Output {
        let profile$:Observable<User?>
    }
    
    
}
