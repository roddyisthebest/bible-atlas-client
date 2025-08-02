//
//  MemoBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/10/25.
//


import Foundation
import RxSwift
import RxRelay

protocol MemoBottomSheetViewModelProtocol {
    func transform(input:MemoBottomSheetViewModel.Input) -> MemoBottomSheetViewModel.Output
}


final class MemoBottomSheetViewModel:MemoBottomSheetViewModelProtocol{

    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private var placeUsecase:PlaceUsecaseProtocol?
    
    private var collectionStore:CollectionStoreProtocol?
    
    private weak var notificationService: RxNotificationServiceProtocol?
    
    private let placeId:String
    
    private let memo$ = BehaviorRelay<String>(value: "");
    
        
    private let loadError$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let interactionError$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let isLoading$ = BehaviorRelay<Bool>(value: true);
    
    private let isCreatingOrUpdating$ = BehaviorRelay<Bool>(value: false);
    
    private let isDeleting$ = BehaviorRelay<Bool>(value: false)

    init(navigator:BottomSheetNavigator?, placeId:String, placeUsecase:PlaceUsecaseProtocol?, collectionStore:CollectionStoreProtocol? ,notificationService:RxNotificationServiceProtocol?){
        self.navigator = navigator
        self.placeId = placeId;
        self.placeUsecase = placeUsecase;
        self.collectionStore = collectionStore
        self.notificationService = notificationService
    }
    
    
    func transform(input: Input) -> Output {
        
        Observable.merge(input.viewLoaded$, input.refetchButtonTapped$).subscribe(onNext: {
            [weak self] in
            self?.fetchPlace();
                
        }).disposed(by: disposeBag)
        
        input.confirmButtonTapped$.subscribe(onNext: { [weak self] text in
            self?.createOrUpdatePlaceMemo(text: text)
        }).disposed(by: disposeBag)
               
        input.deleteButtonTapped$.subscribe(onNext:{
            [weak self] in
            self?.deletePlaceMemo()
        }).disposed(by: disposeBag)
        
        input.cancelButtonTapped$.subscribe(onNext: {
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        return Output(memo$: memo$.asObservable(), loadError$: loadError$.asObservable(), interactionError$: interactionError$.asObservable(), isLoading$: isLoading$.asObservable(), isCreatingOrUpdating$: isCreatingOrUpdating$.asObservable(), isDeleting$: isDeleting$.asObservable())

    }
    
    
    private func fetchPlace(){
            
        self.isLoading$.accept(true)
        self.loadError$.accept(nil);

        Task{
            defer{
                self.isLoading$.accept(false)
            }
            
            let result = await self.placeUsecase?.getPlace(placeId: self.placeId)
            
            
            switch(result){
            case .success(let place):
            
                let memo = place.memo?.text ?? ""
                
                self.memo$.accept(memo)
                
            case .failure(let error):
                self.loadError$.accept(error)
                
            case .none:
                print("none")
            }
        }
    }
    
    
    private func createOrUpdatePlaceMemo(text:String?){
        guard let text = text else {
            self.interactionError$.accept(.clientError("텍스트가 없습니다."))
            return;
        }
        
        self.isCreatingOrUpdating$.accept(true)
        
        Task{
            
            defer{
                self.isCreatingOrUpdating$.accept(false)
            }
            
            let result = await self.placeUsecase?.createOrUpdatePlaceMemo(placeId: self.placeId, text: text)
            
            switch(result){
            case.success(let place):
                self.notificationService?.post(.refetchRequired, object: nil)
                self.collectionStore?.dispatch(.addMemo(placeId))
                self.navigator?.dismiss(animated: true);
            case.failure(let error):
                self.interactionError$.accept(error)
            case.none:
                print("none")
            }
            
            
        }
        
        
        
    }
    
    
    public func deletePlaceMemo(){
        self.isDeleting$.accept(true)
        
        
        Task{
            defer{
                self.isDeleting$.accept(false)
            }
            
            
            let result = await self.placeUsecase?.deletePlaceMemo(placeId: self.placeId)
            
            switch(result){
            case.success(let response):
                self.notificationService?.post(.refetchRequired, object: nil)
                self.collectionStore?.dispatch(.removeMemo(placeId))
                self.navigator?.dismiss(animated: true)
            case.failure(let error):
                self.interactionError$.accept(error)
            case.none:
                print("none")
            }
        }
    }
    
    public struct Input {
        let viewLoaded$:Observable<Void>
        let refetchButtonTapped$:Observable<Void>
        let cancelButtonTapped$:Observable<Void>
        let confirmButtonTapped$:Observable<String>
        let deleteButtonTapped$:Observable<Void>
    }
    
    public struct Output {
        let memo$:Observable<String>
        let loadError$:Observable<NetworkError?>
        let interactionError$:Observable<NetworkError?>
        let isLoading$:Observable<Bool>
        let isCreatingOrUpdating$:Observable<Bool>
        let isDeleting$:Observable<Bool>
        
    }
    

}
