//
//  HomeBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/28/25.
//

import Foundation
import RxSwift
import RxRelay

protocol HomeBottomSheetViewModelProtocol {
    func transform(input:HomeBottomSheetViewModel.Input) -> HomeBottomSheetViewModel.Output
    
}

final class HomeBottomSheetViewModel:HomeBottomSheetViewModelProtocol {
        
    private let disposeBag = DisposeBag();

    private weak var navigator: BottomSheetNavigator?
    private let userUsecase:UserUsecaseProtocol?
    private let authUsecase:AuthUsecaseProtocol?

    private var appStore:AppStoreProtocol?
    
    private var isLoggedIn$ = BehaviorRelay<Bool>(value:false)
    private var profile$ = BehaviorRelay<User?>(value:nil)
    
    private var likePlacesCount$ = BehaviorRelay<Int>(value:0);
    private var savePlacesCount$ = BehaviorRelay<Int>(value:0);
    private var memoPlacesCount$ = BehaviorRelay<Int>(value:0);
    
    private let loading$ = BehaviorRelay<Bool>(value:false);

    init(navigator:BottomSheetNavigator?, appStore:AppStoreProtocol?,userUsecase:UserUsecaseProtocol?, authUseCase:AuthUsecaseProtocol?){
        self.navigator = navigator
        self.appStore = appStore
        self.userUsecase = userUsecase
        self.authUsecase = authUseCase
        bindAppStore();
    }
    
    func transform(input: Input) -> Output{
        
        
        
        
        input.avatarButtonTapped$
            .withLatestFrom(profile$)
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] profile in
                guard let self = self else { return }
                
                if (profile != nil) {
                    // TODO: implement mypage
                    print("logout!")
                    let result = self.authUsecase?.logout()
                    switch result {
                        case .success:
                            self.appStore?.dispatch(.logout)
                        case .failure(let error):
                            print(error.localizedDescription)
                        case .none:
                            print("none")
                    }
                } else {
                    self.navigator?.present(.login)
                }
            })
            .disposed(by: disposeBag)
            
 
        
        input.collectionButtonTapped$.subscribe(onNext: { [weak self] collectionType in
            self?.navigator?.present(.myCollection(collectionType))
        }).disposed(by: disposeBag)
        
        input.placesByTypeButtonTapped$.subscribe(onNext:{[weak self] in
            self?.navigator?.present(.placeTypes)
        }).disposed(by: disposeBag)
        
        input.placesByCharacterButtonTapped$.subscribe(onNext: {[weak self] in
            self?.navigator?.present(.placeCharacters)
        }).disposed(by: disposeBag)
        
        return Output(profile$: profile$.asObservable(), isLoggedIn$: isLoggedIn$.asObservable(),likePlacesCount$: likePlacesCount$.asObservable(),savePlacesCount$: savePlacesCount$.asObservable(),memoPlacesCount$: memoPlacesCount$.asObservable(),loading$: loading$.asObservable() )
        
    }
    
    
    func bindAppStore(){
        appStore?.state$.subscribe(onNext: { appState in
            self.profile$.accept(appState.profile)
            self.isLoggedIn$.accept(appState.isLoggedIn)
                
            if(appState.isLoggedIn){
                Task{
                    
                    self.loading$.accept(true)
                    
                    defer {
                          self.loading$.accept(false)
                    }
                    
                    async let result1 = self.userUsecase?.getPlaces(limit: nil, page: nil, filter: .like)
                    async let result2 = self.userUsecase?.getPlaces(limit: nil, page: nil, filter: .memo)
                    async let result3 = self.userUsecase?.getPlaces(limit: nil, page: nil, filter: .save)
                    
                    let results: [(PlaceFilter, Result<ListResponse<Place>, NetworkError>?)] = [
                            (.like, await result1),
                            (.memo, await result2),
                            (.save, await result3)
                        ]
                    
                    

                    for (filter, result) in results {
                          guard let result else { continue }
                          
                          switch result {
                          case .success(let response):
                              switch(filter){
                                case .like:
                                    self.likePlacesCount$.accept(response.total)
                                case .memo:
                                    self.memoPlacesCount$.accept(response.total)
                                case .save:
                                    self.savePlacesCount$.accept(response.total)
                              }
                              if filter == .like {
                                  self.likePlacesCount$.accept(response.total)
                              }
                          case .failure(let error):
                              print("❌ \(filter) → \(error.description)")
                          }
                      }
                    
                            
                }
        
                        
                    
                
            }
            else{
                self.likePlacesCount$.accept(0)
                self.memoPlacesCount$.accept(0)
                self.savePlacesCount$.accept(0)
            }
            
        }).disposed(by: disposeBag)
        
        
    }
    
    public struct Input {
        let avatarButtonTapped$:Observable<Void>
        let collectionButtonTapped$:Observable<MyCollectionType>
        let placesByTypeButtonTapped$:Observable<Void>
        let placesByCharacterButtonTapped$:Observable<Void>
    }
    
    public struct Output{
        let profile$:Observable<User?>
        let isLoggedIn$:Observable<Bool>
        let likePlacesCount$:Observable<Int>
        let savePlacesCount$:Observable<Int>
        let memoPlacesCount$:Observable<Int>
        let loading$:Observable<Bool>

    }
    
  
    
    
}
