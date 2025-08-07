//
//  HomeBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/28/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

enum HomeScreenMode {
    case home
    case searchReady
    case searching
}


protocol HomeBottomSheetViewModelProtocol {
    func transform(input:HomeBottomSheetViewModel.Input) -> HomeBottomSheetViewModel.Output
    
    var isSearchingMode$: BehaviorRelay<Bool> { get }
    var keyword$: BehaviorRelay<String> { get }
    var cancelButtonTapped$: PublishRelay<Void> { get }
    
}

final class HomeBottomSheetViewModel:HomeBottomSheetViewModelProtocol {
        
    private let disposeBag = DisposeBag();

    private weak var navigator: BottomSheetNavigator?

    private let authUsecase:AuthUsecaseProtocol?

    private var appStore:AppStoreProtocol?
    
    private var recentSearchService: RecentSearchServiceProtocol?
    
    private var isLoggedIn$ = BehaviorRelay<Bool>(value:false)
    
    private var profile$ = BehaviorRelay<User?>(value:nil)
    
    private var screenMode$ = BehaviorRelay<HomeScreenMode>(value: .home)
    
    public let isSearchingMode$ = BehaviorRelay<Bool>(value: false);
    public let keyword$ = BehaviorRelay<String>(value: "");
    public let cancelButtonTapped$ = PublishRelay<Void>();
    

    init(navigator:BottomSheetNavigator?, appStore:AppStoreProtocol?, authUseCase:AuthUsecaseProtocol?, recentSearchService:RecentSearchServiceProtocol?){
        self.navigator = navigator
        self.appStore = appStore
        self.authUsecase = authUseCase
        self.recentSearchService = recentSearchService;
        bindAppStore();
    }
    
    func transform(input: Input) -> Output{
        
        

        input.avatarButtonTapped$
            .withLatestFrom(profile$)
            .subscribe(onNext: { [weak self] profile in
                guard let self = self else { return }
                if (profile != nil) {
                        self.navigator?.present(.myPage)
                } else {
                    self.navigator?.present(.login)
                }
            })
            .disposed(by: disposeBag)
        
        
        Observable
            .combineLatest(isSearchingMode$, keyword$)
            .map { isSearchingMode, keyword in
                let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                let screenMode: HomeScreenMode = isSearchingMode
                    ? (trimmed.isEmpty ? .searchReady : .searching)
                    : .home
                return screenMode
            }
            .distinctUntilChanged()
            .bind(to: screenMode$)
            .disposed(by: disposeBag)
        
        input.cancelButtonTapped$
            .bind{[weak self] in
                guard let self = self else { return }
                self.cancelButtonTapped$.accept(Void())
                self.isSearchingMode$.accept(false)
                self.keyword$.accept("")
            }
            .disposed(by: disposeBag)
        
        input.editingDidBegin$
            .bind { [weak self] in
                self?.isSearchingMode$.accept(true);
            }
            .disposed(by: disposeBag)
            
        return Output(profile$: profile$.asObservable(), isLoggedIn$: isLoggedIn$.asObservable(), screenMode$: screenMode$.asObservable(), keyword$: keyword$, keywordText$: keyword$.asDriver(onErrorJustReturn: ""), isSearchingMode$: isSearchingMode$.asObservable())
        
    }
    
    private func bindAppStore(){
        appStore?.state$.asObservable().subscribe(onNext:{[weak self] state in
            self?.isLoggedIn$.accept(state.isLoggedIn)
            self?.profile$.accept(state.profile)
        })
        .disposed(by: disposeBag)
    }
    
    
    public struct Input {
        let avatarButtonTapped$:Observable<Void>
        let cancelButtonTapped$:Observable<Void>
        let editingDidBegin$:Observable<Void>

    }
    
    public struct Output{
        let profile$:Observable<User?>
        let isLoggedIn$:Observable<Bool>
        let screenMode$:Observable<HomeScreenMode>
        let keyword$: BehaviorRelay<String>
        let keywordText$: Driver<String>
        let isSearchingMode$:Observable<Bool>

        
    }
    
  
    
    
}
