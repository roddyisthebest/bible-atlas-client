//
//  HomeBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/28/25.
//

import Foundation
import RxSwift
import RxRelay

protocol HomeBottomSheetViewModelProtocol {
    func transform(input:HomeBottomSheetViewModel.Input) -> Void
    
}

final class HomeBottomSheetViewModel:HomeBottomSheetViewModelProtocol {
        
    private let disposeBag = DisposeBag();

    private weak var navigator: BottomSheetNavigator?
    
    init(navigator:BottomSheetNavigator?){
        self.navigator = navigator
    }
    
    func transform(input: Input) {
        input.avatarButtonTapped$.subscribe(onNext: {
            [weak self] in
                self?.navigator?.present(.login)
        }).disposed(by: disposeBag)
        
        input.collectionButtonTapped$.subscribe(onNext: { [weak self] collectionType in
            self?.navigator?.present(.myCollection(collectionType))
        }).disposed(by: disposeBag)
    }
    
    public struct Input {
        let avatarButtonTapped$:Observable<Void>
        let collectionButtonTapped$:Observable<MyCollectionType>
    }
    
  
    
    
}
