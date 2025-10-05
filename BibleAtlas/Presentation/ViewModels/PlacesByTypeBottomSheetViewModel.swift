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
    
    
    private let places$ = BehaviorRelay<[Place]>(value:[]);
    private let error$ = PublishRelay<NetworkError?>()
    private let placeTypeName$ = BehaviorRelay<PlaceTypeName?>(value: nil)

    
    private let isInitialLoading$ = BehaviorRelay<Bool>(value: true);
    private let isFetchingNext$ = BehaviorRelay<Bool>(value: false);

    private var forceMedium$ = PublishRelay<Void>()
    private var restoreDetents$ = PublishRelay<Void>()
    
    
    private var pagination = Pagination(pageSize: 10)
    
    private let placeUsecase:PlaceUsecaseProtocol?

    private var notificationService: RxNotificationServiceProtocol?

    
    init(navigator:BottomSheetNavigator?,
         placeUsecase:PlaceUsecaseProtocol?,
         placeTypeName:PlaceTypeName, notificationService:RxNotificationServiceProtocol?){
        self.navigator = navigator;
        self.placeUsecase = placeUsecase
        self.notificationService = notificationService
        self.placeTypeName$.accept(placeTypeName);
        
        bindNotificationService()
    }
    
    
    
    private func bindNotificationService(){
        
        notificationService?.observe(.sheetCommand)
            .compactMap { $0.object as? SheetCommand }
            .subscribe(onNext: { [weak self] sheetCommand in
                
                switch(sheetCommand){
                case .forceMedium:
                    self?.forceMedium$.accept(())
                case .restoreDetents:
                    self?.restoreDetents$.accept(())
                }

            }).disposed(by: disposeBag)
        

    }
    
    
    
    func transform(input: Input) -> Output {
        
        
        input.placeCellTapped$.subscribe(onNext: { [weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId))
        }).disposed(by: disposeBag)
        
 
        
        
        input.closeButtonTapped$.subscribe(onNext: {[weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        
        Observable.merge(input.viewLoaded$, input.refetchButtonTapped$).bind{
            [weak self] in
            guard let self = self else { return }
            self.getInitialPlaces()
        }.disposed(by: disposeBag)
        
        
        input.bottomReached$.debounce(.microseconds(100), scheduler: MainScheduler.instance)
            .bind{
                [weak self] in
                guard let self = self else { return }
                self.getMorePlaces()
            }.disposed(by: disposeBag)
        

        
        return Output(places$: places$.asObservable(), error$: error$.asObservable(), typeName$: placeTypeName$.asObservable(), isInitialLoading$: isInitialLoading$.asObservable(), isFetchingNext$: isFetchingNext$.asObservable(), forceMedium$: forceMedium$.asObservable(),
                      restoreDetents$: restoreDetents$.asObservable()
        )
    }
    
    private func getInitialPlaces(){
        
        self.isInitialLoading$.accept(true)
        self.error$.accept(nil)
        self.pagination.reset()

        Task{
            defer {
                self.isInitialLoading$.accept(false)
            }
            
            
            let result = await self.placeUsecase?.getPlaces(parameters: PlaceParameters(limit: self.pagination.pageSize, page:self.pagination.page, placeTypeName: self.placeTypeName$.value));
            
            switch(result){
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
    }
    
    private func getMorePlaces(){
        
        if self.isFetchingNext$.value || !self.pagination.hasMore { return }
        self.isFetchingNext$.accept(true)
        
        Task{
            
            defer{
                self.isFetchingNext$.accept(false)
            }
            
            guard self.pagination.advanceIfPossible() else { return }

            let result = await self.placeUsecase?.getPlaces(parameters: PlaceParameters(limit: self.pagination.pageSize, page:self.pagination.page, placeTypeName: self.placeTypeName$.value));
            
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
        
    }
    
    public struct Input{
        let viewLoaded$:Observable<Void>
        let placeCellTapped$:Observable<String>
        let closeButtonTapped$:Observable<Void>
        let bottomReached$:Observable<Void>
        let refetchButtonTapped$:Observable<Void>
    }
    
    
    public struct Output {
        let places$:Observable<[Place]>
        let error$:Observable<NetworkError?>
        let typeName$:Observable<PlaceTypeName?>
        let isInitialLoading$:Observable<Bool>
        let isFetchingNext$:Observable<Bool>
        let forceMedium$:Observable<Void>
        let restoreDetents$:Observable<Void>
    }
    
    
}
