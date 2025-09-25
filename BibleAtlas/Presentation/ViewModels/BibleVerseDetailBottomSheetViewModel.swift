//
//  BibleVerseDetailBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/4/25.
//

import Foundation
import RxSwift
import RxRelay

protocol BibleVerseDetailBottomSheetViewModelProtocol {
    func transform(input:BibleVerseDetailBottomSheetViewModel.Input) -> BibleVerseDetailBottomSheetViewModel.Output
}


final class BibleVerseDetailBottomSheetViewModel: BibleVerseDetailBottomSheetViewModelProtocol {
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
        
    
    private let bibleVerse$ = BehaviorRelay<String>(value:"");
    private let error$ = BehaviorRelay<NetworkError?>(value: nil)
    private let isLoading$ = BehaviorRelay<Bool>(value: true);
    private let title$ = BehaviorRelay<String?>(value: nil);
    private let bibleBook$ = BehaviorRelay<BibleBook>(value:.Etc)
    

    
    private let placeUsecase:PlaceUsecaseProtocol?
    
    

    
    init(navigator: BottomSheetNavigator? = nil, bibleBook:BibleBook, keyword: String, placeUsecase:PlaceUsecaseProtocol?) {
        self.navigator = navigator

        self.title$.accept("\(bibleBook.title()) \(keyword)")
        self.bibleBook$.accept(bibleBook)
        self.placeUsecase = placeUsecase
    }
    
    func preferredBibleVersion() -> BibleVersion {
        // 앱이 현재 사용하는 로케일(번들 로컬라이즈 우선)
        let lang = Bundle.main.preferredLocalizations.first
            ?? Locale.preferredLanguages.first
            ?? "en"
        switch lang.prefix(2) {
        case "ko": return .kor
        default:   return .niv
        }
    }
    
    
    func transform(input: Input) -> Output {
        
        input.viewLoaded$.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            
            Task{
                defer{
                    self.isLoading$.accept(false)
                }
                

                
                let chapter: String? = self.title$.value?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .split(whereSeparator: \.isWhitespace).last       // "1.21"
                    .flatMap { $0.split(separator: ".", maxSplits: 1).first } // "1"
                    .map(String.init)
                
                let verse = self.title$.value?.trimmingCharacters(in: .whitespacesAndNewlines)
                    .split(separator: ".")
                    .last.map{ String.init($0) }
                
                
                
                let result = await self.placeUsecase?.getBibleVerse(version: self.preferredBibleVersion(), book: self.bibleBook$.value.code, chapter: chapter ?? "1" , verse: verse ?? "1")
                
                
                switch(result){
                    case .success(let response):
                        self.bibleVerse$.accept(response.text)
                    case .failure(let error):
                        self.error$.accept(error)
                    case .none:
                        print("none")
                }
                
            }
            

        }).disposed(by: disposeBag)
        
        input.refetchButtonTapped$.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            
            self.isLoading$.accept(true);
            self.error$.accept(nil)
            
            Task{
                defer{
                    self.isLoading$.accept(false)
                }
                
                let chapter = self.title$.value?.split(separator: ".").first.map{ String.init($0) }
                let verse = self.title$.value?.split(separator: ".").last.map{ String.init($0) }
                
                let result = await self.placeUsecase?.getBibleVerse(version: .kor, book: self.bibleBook$.value.code, chapter: chapter ?? "1" , verse: verse ?? "1")
                
                
                switch(result){
                    case .success(let response):
                        self.bibleVerse$.accept(response.text)
                    case .failure(let error):
                        self.error$.accept(error)
                    case .none:
                        print("none")
                }
                
            }
            

        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            self.navigator?.dismiss(animated: true)

        }).disposed(by: disposeBag)
        
        
        return Output(bibleVerse$: bibleVerse$.asObservable(), error$: error$.asObservable(), isLoading$: isLoading$.asObservable(), title$: title$.asObservable())
        
    }
    
    
    
    public struct Input {
        let viewLoaded$:Observable<Void>
        let refetchButtonTapped$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
    }
    
    public struct Output {
        let bibleVerse$:Observable<String>
        let error$:Observable<NetworkError?>
        let isLoading$:Observable<Bool>
        let title$:Observable<String?>
    }
}

