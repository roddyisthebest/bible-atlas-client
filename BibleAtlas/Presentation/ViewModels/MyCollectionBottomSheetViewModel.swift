//
//  MyCollectionBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/1/25.
//

import Foundation
import RxSwift
import RxRelay

protocol MyCollectionBottomSheetViewModelProtocol{
    func transform(input:MyCollectionBottomSheetViewModel.Input) -> MyCollectionBottomSheetViewModel.Output
}

final class MyCollectionBottomSheetViewModel:MyCollectionBottomSheetViewModelProtocol{
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    

    
    private let placesResponse$ = PublishRelay<Any>();
    private let error$ = PublishRelay<String>()
    private let type$: BehaviorRelay<MyCollectionType>

    
    private var type:MyCollectionType

    init(navigator:BottomSheetNavigator?, type:MyCollectionType){
        self.navigator = navigator
        self.type = type;
        self.type$ = BehaviorRelay(value: type)
    }
        
    func transform(input:Input) -> Output{
        input.bottomReached$.subscribe(onNext: {
            [weak self] in
            
        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        input.placeTabelCellSelected$.subscribe(onNext:{ [weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId))

        }).disposed(by:disposeBag)
        
        
        return Output(placesResponse$: placesResponse$.asObservable(), error$: error$.asObservable(), type$: type$.asObservable())
    }
    
    
    public struct Input {
        let closeButtonTapped$:Observable<Void>
        let placeTabelCellSelected$:Observable<String>
        let bottomReached$:Observable<Void>
    }
    
    public struct Output{
        let placesResponse$:Observable<Any>
        let error$:Observable<String>
        let type$:Observable<MyCollectionType>;
    }
}
