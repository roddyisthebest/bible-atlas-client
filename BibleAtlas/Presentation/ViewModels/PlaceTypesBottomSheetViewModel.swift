//
//  PlacesByTypeBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import Foundation
import RxSwift

protocol PlaceTypesBottomSheetViewModelProtocol {
    func transform(input:PlaceTypesBottomSheetViewModel.Input)
}

final class PlaceTypesBottomSheetViewModel:PlaceTypesBottomSheetViewModelProtocol {
    
    func transform(input: Input) {
        input.placeTypeCellTapped$.subscribe(onNext: {[weak self] placeTypeId in
            self?.navigator?.present(.placesByType(placeTypeId))
        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {[weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
    }
    
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    init(navigator:BottomSheetNavigator?){
        self.navigator = navigator
    }
    
    public struct Input {
        let placeTypeCellTapped$:Observable<Int>
        let closeButtonTapped$:Observable<Void>
    }
    
}
