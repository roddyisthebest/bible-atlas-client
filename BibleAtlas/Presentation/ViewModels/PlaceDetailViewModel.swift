//
//  PlaceDetailViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/3/25.
//

import Foundation
import RxSwift
import RxRelay

protocol PlaceDetailViewModelProtocol {
    func transform(input:PlaceDetailViewModel.Input) -> PlaceDetailViewModel.Output
}

final class PlaceDetailViewModel:PlaceDetailViewModelProtocol{
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private let placeResponse$ = PublishRelay<Place>();

    func transform(input: Input) -> Output {
        input.placeDetailViewLoaded$.subscribe(onNext:{
            [weak self] in
            
        }).disposed(by: disposeBag)
        
        return Output(placeData$: placeResponse$.asObservable())
        
    }
    
    
    
    init(navigator:BottomSheetNavigator?){
        self.navigator = navigator
    }
    
    public struct Input {
        let placeDetailViewLoaded$:Observable<Void>
        let saveButtonTapped$:Observable<Void>
        let shareButtonTapped$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
        let likeButtonTapped$:Observable<Void>
        let verseButtonTapped$:Observable<String>
        let memoButtonTapped$:Observable<Void>
    }
    
    public struct Output{
        let placeData$:Observable<Place>
        
    }
    
    
}
