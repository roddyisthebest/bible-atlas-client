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
    private var appStore:AppStoreProtocol?
    
    private var isLoggedIn$ = BehaviorRelay<Bool>(value:false)
    private var profile$ = BehaviorRelay<User?>(value:nil)
    
    private var likePlacesCount$ = BehaviorRelay<Int>(value:0);
    

    init(navigator:BottomSheetNavigator?, appStore:AppStoreProtocol?,userUsecase:UserUsecaseProtocol?){
        self.navigator = navigator
        self.appStore = appStore
        self.userUsecase = userUsecase
        bindAppStore();
    }
    
    func transform(input: Input) -> Output{
        
        
        
        
        
        Observable
            .combineLatest(input.avatarButtonTapped$, profile$)
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self ](_, profile) in
                
                if(profile != nil){
                    // TODO: implement mypage
                    print("my-page")
                    return;
                }
                
                
                self?.navigator?.present(.login)
            }.disposed(by: disposeBag)
            
 
        
        input.collectionButtonTapped$.subscribe(onNext: { [weak self] collectionType in
            self?.navigator?.present(.myCollection(collectionType))
        }).disposed(by: disposeBag)
        
        input.placesByTypeButtonTapped$.subscribe(onNext:{[weak self] in
            self?.navigator?.present(.placeTypes)
        }).disposed(by: disposeBag)
        
        input.placesByCharacterButtonTapped$.subscribe(onNext: {[weak self] in
            self?.navigator?.present(.placeCharacters)
        }).disposed(by: disposeBag)
        
        return Output(profile$: profile$.asObservable(), isLoggedIn$: isLoggedIn$.asObservable(),likePlacesCount$: likePlacesCount$.asObservable() )
        
    }
    
    
    func bindAppStore(){
        appStore?.state$.subscribe(onNext: { appState in
            self.profile$.accept(appState.profile)
            self.isLoggedIn$.accept(appState.isLoggedIn)
                
            if(appState.isLoggedIn){
                
                Task{
                    let result = await self.userUsecase?.getPlaces(limit:nil, page: nil, filter: .like)
                        
                    switch(result){
                    case .success(let response):
                        print(response,"response")
                        self.likePlacesCount$.accept(response.total)
                        break;
                    case .failure(let error):
                        print(error.description)
                        break
                    case .none:
                        break
                    }
                    
                            
                }
          
                        
                    
                
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
    }
    
  
    
    
}
