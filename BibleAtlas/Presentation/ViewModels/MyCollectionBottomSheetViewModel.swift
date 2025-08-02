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
    
    private let places$ = BehaviorRelay<[Place]>(value: []);
    private let error$ = BehaviorRelay<NetworkError?>(value: nil)
    private let filter$: BehaviorRelay<PlaceFilter>

    private let isInitialLoading$ = BehaviorRelay<Bool>(value: true);
    private let isFetchingNext$ = BehaviorRelay<Bool>(value: false);
    
    
    private let userUsecase:UserUsecaseProtocol?
    
    private var pagination = Pagination(pageSize: 10)

    private var filter:PlaceFilter

    init(navigator:BottomSheetNavigator?, filter:PlaceFilter, userUsecase:UserUsecaseProtocol?){
        self.navigator = navigator
        self.filter = filter;
        self.userUsecase = userUsecase;
        
        self.filter$ = BehaviorRelay(value: filter)
    }
        
    func transform(input:Input) -> Output{
        
        
        
        input.myCollectionViewLoaded$.subscribe(onNext: {
            [weak self] in
            guard let self = self else { return }
            
            Task{
                
                defer {
                    self.isInitialLoading$.accept(false)
                }
                
                let response = await self.userUsecase?.getPlaces(limit: self.pagination.pageSize, page: self.pagination.page, filter: self.filter)
                
                switch(response){
                case.success(let response):
                    self.places$.accept(response.data)
                    self.pagination.update(total: response.total)
                case .failure(let error):
                    // TODO: handle some error
                    self.error$.accept(error)
                    print(error.description)
                case .none:
                    print("none")
                }
            }
        }).disposed(by: disposeBag)
        
        input.bottomReached$
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                if self.isFetchingNext$.value || !self.pagination.hasMore { return }
                self.isFetchingNext$.accept(true)
                
                Task{
                    defer {
                        self.isFetchingNext$.accept(false)
                    }
                    
                    guard self.pagination.advanceIfPossible() else { return }
                    
                    let placesResponse = await self.userUsecase?.getPlaces(limit: self.pagination.pageSize, page: self.pagination.page, filter: self.filter)
                    
                    switch(placesResponse){
                    case.success(let response):
                        let current = self.places$.value
                        self.places$.accept(current + response.data)
                        self.pagination.update(total: response.total)
                        
                    case .failure(let error):
                        self.error$.accept(error)
                    case .none:
                        print("none")
                    }
                }
            })
            .disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        input.placeTabelCellSelected$.subscribe(onNext:{ [weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId))
            
        }).disposed(by:disposeBag)
        
        input.refetchButtonTapped$.subscribe( onNext: { [weak self] in
            
            guard let self = self else { return }
            
            self.pagination.reset();
            self.places$.accept([])
            self.isInitialLoading$.accept(true)
            self.error$.accept(nil)
            
            Task{
                
                defer {
                    self.isInitialLoading$.accept(false)
                }
                
                let response = await self.userUsecase?.getPlaces(limit: self.pagination.pageSize, page: 0, filter: self.filter)
                
                switch(response){
                case.success(let response):
                    self.places$.accept(response.data)
                    self.pagination.update(total: response.total)
                    self.error$.accept(nil)
                case .failure(let error):
                    // TODO: handle some error
                    self.error$.accept(error)
                    print(error.description)
                case .none:
                    print("none")
                }
            }
        }).disposed(by: disposeBag)
        
        return Output(places$: places$.asObservable(),
                      error$: error$.asObservable(),
                      filter$: filter$.asObservable(),
                      isInitialLoading$: isInitialLoading$.asObservable(),
                      isFetchingNext$:isFetchingNext$.asObservable())
        
    }
    
    
    public struct Input {
        let myCollectionViewLoaded$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
        let placeTabelCellSelected$:Observable<String>
        let bottomReached$:Observable<Void>
        let refetchButtonTapped$:Observable<Void>
    }
    
    public struct Output{
        let places$:Observable<[Place]>
        let error$:Observable<NetworkError?>
        let filter$:Observable<PlaceFilter>;
        let isInitialLoading$:Observable<Bool>
        let isFetchingNext$:Observable<Bool>
    }
}
