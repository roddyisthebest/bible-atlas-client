//
//  MockSearchResultViewModel.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/22/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

@testable import BibleAtlas

final class MockSearchResultViewModel: SearchResultViewModelProtocol {

    struct CapturedInput {
        var refetchTapped: Bool = false
        var bottomReachedCount: Int = 0
        var lastSelectedPlace: Place?
    }

    // Outputs as Relays to let tests drive UI
    let placesRelay = BehaviorRelay<[Place]>(value: [])
    let errorToFetchPlacesRelay = BehaviorRelay<NetworkError?>(value: nil)
    let errorToSaveRecentSearchRelay = BehaviorRelay<RecentSearchError?>(value: nil)
    let isSearchingRelay = BehaviorRelay<Bool>(value: false)
    let isFetchingNextRelay = BehaviorRelay<Bool>(value: false)
    let isSearchingModeRelay = BehaviorRelay<Bool>(value: true)
    let debouncedKeywordRelay = BehaviorRelay<String>(value: "")

    private(set) var captured = CapturedInput()
    private let bag = DisposeBag()

    func transform(input: BibleAtlas.SearchResultViewModel.Input) -> BibleAtlas.SearchResultViewModel.Output {
        // Observe inputs to capture interactions
        input.refetchButtonTapped$
            .subscribe(onNext: { [weak self] in self?.captured.refetchTapped = true })
            .disposed(by: bag)

        input.bottomReached$
            .subscribe(onNext: { [weak self] in self?.captured.bottomReachedCount += 1 })
            .disposed(by: bag)

        input.placeCellSelected$
            .subscribe(onNext: { [weak self] place in self?.captured.lastSelectedPlace = place })
            .disposed(by: bag)

        return BibleAtlas.SearchResultViewModel.Output(
            places$: placesRelay.asObservable(),
            errorToFetchPlaces$: errorToFetchPlacesRelay.asObservable(),
            errorToSaveRecentSearch$: errorToSaveRecentSearchRelay.asObservable(),
            isSearching$: isSearchingRelay.asObservable(),
            isFetchingNext$: isFetchingNextRelay.asObservable(),
            isSearchingMode$: isSearchingModeRelay.asObservable(),
            debouncedKeyword$: debouncedKeywordRelay.asObservable()
        )
    }
}
