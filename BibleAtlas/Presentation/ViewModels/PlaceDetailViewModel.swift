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
    var currentPlace: Place? { get }
}

final class PlaceDetailViewModel:PlaceDetailViewModelProtocol{
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private let notificationService: RxNotificationServiceProtocol?
    
    private let place$ = BehaviorRelay<Place?>(value: nil);
    
    var currentPlace: Place? {
         return place$.value
     }
    
    private let bibles$ = BehaviorRelay<([Bible],Int)>(value:([],0));
    
    private var placeId:String
    
    private let loadError$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let interactionError$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let isLoading$ = BehaviorRelay<Bool>(value: true);
    private let isSaving$ = BehaviorRelay<Bool>(value: false);
    private let isLiking$ = BehaviorRelay<Bool>(value: false)
    
    private let placeUsecase:PlaceUsecaseProtocol?
    
    private var appStore:AppStoreProtocol?
    private var collectionStore:CollectionStoreProtocol?
    
    private var isLoggedIn$ = BehaviorRelay<Bool>(value:false)
    private var profile$ = BehaviorRelay<User?>(value:nil)
    
    private var hasPrevPlaceId$ = BehaviorRelay<Bool>(value:false)
    
    private let maxPlaceCount = 3;
    
    
    
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
                    guard let bibles = self.placeUsecase?.parseBible(verseString: response.verse) else{
                        self.bibles$.accept(([], 0))
                        return
                    }
                    let restBiblesCount = max(bibles.count - self.maxPlaceCount ,0)
                    self.bibles$.accept((Array(bibles.prefix(self.maxPlaceCount)), restBiblesCount))
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
                @MainActor in

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
                    self.collectionStore?.dispatch(response.liked ? .like(self.placeId): .unlike(self.placeId))
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
            let isLoggedIn = self?.appStore?.state$.value.isLoggedIn ?? false
            
            if(isLoggedIn){
                self?.navigator?.present(.placeModification(placeId))
            }
            else{
                self?.navigator?.present(.login)
            }
            

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
                        self.collectionStore?.dispatch(response.saved ? .bookmark(self.placeId): .unbookmark(self.placeId))
                    
