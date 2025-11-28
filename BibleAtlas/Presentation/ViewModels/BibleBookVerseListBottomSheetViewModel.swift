//
//  BibleBookVerseListBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 10/3/25.
//

import Foundation
import RxSwift
import RxRelay

protocol BibleBookVerseListBottomSheetViewModelProtocol{
    func transform(input:BibleBookVerseListBottomSheetViewModel.Input) -> BibleBookVerseListBottomSheetViewModel.Output
}

final class BibleBookVerseListBottomSheetViewModel:BibleBookVerseListBottomSheetViewModelProtocol{

    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    private let placeUsecase:PlaceUsecaseProtocol?
    
    
    private let placeId:String
    
    private let selectedBibleBookAndVerses$ = BehaviorRelay<(BibleBook?,[Verse])>(value: (nil, []))
    private let bibles$ = BehaviorRelay<[Bible]>(value: [])
    
    private let isLoading$ = BehaviorRelay<Bool>(value: false)
    private let error$ = BehaviorRelay<NetworkError?>(value: nil)
    
    private let place$ = BehaviorRelay<Place?>(value: nil)
    
    init(navigator: BottomSheetNavigator? = nil, placeId:String, bibleBook:BibleBook?,  placeUsecase:PlaceUsecaseProtocol?) {
        self.navigator = navigator
        self.placeUsecase = placeUsecase
        self.placeId = placeId
        
        guard let bibleBook = bibleBook else{
            return
        }
        self.selectedBibleBookAndVerses$.accept((bibleBook, []))

    }

    
    func transform(input: Input) -> Output {
        
        Observable.merge(input.viewLoaded$, input.refetchButtonTapped$).subscribe(onNext:{[weak self] in
            guard let self = self else {
                return
            }
            self.getPlace()
        }).disposed(by: disposeBag)
     
        input.bibleBookChanged$.subscribe(onNext:{
            [weak self] bookName in
            guard let self = self else {
                return
            }
            self.changeBibleBook(bibleBook: bookName)
        }).disposed(by: disposeBag)
        
        
        input.closeButtonTapped$.subscribe(onNext:{
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        
        input.verseCellTapped$
            // 탭이 발생했을 때의 최신 place만 끌어온다 (place$ 변경으로 재발화 방지)
            .withLatestFrom(place$) { verse, place in (verse, place) }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] verse, place in
                guard let bibleBook = self?.selectedBibleBookAndVerses$.value.0 else {
                    return
                }
                    
                let localizedName = L10n.isEnglish ? place?.name : place?.koreanName
                if case let .def(text) = verse {
                    self?.navigator?.present(.bibleVerseDetail(bibleBook, text, localizedName))
                }
            })
            .disposed(by: disposeBag)
        
        
        
        return Output(error$: error$.asObservable(), isLoading$: isLoading$.asObservable() , selectedBibleBookAndVerses$: selectedBibleBookAndVerses$.asObservable(), bibles$: bibles$.asObservable(), place$: place$.asObservable())
    }
    
    
    func getPlace(){
        
        self.isLoading$.accept(true)
        self.error$.accept(nil)
        
        Task{
            defer{
                self.isLoading$.accept(false)
                
            }
            guard let result = await self.placeUsecase?.getPlace(placeId: placeId) else{
                self.error$.accept(.clientError(L10n.FatalError.reExec))
                return
            }
            
            switch(result){
                case .success(let place):
                self.place$.accept(place)
                guard let bibles = self.placeUsecase?.parseBible(verseString: place.verse) else{
                    self.error$.accept(.clientError(L10n.FatalError.reExec))
                    return
                }
                self.bibles$.accept(bibles)
                guard let selectedBook = self.selectedBibleBookAndVerses$.value.0 else{
                    return;
                }
                
                let selectedVerses = bibles.first{ $0.bookName == selectedBook }?.verses.map{Verse.def($0)} ?? []
                
                self.selectedBibleBookAndVerses$.accept((selectedBook, selectedVerses))
                
                case .failure(let error):
                    self.error$.accept(error)
            }
        }
        
    }
    
    
    
    func changeBibleBook(bibleBook:BibleBook){
        let selectedVerses = self.bibles$.value.first{ $0.bookName == bibleBook }?.verses.map{Verse.def($0)} ?? []
        
        self.selectedBibleBookAndVerses$.accept((bibleBook, selectedVerses))
    }
    
    
    public struct Input{
        let viewLoaded$:Observable<Void>
        let refetchButtonTapped$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
        let bibleBookChanged$:Observable<BibleBook>
        let verseCellTapped$:Observable<Verse>
    }
    
    public struct Output{
        let error$:Observable<NetworkError?>
        let isLoading$:Observable<Bool>
        let selectedBibleBookAndVerses$:Observable<(BibleBook?,[Verse])>
        let bibles$:Observable<[Bible]>
        let place$:Observable<Place?>
    }
    
    
    
}
