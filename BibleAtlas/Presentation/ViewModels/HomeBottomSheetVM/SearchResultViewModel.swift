//
//  SearchResultViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/21/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

protocol SearchResultViewModelProtocol {
    func transform(input:SearchResultViewModel.Input) -> SearchResultViewModel.Output
}


final class SearchResultViewModel:SearchResultViewModelProtocol {
    private let disposeBag = DisposeBag();

    private weak var navigator: BottomSheetNavigator?

    private let placeUsecase:PlaceUsecaseProtocol?
    private var pagination = Pagination(pageSize: 20)

    
    private let places$ = BehaviorRelay<[Place]>(value: []);
    private let error$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let isSearching$ = BehaviorRelay<Bool>(value: false)
    private let isFetchingNext$ = BehaviorRelay<Bool>(value: false);

    private let isSearchingMode$:Observable<Bool>
    private let keyword$:Observable<String>
    private let cancelButtonTapped$:Observable<Void>
    
    private let recentSearchService: RecentSearchServiceProtocol?
    
    
    init(navigator: BottomSheetNavigator? = nil, placeUsecase: PlaceUsecaseProtocol?, isSearchingMode$:Observable<Bool>, keyword$:Observable<String>, cancelButtonTapped$:Observable<Void>, recentSearchService:RecentSearchServiceProtocol? ) {
        self.navigator = navigator
        self.placeUsecase = placeUsecase
        self.isSearchingMode$ = isSearchingMode$
        self.keyword$ = keyword$
        self.cancelButtonTapped$ = cancelButtonTapped$
        self.recentSearchService = recentSearchService
    }
        
    
    func transform(input:Input) -> Output {

        let debouncedKeyword$ = keyword$
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
        
        Observable.combineLatest(debouncedKeyword$, isSearchingMode$)
            .subscribe(onNext: {[weak self] keyword, isSearchingMode in
                guard let self = self else {
                    return;
                }
                if(!isSearchingMode){
                    return
                }
                
                
                if keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.places$.accept([])
                    self.error$.accept(nil)
                    self.isSearching$.accept(false)
                    return
                }
                
                self.pagination.reset()
                self.getPlaces(keyword: keyword)
                
            })
            .disposed(by: disposeBag)
        
       
            
        let debouncedBottomReached$ = input.bottomReached$
            .debounce(.microseconds(500), scheduler: MainScheduler.instance)
        
        Observable.combineLatest(debouncedBottomReached$, keyword$)
            .subscribe(onNext: { [weak self] _, keyword in
                guard let self = self else { return }
                if(keyword.isEmpty){
                    return;
                }
                
                self.getMorePlaces(keyword: keyword)


            })
            .disposed(by: disposeBag)
        
        
        input.placeCellSelected$
            .subscribe(onNext:{ [weak self] place in
                guard let self = self else { return }
                
                let result = self.recentSearchService?.save(place)
                
                switch(result){
                case .success():
                    print("success")
                    self.navigator?.present(.placeDetail(place.id))
                case .failure(let error):
                    print(error.description)
                default:
                    print("none")
                }

            })
            .disposed(by: disposeBag)
        
        return Output(places$: places$.asObservable(), error$: error$.asObservable(), isSearching$: isSearching$.asObservable(), isFetchingNext$: isFetchingNext$.asObservable(), isSearchingMode$: isSearchingMode$.asObservable())
    }
    
    
    private func getPlaces(keyword:String){
        
        isSearching$.accept(true)
        
        Task{
            defer{
                isSearching$.accept(false)
            }
            let result = await self.placeUsecase?.getPlaces(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeId: nil, name: keyword, prefix: nil, sort: nil)
            
            
            switch(result){
            case .success(let response):
                self.places$.accept(response.data)
                self.pagination.update(total: response.total)
                self.error$.accept(nil)
            case .failure(let error):
                error$.accept(error)
            default:
                print("none")
            }
            
        }
    }
    
    private func getMorePlaces(keyword:String){
        if self.isFetchingNext$.value || !self.pagination.hasMore { return }
        
        self.isFetchingNext$.accept(true);
        
        Task{
            defer{
                self.isFetchingNext$.accept(false);
            }
            
            guard self.pagination.advanceIfPossible() else { return }
            
            let result = await self.placeUsecase?.getPlaces(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeId: nil, name: keyword, prefix: nil, sort: nil)
            
            
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
//        let refetchButtonTapped$:Observable<Void>
        let bottomReached$:Observable<Void>
        let placeCellSelected$:Observable<Place>
    }
    
    
    public struct Output {
        let places$:Observable<[Place]>
        let error$:Observable<NetworkError?>
        let isSearching$:Observable<Bool>
        let isFetchingNext$:Observable<Bool>
        let isSearchingMode$:Observable<Bool>
    }
    
}
