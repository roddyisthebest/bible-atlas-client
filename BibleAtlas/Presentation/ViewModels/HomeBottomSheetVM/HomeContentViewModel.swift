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
        let collectionButtonTapped$:Observable<PlaceFilter>
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
    
    
    func transform(input:Input) -> Output {

        input.collectionButtonTapped$
            .withLatestFrom(isLoggedIn$, resultSelector: { collectionType, isLoggedIn in
                return (collectionType, isLoggedIn)
            })
            .observe(on: MainScheduler.asyncInstance)
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
        
        return Output(profile$: profile$.asObservable(), isLoggedIn$: isLoggedIn$.asObservable(),likePlacesCount$: likePlacesCount$.asObservable(),savePlacesCount$: savePlacesCount$.asObservable(),memoPlacesCount$: memoPlacesCount$.asObservable(),loading$: loading$.asObservable() )
    }
    
}
