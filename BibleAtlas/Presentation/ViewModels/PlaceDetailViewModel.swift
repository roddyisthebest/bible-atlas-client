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
    
    private let notificationService: RxNotificationServiceProtocol?
    
    private let place$ = BehaviorRelay<Place?>(value: nil);
    private let bibles$ = BehaviorRelay<[Bible]>(value:[]);
    
    private var placeId:String
    
    private let loadError$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let interactionError$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let isLoading$ = BehaviorRelay<Bool>(value: true);
    private let isSaving$ = BehaviorRelay<Bool>(value: false);
    private let isLiking$ = BehaviorRelay<Bool>(value: false)
    
    private let placeUsecase:PlaceUsecaseProtocol?
    
    private var appStore:AppStoreProtocol?
    
    private var isLoggedIn$ = BehaviorRelay<Bool>(value:false)
    private var profile$ = BehaviorRelay<User?>(value:nil)
    
    
    
    
    
    func transform(input: Input) -> Output {
        
        Observable.merge(input.viewLoaded$, input.refetchButtonTapped$).subscribe(onNext:{
            [weak self] in
            guard let self = self else { return }
            
            self.loadError$.accept(nil)
            self.isLoading$.accept(true)
            Task{
                defer {
                    self.isLoading$.accept(false)
                }
                
                
                
                let response = await self.placeUsecase?.getPlace(placeId: self.placeId);
                
                
                switch(response){
                case.success(let response):
                    self.place$.accept(response);
                    let bibles = self.placeUsecase?.parseBible(verseString: response.verse)
                    self.bibles$.accept(bibles ?? [])
                case .failure(let error):
                    self.loadError$.accept(error)
                case .none:
                    print("none")
                }
            }
            
            
        }).disposed(by: disposeBag)
        

        
        input.closeButtonTapped$.subscribe(onNext: {[weak self] in
            
            guard let self = self else {
                return;
            }
        
            self.navigator?.dismissFromDetail(animated: true)
            
        }).disposed(by: disposeBag)
        
        input.likeButtonTapped$.subscribe(onNext: {[weak self] in
            let isLoggedIn = self?.appStore?.state$.value.isLoggedIn ?? false

            if(!isLoggedIn){
                self?.navigator?.present(.login)
                return;
            }
            
            guard let self = self else { return }
            self.isLiking$.accept(true)
            
            Task{
                defer{
                    self.isLiking$.accept(false)
                }
                
                let result = await self.placeUsecase?.toggleLike(placeId: self.placeId);
                
                
                switch(result){
                case .success(let response):
                    guard var place = self.place$.value else {
                        return
                    }

                    place.isLiked = response.liked
                    place.likeCount = response.liked ? place.likeCount + 1 : place.likeCount - 1

                    self.place$.accept(place)
                    
                case .failure(let error):
                    self.interactionError$.accept(error)
                case .none:
                    print("none")
                }
                
            }
            
        }).disposed(by: disposeBag)
        
        input.placeModificationButtonTapped$.subscribe(onNext: {
            [weak self] in
            guard let placeId = self?.placeId else { return }
            self?.navigator?.present(.placeModification(placeId))
        }).disposed(by: disposeBag)
        
        
        
        input.saveButtonTapped$.subscribe(onNext: {[weak self] in
                
            
            let isLoggedIn = self?.appStore?.state$.value.isLoggedIn ?? false
            
            if(!isLoggedIn){
                self?.navigator?.present(.login)
                return;
            }
            
            guard let self = self else { return }

            self.isSaving$.accept(true)
            Task{
                defer{
                    self.isSaving$.accept(false)
                }
                
                let result = await self.placeUsecase?.toggleSave(placeId: self.placeId)
                
                
                switch(result){
                    case .success(let response):
                        guard var place = self.place$.value else {
                            return
                        }
                        place.isSaved = response.saved
                        self.place$.accept(place);
                    case .failure(let error):
                        self.interactionError$.accept(error)
                    case .none:
                        print("none")
                }
                
            }

        }).disposed(by: disposeBag)
        
        input.memoButtonTapped$.subscribe(onNext: {
            [weak self] in
            guard let placeId = self?.placeId else { return }
            self?.navigator?.present(.memo(placeId))
        }).disposed(by: disposeBag)
        
        input.placeCellTapped$.subscribe(onNext: {[weak self] (placeId) in
            self?.navigator?.present(.placeDetail(placeId))
        }).disposed(by: disposeBag)
        
        input.verseCellTapped$.subscribe(onNext: {[weak self] keyword in self?.navigator?.present(.bibleVerseDetail(keyword))
        }).disposed(by: disposeBag)
        
        input.reportButtonTapped$.bind{
            [weak self] reportType in
            
            guard let placeId = self?.placeId else {
                return;
            }

            self?.navigator?.present(.placeReport(placeId, reportType))
            
        }.disposed(by: disposeBag)
        
        
        return Output(place$: place$.asObservable(), bibles$: bibles$.asObservable(), loadError$: loadError$.asObservable(), interactionError$: interactionError$.asObservable(), isLoading$: isLoading$.asObservable(),isSaving$: isSaving$.asObservable(), isLiking$: isLiking$.asObservable(),isLoggedIn$: isLoggedIn$.asObservable(),profile$: profile$.asObservable())
    }
    
    func bindAppStore(){
        appStore?.state$
            .subscribe(onNext: { [weak self] appState in
                self?.isLoggedIn$.accept(appState.isLoggedIn)
                self?.profile$.accept(appState.profile)
            })
            .disposed(by: disposeBag)
        
        
    
    }
    
    
    func bindNotificationSerivce(){
        self.notificationService?.observe(.refetchRequired)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.refetch()
            }).disposed(by: disposeBag)
        
        
        self.notificationService?.observe(.fetchPlaceRequired)
            .observe(on: MainScheduler.instance)
            .compactMap { $0.object as? String }
            .subscribe(onNext: { [weak self] placeId in
                self?.placeId = placeId
                self?.refetch()

            }).disposed(by: disposeBag)
    }
    
    private func refetch() {
        isLoading$.accept(true)
        loadError$.accept(nil)

        Task {
            defer { isLoading$.accept(false) }

            let response = await placeUsecase?.getPlace(placeId: placeId)

            switch response {
            case .success(let place):
                place$.accept(place)
            case .failure(let error):
                loadError$.accept(error)
            case .none:
                print("none")
            }
        }
    }
    
    
    
    
    
    init(navigator:BottomSheetNavigator?, placeId:String, placeUsecase:PlaceUsecaseProtocol?, appStore:AppStoreProtocol?, notificationService:RxNotificationServiceProtocol?){
        self.navigator = navigator
        self.placeId = placeId;
        
        self.placeUsecase = placeUsecase
        self.appStore = appStore
        
        self.notificationService = notificationService
    
        self.bindAppStore()
        self.bindNotificationSerivce();
    }
    

    
    public struct Input {
        let viewLoaded$:Observable<Void>
        let saveButtonTapped$:Observable<Void>
        let shareButtonTapped$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
        let likeButtonTapped$:Observable<Void>
        let placeModificationButtonTapped$:Observable<Void>
        let verseButtonTapped$:Observable<String>
        let memoButtonTapped$:Observable<Void>
        let placeCellTapped$:Observable<String>
        let refetchButtonTapped$:Observable<Void>
        let verseCellTapped$:Observable<String>
        
        let reportButtonTapped$:Observable<PlaceReportType>
    }
    
    public struct Output{
        let place$:Observable<Place?>
        let bibles$:Observable<[Bible]>
        let loadError$:Observable<NetworkError?>
        let interactionError$:Observable<NetworkError?>
        let isLoading$:Observable<Bool>
        let isSaving$:Observable<Bool>
        let isLiking$:Observable<Bool>
        let isLoggedIn$:Observable<Bool>
        let profile$:Observable<User?>
    }
    
    
}
