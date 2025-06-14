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
    func transform(input:PlaceModificationBottomSheetViewModel.Input) -> PlaceModificationBottomSheetViewModel.Output
}

final class PlaceModificationBottomSheetViewModel:PlaceModificationBottomSheetViewModelProtocol {
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    private var placeUsecase:PlaceUsecaseProtocol?
    
    private var placeId:String? = nil
    
    private let interactionError$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let isSuccess$ = BehaviorRelay<Bool?>(value: nil)

    private let isCreating$ = BehaviorRelay<Bool>(value: false)
    
    init(navigator:BottomSheetNavigator?, placeId:String, placeUsecase:PlaceUsecaseProtocol?){
        self.navigator = navigator
        self.placeId = placeId;
        self.placeUsecase = placeUsecase
    }
    
    
    func transform(input:Input) -> Output {
        input.confirmButtonTapped$.subscribe(onNext: { [weak self] comment in
            self?.createPlaceProposal(comment: comment)
                
        }).disposed(by: disposeBag)

        
        input.cancelButtonTapped$.subscribe(onNext: {
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        return Output(interactionError$: interactionError$.asObservable(), isCreating$: isCreating$.asObservable(), isSuccess$: isSuccess$.asObservable())
    }
    
    
    private func createPlaceProposal(comment:String){
        
        guard let placeId = placeId else {
            return
        }
        self.isCreating$.accept(true)
        
        Task{
            defer{
                self.isCreating$.accept(false)
            }
            
            let result = await self.placeUsecase?.createPlaceProposal(placeId: placeId, comment: comment)
            
            switch(result){
                case .success(let response):
                    self.isSuccess$.accept(true)
                case .failure(let error):
                    self.interactionError$.accept(error)
                case .none:
                    print("none")
            }
        }
        
    }
    
    public struct Input {
        let cancelButtonTapped$:Observable<Void>
        let confirmButtonTapped$:Observable<String>
    }
    
    public struct Output {
        let interactionError$:Observable<NetworkError?>
        let isCreating$:Observable<Bool>
        let isSuccess$:Observable<Bool?>
    }
        
    
}
