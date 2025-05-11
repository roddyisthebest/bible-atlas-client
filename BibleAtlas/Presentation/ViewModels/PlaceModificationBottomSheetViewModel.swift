//
//  PlaceUpdateBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import Foundation
import RxSwift
import RxRelay

protocol PlaceModificationBottomSheetViewModelProtocol {
    func transform(input:PlaceModificationBottomSheetViewModel.Input)
}

final class PlaceModificationBottomSheetViewModel:PlaceModificationBottomSheetViewModelProtocol {
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private var placeId:String? = nil
    
    init(navigator:BottomSheetNavigator?, placeId:String){
        self.navigator = navigator
        self.placeId = placeId;
    }
    
    
    func transform(input:Input) {
        input.confirmButtonTapped$.subscribe(onNext: { [weak self] text in print("\(text)")}).disposed(by: disposeBag)

        
        input.cancelButtonTapped$.subscribe(onNext: {
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
    }
    
    public struct Input {
        let cancelButtonTapped$:Observable<Void>
        let confirmButtonTapped$:Observable<String>
    }
    
        
    
}
