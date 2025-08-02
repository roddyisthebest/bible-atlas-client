//
//  PlacesByTypeBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import Foundation
import RxSwift
import RxRelay

protocol PlaceTypesBottomSheetViewModelProtocol {
    func transform(input:PlaceTypesBottomSheetViewModel.Input) -> PlaceTypesBottomSheetViewModel.Output
}

final class PlaceTypesBottomSheetViewModel:PlaceTypesBottomSheetViewModelProtocol {
        
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    private let placeUsecase:PlaceUsecaseProtocol?
    
    private let placeTypes$ = BehaviorRelay<[PlaceTypeWithPlaceCount]>(value:[])
    private let error$ = BehaviorRelay<NetworkError?>(value: nil)

    private let isInitialLoading$ = BehaviorRelay<Bool>(value: true);
    private let isFetchingNext$ = BehaviorRelay<Bool>(value: false);
    
    private var pagination = Pagination(pageSize: 18)
    

    
    
    init(navigator:BottomSheetNavigator?,placeUsecase:PlaceUsecaseProtocol?){
        self.navigator = navigator
        self.placeUsecase = placeUsecase
    }
    
    
    func transform(input: Input) -> Output {
        input.placeTypeCellTapped$.subscribe(onNext: {[weak self] placeTypeId in
            self?.navigator?.present(.placesByType(placeTypeId))
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
                
                let response = await self.placeUsecase?.getPlaceTypes(limit: self.pagination.pageSize, page: self.pagination.page)
                
                
                switch(response){
                case .success(let response):
                    self.placeTypes$.accept(response.data)
                case .failure(let error):
                    self.error$.accept(error)
                case .none:
                    print("none")
                }
                
            }
        }).disposed(by: disposeBag)
        
        input.bottomReached$
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .subscribe(onNext:{ [weak self] in
                guard let self = self else { return }

                if self.isFetchingNext$.value || !self.pagination.hasMore { return }
                
                self.isFetchingNext$.accept(true)
                
                Task{
                    defer {
                        self.isFetchingNext$.accept(false)
                    }
                    
                    guard self.pagination.advanceIfPossible() else { return }
                    
                    let placeTypesResponse = await self.placeUsecase?.getPlaceTypes(limit: self.pagination.pageSize, page: self.pagination.page)
                    
                    switch(placeTypesResponse){
                        case .success(let response):
                            let current = self.placeTypes$.value;
                            self.placeTypes$.accept(current + response.data)
                            self.pagination.update(total: response.total)
                        case .failure(let error):
                            self.error$.accept(error)
                        case .none:
                            print("none")
                    }
                }
                
            }).disposed(by: disposeBag)

        input.refetchButtonTapped$.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.pagination.reset();
            self.placeTypes$.accept([])
            self.isInitialLoading$.accept(true);
            self.error$.accept(nil)
            
            
            Task{
                defer{
                    self.isInitialLoading$.accept(false)
                }
                
                let response = await self.placeUsecase?.getPlaceTypes(limit: self.pagination.pageSize, page: 0)
                
                switch(response){
                case.success(let response):
                    self.placeTypes$.accept(response.data)
                    self.pagination.update(total: response.total)
                    self.error$.accept(nil)
                case .failure(let error):
                    self.error$.accept(error);
                case .none:
                    print("none")
                }
                
            }
            
        }).disposed(by: disposeBag)
        
        return Output(placeTypes$: placeTypes$.asObservable(), error$: error$.asObservable(), isInitialLoading$: isInitialLoading$.asObservable(), isFetchingNext$: isFetchingNext$.asObservable())
        
    }
    
    
    public struct Input {
        let placeTypeCellTapped$:Observable<PlaceTypeName>
        let closeButtonTapped$:Observable<Void>
        let viewLoaded$:Observable<Void>
        let bottomReached$:Observable<Void>
        let refetchButtonTapped$:Observable<Void>
    }
    
    public struct Output{
        let placeTypes$:Observable<[PlaceTypeWithPlaceCount]>
        let error$:Observable<NetworkError?>
        let isInitialLoading$:Observable<Bool>
        let isFetchingNext$:Observable<Bool>
    }
    
}
