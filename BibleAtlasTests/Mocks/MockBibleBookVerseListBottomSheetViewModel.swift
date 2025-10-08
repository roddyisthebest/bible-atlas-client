//
//  MockBibleBookVerseListBottomSheetViewModel.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 10/8/25.
//


import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockBibleBookVerseListBottomSheetViewModel: BibleBookVerseListBottomSheetViewModelProtocol {
    // OUTPUT relays you can drive in tests
    let errorRelay    = BehaviorRelay<NetworkError?>(value: nil)
    let loadingRelay  = BehaviorRelay<Bool>(value: false)
    let selectedRelay = BehaviorRelay<(BibleBook?, [Verse])>(value: (nil, []))
    let biblesRelay   = BehaviorRelay<[Bible]>(value: [])
    let placeRelay    = BehaviorRelay<Place?>(value: nil)

    // Captured INPUTs
    private(set) var viewLoadedCount = 0
    private(set) var refetchCount = 0
    private(set) var closeTappedCount = 0
    private(set) var lastChangedBook: BibleBook?
    private(set) var lastTappedVerse: Verse?

    private let bag = DisposeBag()

    func transform(input: BibleBookVerseListBottomSheetViewModel.Input)
    -> BibleBookVerseListBottomSheetViewModel.Output {

        input.viewLoaded$
            .subscribe(onNext: { [weak self] in self?.viewLoadedCount += 1 })
            .disposed(by: bag)

        input.refetchButtonTapped$
            .subscribe(onNext: { [weak self] in self?.refetchCount += 1 })
            .disposed(by: bag)

        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in self?.closeTappedCount += 1 })
            .disposed(by: bag)

        input.bibleBookChanged$
            .subscribe(onNext: { [weak self] book in self?.lastChangedBook = book })
            .disposed(by: bag)

        input.verseCellTapped$
            .subscribe(onNext: { [weak self] verse in self?.lastTappedVerse = verse })
            .disposed(by: bag)

        return .init(
            error$: errorRelay.asObservable(),
            isLoading$: loadingRelay.asObservable(),
            selectedBibleBookAndVerses$: selectedRelay.asObservable(),
            bibles$: biblesRelay.asObservable(),
            place$: placeRelay.asObservable()
        )
    }
}

