//
//  PlacesByCharacterBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import Foundation
import RxSwift

protocol PlacesByCharacterBottomSheetViewModelProtocol {
    func transform(input:PlacesByCharacterBottomSheetViewModel.Input)

}

final class PlacesByCharacterBottomSheetViewModel:PlacesByCharacterBottomSheetViewModelProtocol{
    func transform(input: Input) {
        
        input.placeCharacterCellTapped$.subscribe(onNext: {[weak self] character in
            print(character, "character")
        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {[weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
    }
    
    
    private let disposeBag = DisposeBag();
    private weak var navigator:BottomSheetNavigator?
        
    init(navigator:BottomSheetNavigator?){
        self.navigator = navigator
    }
    
    public struct Input {
        let placeCharacterCellTapped$:Observable<String>
        let closeButtonTapped$:Observable<Void>
    }
    
}
