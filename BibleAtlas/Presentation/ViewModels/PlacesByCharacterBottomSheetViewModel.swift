//
//  PlacesByCharacterBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/15/25.
//

import Foundation
import RxSwift
import RxRelay

protocol PlacesByCharacterBottomSheetViewModelProtocol {
    
    func transform(input:PlacesByCharacterBottomSheetViewModel.Input) -> PlacesByCharacterBottomSheetViewModel.Output
}


final class PlacesByCharacterBottomSheetViewModel:PlacesByCharacterBottomSheetViewModelProtocol{
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private let placesResponse$ = PublishRelay<[Place]>();
    private let error$ = PublishRelay<String>()
    private let character$ = BehaviorRelay<String>(value: "")

    private var character:String
    
    init(navigator:BottomSheetNavigator?, character:String){
        self.navigator = navigator;
        self.character = character;
        self.character$.accept(character)
    }
    
    func transform(input: Input) -> Output {
        input.placeCellTapped$.subscribe(onNext: { [weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId))
        }).disposed(by: disposeBag)
        
        input.bottomReached$.subscribe(onNext: {
            [weak self] in
            // fetch more data from server
        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {[weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        return Output(placesReponse$: placesResponse$.asObservable(), error$: error$.asObservable(), character$: character$.asObservable())
        
    }

    public struct Input{
        let placeCellTapped$:Observable<String>
        let closeButtonTapped$:Observable<Void>
        let bottomReached$:Observable<Void>
    }
    
    
    public struct Output {
        let placesReponse$:Observable<[Place]>
        let error$:Observable<String>
        let character$:Observable<String>
    }
    
    
}
