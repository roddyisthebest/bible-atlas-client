//
//  PlacesByCharacterBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import Foundation
import RxSwift
import RxRelay

protocol PlaceCharactersBottomSheetViewModelProtocol {
    func transform(input:PlaceCharactersBottomSheetViewModel.Input) -> PlaceCharactersBottomSheetViewModel.Output

}

final class PlaceCharactersBottomSheetViewModel:PlaceCharactersBottomSheetViewModelProtocol{
    
    
    private let disposeBag = DisposeBag();
    private weak var navigator:BottomSheetNavigator?
        
    private let placeUsecase:PlaceUsecaseProtocol?
    
    private let placeCharacters$ = BehaviorRelay<[PlacePrefix]>(value:[])
    private let error$ = BehaviorRelay<NetworkError?>(value: nil)

    private let isInitialLoading$ = BehaviorRelay<Bool>(value: true);
    
    
    init(navigator:BottomSheetNavigator?, placeUsecase:PlaceUsecaseProtocol?){
        self.navigator = navigator
        self.placeUsecase = placeUsecase
    }
    
    func transform(input: Input) -> Output {
        
        input.placeCharacterCellTapped$.subscribe(onNext: {[weak self] character in
            self?.navigator?.present(.placesByCharacter(character))
        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {[weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        input.viewLoaded$.subscribe(onNext: {[weak self] in
            guard let self = self else { return }

            Task{
                defer {
                    self.isInitialLoading$.accept(false)
                }
                
                let response = await self.placeUsecase?.getPrefixs();
                
                switch(response){
                    case .success(let response):
                        self.placeCharacters$.accept(response.data)
                    case .failure(let error):
                        self.error$.accept(error)
                    case .none:
                        print("none")
                }
            }
            
           
            
        }).disposed(by: disposeBag)
        
        
        input.refetchButtonTapped$.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            
            self.placeCharacters$.accept([]);
            self.isInitialLoading$.accept(true);
            self.error$.accept(nil);
            
            Task{
                defer{
                    self.isInitialLoading$.accept(false)
                }
                
                let response = await self.placeUsecase?.getPrefixs();
                
                switch(response){
                    case .success(let response):
                        self.placeCharacters$.accept(response.data)
                        self.error$.accept(nil)
                    case .failure(let error):
                        self.error$.accept(error)
                    case .none:
                        print("none")
                }
                
                
            }
            
            
            
        }).disposed(by: disposeBag)
        
        return Output(placeCharacter$: placeCharacters$.asObservable(), error$: error$.asObservable(), isInitialLoading$: isInitialLoading$.asObservable())

    }
    
    public struct Input {
        let placeCharacterCellTapped$:Observable<String>
        let closeButtonTapped$:Observable<Void>
        let viewLoaded$:Observable<Void>
        let refetchButtonTapped$:Observable<Void>
    }
    
    public struct Output{
        let placeCharacter$:Observable<[PlacePrefix]>
        let error$:Observable<NetworkError?>
        let isInitialLoading$:Observable<Bool>
    }
    
}
