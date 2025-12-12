//
//  MockBiblesBottomSheetViewModel.swift
//  BibleAtlasTests
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockBiblesBottomSheetViewModel: BiblesBottomSheetViewModelProtocol {
    
    // MARK: - Outputs Stub용 Relay
    let bibleBookCountsRelay = BehaviorRelay<[BibleBookCount]>(value: [])
    let errorRelay = BehaviorRelay<NetworkError?>(value: nil)
    let isInitialLoadingRelay = BehaviorRelay<Bool>(value: false)
    let forceMediumRelay = PublishRelay<Void>()
    let restoreDetentsRelay = PublishRelay<Void>()
    
    // MARK: - Input 기록용
    private(set) var cellTappedBooks: [BibleBook] = []
    private(set) var closeButtonTapCount = 0
    private(set) var viewLoadedCount = 0
    private(set) var refetchButtonTapCount = 0
    
    private let disposeBag = DisposeBag()
    
    func transform(input: BiblesBottomSheetViewModel.Input) -> BiblesBottomSheetViewModel.Output {
        
        input.cellTapped$
            .subscribe(onNext: { [weak self] bible in
                self?.cellTappedBooks.append(bible)
            })
            .disposed(by: disposeBag)
        
        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.closeButtonTapCount += 1
            })
            .disposed(by: disposeBag)
        
        input.viewLoaded$
            .subscribe(onNext: { [weak self] in
                self?.viewLoadedCount += 1
            })
            .disposed(by: disposeBag)
        
        input.refetchButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.refetchButtonTapCount += 1
            })
            .disposed(by: disposeBag)
        
        return BiblesBottomSheetViewModel.Output(
            bibleBookCounts$: bibleBookCountsRelay.asObservable(),
            error$: errorRelay.asObservable(),
            isInitialLoading$: isInitialLoadingRelay.asObservable(),
            forceMedium$: forceMediumRelay.asObservable(),
            restoreDetents$: restoreDetentsRelay.asObservable()
        )
    }
}
