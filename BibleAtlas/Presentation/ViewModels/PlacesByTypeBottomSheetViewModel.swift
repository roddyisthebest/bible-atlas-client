//
//  PlacesByTypeBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/15/25.
//

import Foundation
import RxSwift
import RxRelay

protocol PlacesByTypeBottomSheetViewModelProtocol {
    func transform(input:PlacesByTypeBottomSheetViewModel.Input) -> PlacesByTypeBottomSheetViewModel.Output
}

final class PlacesByTypeBottomSheetViewModel:PlacesByTypeBottomSheetViewModelProtocol{

    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    
    private let placesResponse$ = PublishRelay<[Place]>();
    private let error$ = PublishRelay<String>()
    private let type$ = PublishRelay<PlaceType>()
    
    private var typeId:Int

    
    init(navigator:BottomSheetNavigator?, typeId:Int){
        self.navigator = navigator;
        self.typeId = typeId;
    }
    
    
    func transform(input: Input) -> Output {
        
        
        input.placeCellTapped$.subscribe(onNext: { [weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId, nil))
        }).disposed(by: disposeBag)
        
        input.bottomReached$.subscribe(onNext: {
            [weak self] in
            // fetch more data from server
        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {[weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        input.textFieldTyped$.subscribe(onNext: {[weak self] text in
            print(text,"text")
            // fetch data using text query from server
        })
        
        return Output(placesReponse$: placesResponse$.asObservable(), error$: error$.asObservable(), type$: type$.asObservable())
    }
    
    public struct Input{
        let placeCellTapped$:Observable<String>
        let closeButtonTapped$:Observable<Void>
        let textFieldTyped$: Observable<String?>
        let bottomReached$:Observable<Void>
    }
    
    
    public struct Output {
        let placesReponse$:Observable<[Place]>
        let error$:Observable<String>
        let type$:Observable<PlaceType>
    }
    
    
}
