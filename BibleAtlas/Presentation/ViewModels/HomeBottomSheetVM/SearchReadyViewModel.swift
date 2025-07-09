//
//  SearchReadyViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/21/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

protocol SearchReadyViewModelProtocol {
    func transform(input: SearchReadyViewModel.Input) -> SearchReadyViewModel.Output
    
}

final class SearchReadyViewModel: SearchReadyViewModelProtocol {
    private let disposeBag = DisposeBag();

    private weak var navigator: BottomSheetNavigator?

    private let placeUsecase:PlaceUsecaseProtocol?
    
    private let recentSearchService:RecentSearchServiceProtocol?
    
    private let popularPlaces$ = BehaviorRelay<[Place]>(value: []);
    private let recentSearches$ = BehaviorRelay<[RecentSearchItem]>(value: []);

    private let errorToFetchPlaces$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let isFetching$ = BehaviorRelay<Bool>(value: false)
    
    init(navigator: BottomSheetNavigator?, placeUsecase: PlaceUsecaseProtocol?, recentSearchService:RecentSearchServiceProtocol?) {
        self.navigator = navigator
        self.placeUsecase = placeUsecase
        self.recentSearchService = recentSearchService
        
        bindRecentSearchService();
        getRecentSearchItems();
    }
    
    
    func transform(input:Input) -> Output {
        
        Observable.merge(input.popularPlaceCellTapped$, input.recentSearchCellTapped$)
            .subscribe(onNext: {[weak self] placeId in
            self?.navigator?.present(.placeDetail(placeId))
            })
        .disposed(by: disposeBag)
        
        Observable.merge(input.viewLoaded$, input.refetchButtonTapped$).subscribe(onNext: { [weak self] in
            self?.getPlaces();
            
        }).disposed(by: disposeBag)
        

        
        input.moreRecentSearchesButtonTapped$
            .subscribe(onNext:{[weak self] in
                self?.navigator?.present(.recentSearches)
            })
            .disposed(by: disposeBag)
    
        

        
        return Output(popularPlaces$: popularPlaces$.asObservable(), recentSearches$: recentSearches$.asObservable(), errorToFetchPlaces$: errorToFetchPlaces$.asObservable(), isFetching$: isFetching$.asObservable())

    }
    
    
    private func getPlaces(){
        isFetching$.accept(true)
        errorToFetchPlaces$.accept(nil)
        Task{
            defer{
                isFetching$.accept(false)
            }
            
            let result = await self.placeUsecase?.getPlaces(limit: 5, page: 0, placeTypeId: nil, name: nil, prefix: nil, sort: .like)
            
            switch(result){
                case .success(let response):
                    popularPlaces$.accept(response.data)
                case .failure(let error):
                    errorToFetchPlaces$.accept(error)
                default:
                    print("none")
            }
            
            
        }
        
    }
    
    
    private func bindRecentSearchService(){
        self.recentSearchService?.didChanged$.subscribe(onNext:{[weak self] in
            self?.getRecentSearchItems()
        }).disposed(by: disposeBag)

    }
        
    
 
    
    
    private func getRecentSearchItems(){
        let result = self.recentSearchService?.fetch(limit: 5, page:nil)
        switch(result){
        case .success(let response):
            self.recentSearches$.accept(response.items)
            print(response)
        case .failure(let error):
            print(error.description)
        default:
            print("wo")
        }
    }
    
    
    public struct Input {
        let refetchButtonTapped$:Observable<Void>
        let popularPlaceCellTapped$:Observable<String>
        let recentSearchCellTapped$:Observable<String>
        let viewLoaded$:Observable<Void>
        let moreRecentSearchesButtonTapped$:Observable<Void>
    }
    
    public struct Output{
        let popularPlaces$:Observable<[Place]>
        let recentSearches$:Observable<[RecentSearchItem]>
        let errorToFetchPlaces$:Observable<NetworkError?>
        let isFetching$:Observable<Bool>
    }
    
    
}
