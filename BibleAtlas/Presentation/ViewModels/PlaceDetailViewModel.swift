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
    private let placeId:String?
    func transform(input: Input) -> Output {
        input.placeDetailViewLoaded$.subscribe(onNext:{
            [weak self] in
        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext:{[weak self] in self?.navigator?.dismissFromDetail(animated: true )}).disposed(by: disposeBag)
        
        input.likeButtonTapped$.subscribe(onNext: {[weak self] in print("aas")}).disposed(by: disposeBag)
        
        input.placeModificationButtonTapped$.subscribe(onNext: {
            [weak self] in
            guard let placeId = self?.placeId else { return }
            self?.navigator?.present(.placeModification(placeId))
        }).disposed(by: disposeBag)
        
        input.memoButtonTapped$.subscribe(onNext: {
            [weak self] in
            guard let placeId = self?.placeId else { return }
            self?.navigator?.present(.memo(placeId))
        }).disposed(by: disposeBag)
        
        input.placeCellTapped$.subscribe(onNext: {[weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId))
        }).disposed(by: disposeBag)
        
        
        return Output(placeData$: placeResponse$.asObservable())
        
    }
    
    
    
    init(navigator:BottomSheetNavigator?, placeId:String){
        self.navigator = navigator
        self.placeId = placeId;
    }
    
    public struct Input {
        let placeDetailViewLoaded$:Observable<Void>
        let saveButtonTapped$:Observable<Void>
        let shareButtonTapped$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
        let likeButtonTapped$:Observable<Void>
        let placeModificationButtonTapped$:Observable<Void>
//        let verseButtonTapped$:Observable<String>
        let memoButtonTapped$:Observable<Void>
        let placeCellTapped$:Observable<String>
    }
    
    public struct Output{
        let placeData$:Observable<Place>
        
    }
    
    
}
