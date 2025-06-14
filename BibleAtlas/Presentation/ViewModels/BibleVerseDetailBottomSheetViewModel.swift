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
    private let keyword$ = BehaviorRelay<String?>(value: nil);

    
    private let keyword:String
    
    private let placeUsecase:PlaceUsecaseProtocol?
    
    

    
    init(navigator: BottomSheetNavigator? = nil, keyword: String, placeUsecase:PlaceUsecaseProtocol?) {
        self.navigator = navigator
        self.keyword = keyword
        self.keyword$.accept(keyword)
        self.placeUsecase = placeUsecase
    }
    
    func transform(input: Input) -> Output {
        
        input.viewLoaded$.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            
            Task{
                defer{
                    self.isLoading$.accept(false)
                }
                
                let book = self.keyword.split(separator: " ").first.map{ String.init($0)}
                
                let chapter = self.keyword.split(separator: " ").last.map{
                    String.init($0)
                }?.split(separator: ".").first.map{ String.init($0) }
                
                let verse = self.keyword.split(separator: " ").last.map{
                    String.init($0)
                }?.split(separator: ".").last.map{ String.init($0) }
                
                let result = await self.placeUsecase?.getBibleVerse(version: .kor, book: book ?? "Gen", chapter: chapter ?? "1" , verse: verse ?? "1")
                
                
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
                
                let book = self.keyword.split(separator: " ").first.map{ String.init($0)}
                
                let chapter = self.keyword.split(separator: " ").last.map{
                    String.init($0)
                }?.split(separator: ".").first.map{ String.init($0) }
                
                let verse = self.keyword.split(separator: " ").last.map{
                    String.init($0)
                }?.split(separator: ".").last.map{ String.init($0) }
                
                let result = await self.placeUsecase?.getBibleVerse(version: .kor, book: book ?? "Gen", chapter: chapter ?? "1" , verse: verse ?? "1")
                
                
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
        
        
        return Output(bibleVerse$: bibleVerse$.asObservable(), error$: error$.asObservable(), isLoading$: isLoading$.asObservable(), keyword$: keyword$.asObservable())
        
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
        let keyword$:Observable<String?>
    }
}

