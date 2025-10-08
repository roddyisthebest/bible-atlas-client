//
//  HomeContentViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/21/25.
//

import Foundation
import RxSwift
import RxRelay

protocol HomeContentViewModelProtocol {
    func transform(input:HomeContentViewModel.Input) -> HomeContentViewModel.Output
}


final class HomeContentViewModel: HomeContentViewModelProtocol{
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    
    private let userUsecase:UserUsecaseProtocol?
    private let authUsecase:AuthUsecaseProtocol?
    
    private let recentSearchService:RecentSearchServiceProtocol?
    
    private var appStore:AppStoreProtocol?
    private var collectionStore:CollectionStoreProtocol?

    private var isLoggedIn$ = BehaviorRelay<Bool>(value:false)
    private var profile$ = BehaviorRelay<User?>(value:nil)

    
    private var likePlacesCount$ = BehaviorRelay<Int>(value:0);
    private var savePlacesCount$ = BehaviorRelay<Int>(value:0);
    private var memoPlacesCount$ = BehaviorRelay<Int>(value:0);
    
    private let loading$ = BehaviorRelay<Bool>(value:false);
    
    private var forceMedium$ = PublishRelay<Void>()
    private var restoreDetents$ = PublishRelay<Void>()
    
    private let recentSearches$ = BehaviorRelay<[RecentSearchItem]>(value: []);
    private let errorToFetchRecentSearches$ = BehaviorRelay<RecentSearchError?>(value: nil)
    
    private var notificationService: RxNotificationServiceProtocol?
    
    private let scheduler:SchedulerType;
    
    init(navigator:BottomSheetNavigator?, appStore:AppStoreProtocol?, collectionStore:CollectionStoreProtocol? ,userUsecase:UserUsecaseProtocol?, authUseCase:AuthUsecaseProtocol?,
         recentSearchService:RecentSearchServiceProtocol?, schedular:SchedulerType = MainScheduler.asyncInstance,
         notificationService: RxNotificationServiceProtocol?
    
    ){
        self.navigator = navigator
        self.appStore = appStore
        self.collectionStore = collectionStore
        self.userUsecase = userUsecase
        self.authUsecase = authUseCase
        self.recentSearchService = recentSearchService
        self.scheduler = schedular;
        self.notificationService = notificationService
        
        bindStores();
        bindCollectionStore();
        bindRecentSearchService();
        getRecentSearchItems();
        bindNotificationService();
    }
    
    func bindStores(){
        Observable.combineLatest(appStore!.state$, collectionStore!.state$)
            .distinctUntilChanged { prev, next in
                return prev.0.isLoggedIn == next.0.isLoggedIn
            }
            .observe(on: self.scheduler)
            .bind{
                [weak self] appState, collectionState in
                
                guard let self = self else {return}
                self.profile$.accept(appState.profile)
                self.isLoggedIn$.accept(appState.isLoggedIn)
                    
                if(appState.isLoggedIn){
                    Task{
                        
                        self.loading$.accept(true)
                        defer {
                              self.loading$.accept(false)
                        }
                        
                        let result = await self.userUsecase?.getMyCollectionPlaceIds();
                        
                        switch(result){
                            case .success(let myCollectionPlaceIds):
                                self.collectionStore?.dispatch(.initialize(myCollectionPlaceIds))
                            case .failure(let error):
                                print("error")
                            default:
                                print("none")
                        }
                                                
                    }

                }
                else{
                    self.collectionStore?.dispatch(.reset)
                }
                
                
                
            }.disposed(by: disposeBag)
        
    }
    
    func bindCollectionStore(){
        collectionStore!.state$.bind{
            [weak self] state in
            self?.memoPlacesCount$.accept(state.memoedPlaceIds.count)
            self?.likePlacesCount$.accept(state.likedPlaceIds.count)
            self?.savePlacesCount$.accept(state.bookmarkedPlaceIds.count)
        }.disposed(by: disposeBag)
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
    
   
    
    
    private func bindRecentSearchService(){
        self.recentSearchService?.didChanged$.subscribe(onNext:{[weak self] in
            self?.getRecentSearchItems()
        }).disposed(by: disposeBag)

    }
    
    
    
    private func getRecentSearchItems(){
        let result = self.recentSearchService?.fetch(limit: 2, page:nil)
        switch(result){
        case .success(let response):
            self.recentSearches$.accept(response.items)
            print(response)
        case .failure(let error):
            self.errorToFetchRecentSearches$.accept(error)
        default:
            print("wo")
        }
    }
    
    
    public struct Input {
        let collectionButtonTapped$:Observable<PlaceFilter>
        let placesByTypeButtonTapped$:Observable<Void>
        let placesByCharacterButtonTapped$:Observable<Void>
        let placesByBibleButtonTapped$:Observable<Void>
        let recentSearchCellTapped$:Observable<String>
        let moreRecentSearchesButtonTapped$:Observable<Void>
    }
    
    public struct Output{
        let profile$:Observable<User?>
        let isLoggedIn$:Observable<Bool>
        let likePlacesCount$:Observable<Int>
        let savePlacesCount$:Observable<Int>
        let memoPlacesCount$:Observable<Int>
        let recentSearches$:Observable<[RecentSearchItem]>
        let errorToFetchRecentSearches$:Observable<RecentSearchError?>
        let loading$:Observable<Bool>
        let forceMedium$:Observable<Void>
        let restoreDetents$:Observable<Void>
        
    }
    
    
    func transform(input:Input) -> Output {

        input.collectionButtonTapped$
            .withLatestFrom(isLoggedIn$, resultSelector: { collectionType, isLoggedIn in
                return (collectionType, isLoggedIn)
            })
            .subscribe(onNext: { [weak self] collectionType, isLoggedIn in
                if(isLoggedIn){
                    self?.navigator?.present(.myCollection(collectionType))
                }
                else{
                    self?.navigator?.present(.login)
                }
                
        }).disposed(by: disposeBag)
        
        input.placesByTypeButtonTapped$.subscribe(onNext:{[weak self] in
            self?.navigator?.present(.placeTypes)
        }).disposed(by: disposeBag)
        
        input.placesByCharacterButtonTapped$.subscribe(onNext: {[weak self] in
            self?.navigator?.present(.placeCharacters)
        }).disposed(by: disposeBag)
        
        input.placesByBibleButtonTapped$.subscribe(onNext: {[weak self] in
            self?.navigator?.present(.bibles)
        }).disposed(by: disposeBag)
        
        input.recentSearchCellTapped$.bind{[weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId))
        }.disposed(by: disposeBag)
        
        input.moreRecentSearchesButtonTapped$.bind{[weak self] in
            self?.navigator?.present(.recentSearches)
        }.disposed(by: disposeBag)
        
        return Output(profile$: profile$.asObservable(), isLoggedIn$: isLoggedIn$.asObservable(), likePlacesCount$: likePlacesCount$.asObservable(), savePlacesCount$: savePlacesCount$.asObservable(), memoPlacesCount$: memoPlacesCount$.asObservable(), recentSearches$: recentSearches$.asObservable(), errorToFetchRecentSearches$: errorToFetchRecentSearches$.asObservable(), loading$: loading$.asObservable(), forceMedium$: forceMedium$.asObservable(), restoreDetents$: restoreDetents$.asObservable())
    }
    
}
