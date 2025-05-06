//
//  LoginBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/1/25.
//

import Foundation
import RxSwift
import RxRelay

protocol LoginBottomSheetViewModelProtocol {
    func transform(input:LoginBottomSheetViewModel.Input) -> Void
}

final class LoginBottomSheetViewModel:LoginBottomSheetViewModelProtocol {
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    init(navigator:BottomSheetNavigator?){
        self.navigator = navigator
    }
    
    func transform(input: Input) {
        input.googleButtonTapped$.subscribe(onNext: {
            [weak self] in
            
        }).disposed(by: disposeBag)
        
        input.kakaoButtonTapped$.subscribe(onNext: {
            [weak self] in

        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
    }
    
    public struct Input {
        let googleButtonTapped$:Observable<Void>
        let kakaoButtonTapped$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
    }
    
    
}