                        self.place$.accept(place);
                    case .failure(let error):
                        self.interactionError$.accept(error)
                    case .none:
                        print("none")
                }
                
            }

        }).disposed(by: disposeBag)
        
        input.backButtonTapped$.observe(on: MainScheduler.instance).bind{
            [weak self] in
            self?.navigator?.present(.placeDetailPrevious)
        }.disposed(by: disposeBag)
        
        input.memoButtonTapped$.subscribe(onNext: {
            [weak self] in
            guard let placeId = self?.placeId else { return }
            
            let isLoggedIn = self?.appStore?.state$.value.isLoggedIn ?? false
            
            if(isLoggedIn){
                self?.navigator?.present(.memo(placeId))
            }else{
                self?.navigator?.present(.login)
            }
            

        }).disposed(by: disposeBag)
        
        input.placeCellTapped$.subscribe(onNext: {[weak self] (placeId) in
            self?.navigator?.present(.placeDetail(placeId))
        }).disposed(by: disposeBag)
        
        input.verseCellTapped$
            // 탭이 발생했을 때의 최신 place만 끌어온다 (place$ 변경으로 재발화 방지)
            .withLatestFrom(place$) { tap, place in (tap, place) }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] tap, place in
                let (book, keyword) = tap
                let localizedName = L10n.isEnglish ? place?.name : place?.koreanName
                self?.navigator?.present(.bibleVerseDetail(book, keyword, localizedName))
            })
            .disposed(by: disposeBag)
 
        input.moreVerseButtonTapped$.subscribe(onNext:{ [weak self] bibleBook in
            guard let placeId = self?.placeId else{
                return
            }
            
            self?.navigator?.present(.bibleBookVerseList(placeId, bibleBook))
        }).disposed(by: disposeBag)
        
        input.reportButtonTapped$.bind{
            [weak self] reportType in
            
            guard let placeId = self?.placeId else {
                return;
            }

            self?.navigator?.present(.placeReport(placeId, reportType))
            
        }.disposed(by: disposeBag)
        
        
        
        
        return Output(place$: place$.asObservable(), bibles$: bibles$.asObservable(), loadError$: loadError$.asObservable(), interactionError$: interactionError$.asObservable(), isLoading$: isLoading$.asObservable(),isSaving$: isSaving$.asObservable(), isLiking$: isLiking$.asObservable(),isLoggedIn$: isLoggedIn$.asObservable(),profile$: profile$.asObservable(), hasPrevPlaceId$: hasPrevPlaceId$.asObservable())
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
            .observe(on: schedular)
            .subscribe(onNext: { [weak self] _ in
                self?.refetch()
            }).disposed(by: disposeBag)
        
        
        self.notificationService?.observe(.fetchPlaceRequired)
            .observe(on: schedular)
            .compactMap { $0.object as? [String:String?] }
            .subscribe(onNext: { [weak self] object in
                guard let self = self else { return }
                
                guard
                      let placeIdOpt = object["placeId"],
                      let placeId = placeIdOpt
                  else {
                      print("❌ placeId is nil")
                      return
                  }
           
                let prevPlaceId = object["prevPlaceId"] ?? nil
                self.placeId = placeId
                print(placeId)
                self.hasPrevPlaceId$.accept(prevPlaceId != nil)
                self.refetch();

            }).disposed(by: disposeBag)
    }
    
    private func refetch() {
        isLoading$.accept(true)
        loadError$.accept(nil)

        Task {
            @MainActor in
            defer { isLoading$.accept(false) }

            let response = await placeUsecase?.getPlace(placeId: placeId)

            switch response {
            case .success(let place):
                place$.accept(place)
                guard let bibles = self.placeUsecase?.parseBible(verseString: place.verse) else{
                    self.bibles$.accept(([], 0))
                    return
                }
                let restBiblesCount = max(bibles.count - self.maxPlaceCount ,0)
                self.bibles$.accept((Array(bibles.prefix(self.maxPlaceCount)), restBiblesCount))
            case .failure(let error):
                loadError$.accept(error)
            case .none:
                print("none")
            }
        }
    }
    
    
    private let schedular:SchedulerType
    
    
    init(navigator:BottomSheetNavigator?, placeId:String, placeUsecase:PlaceUsecaseProtocol?, appStore:AppStoreProtocol?, collectionStore:CollectionStoreProtocol?, notificationService:RxNotificationServiceProtocol?,
         schedular:SchedulerType = MainScheduler.instance){
        self.navigator = navigator
        self.placeId = placeId;
        self.placeUsecase = placeUsecase
        
        self.appStore = appStore
        self.collectionStore = collectionStore
        
        self.notificationService = notificationService
        self.schedular = schedular
        
        self.bindAppStore()
        self.bindNotificationSerivce();
    }
    

    
    public struct Input {
        let viewLoaded$:Observable<Void>
        let saveButtonTapped$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
        let backButtonTapped$:Observable<Void>
        let likeButtonTapped$:Observable<Void>
        let placeModificationButtonTapped$:Observable<Void>
        let memoButtonTapped$:Observable<Void>
        let placeCellTapped$:Observable<String>
        let refetchButtonTapped$:Observable<Void>
        let verseCellTapped$:Observable<(BibleBook, String)>
        let moreVerseButtonTapped$:Observable<BibleBook?>
        let reportButtonTapped$:Observable<PlaceReportType>
    }
    
    public struct Output{
        let place$:Observable<Place?>
        let bibles$:Observable<([Bible], Int)>
        let loadError$:Observable<NetworkError?>
        let interactionError$:Observable<NetworkError?>
        let isLoading$:Observable<Bool>
        let isSaving$:Observable<Bool>
        let isLiking$:Observable<Bool>
        let isLoggedIn$:Observable<Bool>
        let profile$:Observable<User?>
        let hasPrevPlaceId$:Observable<Bool>
    }
    
    
}
