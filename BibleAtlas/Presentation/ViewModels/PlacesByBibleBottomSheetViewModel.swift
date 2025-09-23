//
//  PlacesByBibleBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 9/23/25.
//

import Foundation
import RxSwift
import RxRelay

protocol PlacesByBibleBottomSheetViewModelProtocol {
    
    func transform(input:PlacesByBibleBottomSheetViewModel.Input) -> PlacesByBibleBottomSheetViewModel.Output
}


final class PlacesByBibleBottomSheetViewModel:PlacesByBibleBottomSheetViewModelProtocol{
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private let places$ = BehaviorRelay<[Place]>(value: []);
    private let error$ = BehaviorRelay<NetworkError?>(value: nil)
    private let bible$ = BehaviorRelay<BibleBook>(value: .Exod)

    private let isInitialLoading$ = BehaviorRelay<Bool>(value: true);
    private let isFetchingNext$ = BehaviorRelay<Bool>(value: false);
    
    private var pagination = Pagination(pageSize: 10)
    
    private let placeUsecase:PlaceUsecaseProtocol?
    
    private var bible:BibleBook
    
    init(navigator:BottomSheetNavigator?, bible:BibleBook,placeUsecase:PlaceUsecaseProtocol?){
        self.navigator = navigator;
        self.bible = bible;
        self.placeUsecase = placeUsecase
        self.bible$.accept(bible)
        
    }
    
    func transform(input: Input) -> Output {
        input.viewLoaded$.subscribe(onNext: {
            [weak self] in
            guard let self = self else { return }
                
            Task{
                defer {
                    self.isInitialLoading$.accept(false)
                }
                
                let parameters = PlaceParameters(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeName: nil, prefix: nil, sort:nil, bible: self.bible$.value )
                let response = await self.placeUsecase?.getPlaces(parameters:parameters);
                
                switch(response){
                case.success(let response):
                    self.places$.accept(response.data)
                    self.pagination.update(total: response.total)
                case .failure(let error):
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
                    
                    let parameters = PlaceParameters(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeName: nil, prefix: nil, sort:nil, bible: self.bible$.value)
                    
                    let response = await self.placeUsecase?.getPlaces(parameters:parameters)
                    switch(response){
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
        
        input.placeCellTapped$.subscribe(onNext: { [weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId))
        }).disposed(by: disposeBag)
        

        input.refetchButtonTapped$.subscribe(onNext:{
            [weak self] in
            guard let self = self else { return }
            
            self.pagination.reset();
            self.places$.accept([])
            self.isInitialLoading$.accept(true)
            self.error$.accept(nil)
            
            Task{
                defer {
                    self.isInitialLoading$.accept(false)
                }
                let parameters = PlaceParameters(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeName: nil, prefix: nil, sort:nil, bible: self.bible$.value)
                
                
                let response = await self.placeUsecase?.getPlaces(parameters:parameters);
                
                switch(response){
                case.success(let response):
                    self.places$.accept(response.data)
                    self.pagination.update(total: response.total)
                    self.error$.accept(nil)
                case .failure(let error):
                    self.error$.accept(error)
                    print(error.description)
                case .none:
                    print("none")
                }
            }
            
        }).disposed(by:disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {[weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        
        
        

        return Output(places$: places$.asObservable(), error$: error$.asObservable(), bible$: bible$.asObservable(), isInitialLoading$: isInitialLoading$.asObservable(), isFetchingNext$: isFetchingNext$.asObservable())
        
    }

    public struct Input{
        let viewLoaded$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
        let placeCellTapped$:Observable<String>
        let bottomReached$:Observable<Void>
        let refetchButtonTapped$:Observable<Void>
    }
    
    
    public struct Output {
        let places$:Observable<[Place]>
        let error$:Observable<NetworkError?>
        let bible$:Observable<BibleBook>
        let isInitialLoading$:Observable<Bool>
        let isFetchingNext$:Observable<Bool>
        
    }
    
    
}

