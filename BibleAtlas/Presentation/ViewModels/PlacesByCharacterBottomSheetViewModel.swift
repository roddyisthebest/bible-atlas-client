//
//  PlacesByCharacterBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/15/25.
//

import Foundation
import RxSwift
import RxRelay

protocol PlacesByCharacterBottomSheetViewModelProtocol {
    
    func transform(input:PlacesByCharacterBottomSheetViewModel.Input) -> PlacesByCharacterBottomSheetViewModel.Output
}


final class PlacesByCharacterBottomSheetViewModel:PlacesByCharacterBottomSheetViewModelProtocol{
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private let places$ = BehaviorRelay<[Place]>(value: []);
    private let error$ = BehaviorRelay<NetworkError?>(value: nil)
    private let character$ = BehaviorRelay<String>(value: "")

    private let isInitialLoading$ = BehaviorRelay<Bool>(value: true);
    private let isFetchingNext$ = BehaviorRelay<Bool>(value: false);
    
    private var forceMedium$ = PublishRelay<Void>()
    private var restoreDetents$ = PublishRelay<Void>()
    
    private var pagination = Pagination(pageSize: 10)
    
    private let placeUsecase:PlaceUsecaseProtocol?
    
    private var notificationService: RxNotificationServiceProtocol?
    
    private var character:String
    
    init(navigator:BottomSheetNavigator?, character:String,placeUsecase:PlaceUsecaseProtocol?,
         notificationService: RxNotificationServiceProtocol?){
        self.navigator = navigator;
        self.character = character;
        self.placeUsecase = placeUsecase
        self.notificationService = notificationService
        self.character$.accept(character)
        
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
        input.viewLoaded$
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                Task {
                    let parameters = PlaceParameters(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeName: nil, prefix: self.character$.value, sort: nil)
                    let response = await self.placeUsecase?.getPlaces(parameters: parameters)
                    switch response {
                    case .success(let r):
                        self.places$.accept(r.data)
                        self.pagination.update(total: r.total)
                        self.error$.accept(nil)
                    case .failure(let e):
                        self.error$.accept(e)
                    case .none:
                        break
                    }
                    self.isInitialLoading$.accept(false)
                }
            })
            .disposed(by: disposeBag)
        
        input.bottomReached$
            .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                
                if self.isFetchingNext$.value || !self.pagination.hasMore { return }
                self.isFetchingNext$.accept(true)
                
                Task {
                    if !self.pagination.advanceIfPossible() {
                        self.isFetchingNext$.accept(false)
                        return
                    }
                    let parameters = PlaceParameters(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeName: nil, prefix: self.character$.value, sort: nil)
                    let response = await self.placeUsecase?.getPlaces(parameters: parameters)
                    switch response {
                    case .success(let r):
                        let current = self.places$.value
                        self.places$.accept(current + r.data)
                        self.pagination.update(total: r.total)
                    case .failure(let e):
                        self.error$.accept(e)
                    case .none:
                        break
                    }
                    self.isFetchingNext$.accept(false)
                }
            })
            .disposed(by: disposeBag)
        
        input.placeCellTapped$.subscribe(onNext: { [weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId))
        }).disposed(by: disposeBag)
        

        input.refetchButtonTapped$
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                // Reset synchronously
                self.pagination.reset()
                self.places$.accept([])
                self.isInitialLoading$.accept(true)
                self.error$.accept(nil)

                Task {
                    let parameters = PlaceParameters(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeName: nil, prefix: self.character$.value, sort: nil)
                    let response = await self.placeUsecase?.getPlaces(parameters: parameters)
                    switch response {
                    case .success(let r):
                        self.places$.accept(r.data)
                        self.pagination.update(total: r.total)
                        self.error$.accept(nil)
                    case .failure(let e):
                        self.error$.accept(e)
                    case .none:
                        break
                    }
                    self.isInitialLoading$.accept(false)
                }
            })
            .disposed(by: disposeBag)
        
        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    self.navigator?.dismiss(animated: true)
                }
            })
            .disposed(by: disposeBag)
        
        
        
        

        return Output(places$: places$.asObservable(), error$: error$.asObservable(), character$: character$.asObservable(), isInitialLoading$: isInitialLoading$.asObservable(), isFetchingNext$: isFetchingNext$.asObservable(), forceMedium$: forceMedium$.asObservable(), restoreDetents$: restoreDetents$.asObservable())
        
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
        let character$:Observable<String>
        let isInitialLoading$:Observable<Bool>
        let isFetchingNext$:Observable<Bool>
        let forceMedium$:Observable<Void>
        let restoreDetents$:Observable<Void>
    }
    
    
}

