//
//  SearchViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/17/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

protocol SearchBottomSheetViewModelProtocol {
    func transform(input:SearchBottomSheetViewModel.Input) -> SearchBottomSheetViewModel.Output
}



final class SearchBottomSheetViewModel:SearchBottomSheetViewModelProtocol {
    private let disposeBag = DisposeBag();
            
    private let screenMode$ = BehaviorRelay<HomeScreenMode>(value: .home)
    
    private weak var navigator: BottomSheetNavigator?

    private let placeUsecase:PlaceUsecaseProtocol?
    private var pagination = Pagination(pageSize: 20)

    
    private let places$ = BehaviorRelay<[Place]>(value: []);
    private let error$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let isSearching$ = BehaviorRelay<Bool>(value: false)
    private let isFetchingNext$ = BehaviorRelay<Bool>(value: false);

        
    private let isSearchingMode$ = BehaviorRelay<Bool>(value: false);
    
    private let keyword$ = BehaviorRelay<String>(value: "");
    
    
    
    init(navigator: BottomSheetNavigator? = nil, placeUsecase: PlaceUsecaseProtocol?) {
        self.navigator = navigator
        self.placeUsecase = placeUsecase
    }
        
    
    func transform(input:Input) -> Output {
            
    
        keyword$
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: {[weak self] keyword in
                guard let self = self else {
                    return;
                }
                
                if(!self.isSearchingMode$.value){
                    return
                }
                

                
                if keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.places$.accept([])
                    self.error$.accept(nil)
                    self.isSearching$.accept(false)
                    self.screenMode$.accept(.searchReady)
                    return
                }
                
                self.pagination.reset()
                self.getPlaces(keyword: keyword)
                self.screenMode$.accept(.searching)

                
            })
            .disposed(by: disposeBag)
        
        isSearchingMode$.asObservable().subscribe(onNext: {[weak self] isSearchingMode in
            guard let self = self else { return }
            if(isSearchingMode){
                if(self.keyword$.value.isEmpty){
                    self.screenMode$.accept(.searchReady)
                }
                else{
                    self.screenMode$.accept(.searching)
                }
            }
            else{
                self.screenMode$.accept(.home)
                self.keyword$.accept("")
            }
        }).disposed(by: disposeBag)
        
        input.cancelButtonTapped$
            .subscribe(onNext: {[weak self] in
                self?.places$.accept([])
                self?.error$.accept(nil)
                self?.pagination.reset();
                    
                self?.isSearchingMode$.accept(false)
                
            })
            .disposed(by: disposeBag)
        
        input.editingDidBegin$
            .subscribe(onNext: { [weak self] in
                self?.isSearchingMode$.accept(true);
            })
            .disposed(by: disposeBag)
        
        
        input.bottomReached$
            .debounce(.microseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext:{ [weak self] in
                guard let self = self else { return }
                if(self.keyword$.value.isEmpty){
                    return;
                }
                
                self.getMorePlaces(keyword: self.keyword$.value)
                
            })
            .disposed(by: disposeBag)
        
        input.placeCellSelected$
            .subscribe(onNext:{ [weak self] placeId in
                guard let self = self else { return }
             
                self.navigator?.present(.placeDetail(placeId))
                
            })
            .disposed(by: disposeBag)
        
        return Output(places$: places$.asObservable(), error$: error$.asObservable(), isSearching$: isSearching$.asObservable(), isFetchingNext$: isFetchingNext$.asObservable(),screenMode$: screenMode$.asObservable(), keywordRelay$: keyword$, keywordText$: keyword$.asDriver(onErrorJustReturn: ""), isSearchingMode$: isSearchingMode$.asObservable())
    }
    
    
    private func getPlaces(keyword:String){
        
        isSearching$.accept(true)
        
        Task{
            defer{
                isSearching$.accept(false)
            }
            
            let parameters = PlaceParameters(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeName: nil, name: keyword, prefix: nil, sort: nil)
            
            let result = await self.placeUsecase?.getPlaces(parameters: parameters)
            
            
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
            
            let parameters = PlaceParameters(limit: self.pagination.pageSize, page: self.pagination.page, placeTypeName: nil, name: keyword, prefix: nil, sort: nil)
            
            let result = await self.placeUsecase?.getPlaces(parameters: parameters)
            
            
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
        let cancelButtonTapped$:Observable<Void>
        let editingDidBegin$:Observable<Void>
//        let refetchButtonTapped$:Observable<Void>
        let bottomReached$:Observable<Void>
        let placeCellSelected$:Observable<String>
        
    }
    
    
    public struct Output {
        let places$:Observable<[Place]>
        let error$:Observable<NetworkError?>
        let isSearching$:Observable<Bool>
        let isFetchingNext$:Observable<Bool>
        let screenMode$:Observable<HomeScreenMode>
        let keywordRelay$: BehaviorRelay<String>
        let keywordText$: Driver<String>
        let isSearchingMode$:Observable<Bool>
    }
    
}
