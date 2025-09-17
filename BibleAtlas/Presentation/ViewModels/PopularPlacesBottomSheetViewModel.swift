//
//  PopularPlacesBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/11/25.
//

import Foundation
import RxSwift
import RxRelay

protocol PopularPlacesBottomSheetViewModelProtocol{
    func transform(input:PopularPlacesBottomSheetViewModel.Input) -> PopularPlacesBottomSheetViewModel.Output
}


final class PopularPlacesBottomSheetViewModel:PopularPlacesBottomSheetViewModelProtocol{
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?

    private let schedular:SchedulerType
    
    private let places$ = BehaviorRelay<[Place]>(value: []);
    
    private let error$ = BehaviorRelay<NetworkError?>(value: nil)
    
    
    private let isInitialLoading$ = BehaviorRelay<Bool>(value: false);
    
    private let isFetchingNext$ = BehaviorRelay<Bool>(value: false);
    
    private let placeUsecase:PlaceUsecaseProtocol?
    
    private var pagination = Pagination(pageSize: 15)
    
    
    init(navigator:BottomSheetNavigator?, placeUsecase:PlaceUsecaseProtocol?, schedular:SchedulerType = MainScheduler.instance){
        self.navigator = navigator
        self.placeUsecase = placeUsecase;
        self.schedular = schedular
    }
        
    
    
    func transform(input:Input) -> Output{
    
        Observable.merge(input.viewLoaded$, input.refetchButtonTapped$)
            .subscribe(onNext: {[weak self] in
        
                guard let self = self else { return }

                self.error$.accept(nil)
                self.pagination.reset()
                self.isInitialLoading$.accept(true)

                Task{
                    defer{
                        self.isInitialLoading$.accept(false)
                    }
                    
                    let parameters = PlaceParameters(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeName: nil, name: nil, prefix: nil, sort: .like)
                    
                    let result = await  self.placeUsecase?.getPlaces(parameters: parameters)
                    
                    
                    switch(result){
                        case .success(let response):
                            self.places$.accept(response.data)
                            self.pagination.update(total: response.total)
                        case .failure(let error):
                            self.error$.accept(error)
                        default:
                            print("none")
                    
                    }
                    
                }
                
                
            })
            .disposed(by: disposeBag)
        
        input.bottomReached$.debounce(.microseconds(100), scheduler: schedular).subscribe(onNext:{ [weak self] in
            guard let self = self else { return }
            
            if self.isFetchingNext$.value || !self.pagination.hasMore { return }
            
            self.isFetchingNext$.accept(true)
            
            Task{
                
                defer{
                    self.isFetchingNext$.accept(false)
                }
                
                let parameters = PlaceParameters(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeName: nil, name: nil, prefix: nil, sort: .like)
                
                let result = await  self.placeUsecase?.getPlaces(parameters: parameters)
                
                switch(result){
                    case .success(let response):
                        let current = self.places$.value;
                        self.places$.accept(current + response.data)
                        self.pagination.update(total: response.total)
                    case .failure(let error):
                        self.error$.accept(error)
                    case .none:
                        print("none")
                    }
                
            }
            
        }).disposed(by: disposeBag)
        
        
        input.closeButtonTapped$.subscribe(onNext: {
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        
        input.cellSelected$.subscribe(onNext:{ [weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId))
        }).disposed(by:disposeBag)
        
        return Output(places$: places$.asObservable(), error$: error$.asObservable(), isInitialLoading$: isInitialLoading$.asObservable(), isFetchingNext$: isFetchingNext$.asObservable())
    }
    
    
    
    
    
    public struct Input{
        let viewLoaded$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
        let cellSelected$:Observable<String>
        let bottomReached$:Observable<Void>
        let refetchButtonTapped$:Observable<Void>
    }
    
    
    public struct Output{
        let places$:Observable<[Place]>
        let error$:Observable<NetworkError?>
        let isInitialLoading$:Observable<Bool>
        let isFetchingNext$:Observable<Bool>
    }
     
}
