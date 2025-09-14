//
//  RecentSearchesBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/9/25.
//

import Foundation
import RxSwift
import RxRelay

protocol RecentSearchesBottomSheetViewModelProtocol{
    func transform(input:RecentSearchesBottomSheetViewModel.Input) -> RecentSearchesBottomSheetViewModel.Output
}

final class RecentSearchesBottomSheetViewModel:RecentSearchesBottomSheetViewModelProtocol{

    
    private let disposeBag = DisposeBag();
    
    private weak var navigator: BottomSheetNavigator?
        
    private let recentSearches$ = BehaviorRelay<[RecentSearchItem]>(value: []);
    
    private let errorToFetch$ = BehaviorRelay<RecentSearchError?>(value: nil)
    private let errorToInteract$ = BehaviorRelay<RecentSearchError?>(value: nil)

    private let schedular:SchedulerType

    
    private let isInitialLoading$ = BehaviorRelay<Bool>(value: true);
    private let isFetchingNext$ = BehaviorRelay<Bool>(value: false);
    
    private let recentSearchService:RecentSearchServiceProtocol?
    
    private var pagination = Pagination(pageSize: 15)

    
    init(navigator: BottomSheetNavigator?, recentSearchService: RecentSearchServiceProtocol?, schedular:SchedulerType = MainScheduler.instance) {
        self.navigator = navigator
        self.recentSearchService = recentSearchService
        self.schedular = schedular
    }
    
    func transform(input: Input) -> Output {
        
        Observable.merge(input.viewLoaded$, input.retryButtonTapped$).subscribe(onNext:{[weak self] in
            guard let self = self else { return }
            
            self.isInitialLoading$.accept(true)
            self.errorToFetch$.accept(nil)
            self.recentSearches$.accept([])
            self.pagination.reset()
            
            let result = self.recentSearchService?.fetch(limit: self.pagination.pageSize, page: self.pagination.page)
            
            self.isInitialLoading$.accept(false)
            switch(result){
                case .success(let response):
                    self.recentSearches$.accept(response.items)
                    self.pagination.update(total: response.total)

                case .failure(let error):
                    self.errorToFetch$.accept(error)
                default:
                    print("none")
            }
            
        }).disposed(by: disposeBag)
        
        input.bottomReached$.debounce(.microseconds(100), scheduler: schedular).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            
            if self.isFetchingNext$.value || !self.pagination.hasMore { return }
            
            self.isFetchingNext$.accept(true)
            
            
            guard self.pagination.advanceIfPossible() else { return }
            
            let result = self.recentSearchService?.fetch(limit: self.pagination.pageSize, page: self.pagination.page)
            
            self.isFetchingNext$.accept(false)
            switch(result){
            case.success(let response):
                let current = self.recentSearches$.value
                self.recentSearches$.accept(current + response.items)
                self.pagination.update(total: response.total)
            case .failure(let error):
                self.errorToFetch$.accept(error)
            case .none:
                print("none")
            }
            

        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        input.cellSelected$.subscribe(onNext:{ [weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId))
        }).disposed(by:disposeBag)
        
        input.allClearButtonTapped$.subscribe(onNext:{ [weak self] in
            let result = self?.recentSearchService?.clearAll();
            
            switch(result){
            case .success():
                self?.recentSearches$.accept([])
            case .failure(let error):
                self?.errorToInteract$.accept(error)
            default:
                print("none")
            }
            
            
        }).disposed(by:disposeBag)
        
        return Output(recentSearches$: recentSearches$.asObservable(), errorToFetch$: errorToFetch$.asObservable(), errorToInteract$: errorToInteract$.asObservable(), isInitialLoading$: isInitialLoading$.asObservable(), isFetchingNext$: isFetchingNext$.asObservable())
    }

    public struct Input {
        let viewLoaded$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
        let cellSelected$:Observable<String>
        let bottomReached$:Observable<Void>
        let retryButtonTapped$:Observable<Void>
        let allClearButtonTapped$:Observable<Void>
    }
    
    public struct Output{
        let recentSearches$:Observable<[RecentSearchItem]>
        let errorToFetch$:Observable<RecentSearchError?>
        let errorToInteract$:Observable<RecentSearchError?>
        let isInitialLoading$:Observable<Bool>
        let isFetchingNext$:Observable<Bool>
    }
    
    
}
