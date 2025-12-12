//
//  MockPlacesByCharacterBottomSheetViewModel.swift
//  BibleAtlasTests
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockPlacesByCharacterBottomSheetViewModel: PlacesByCharacterBottomSheetViewModelProtocol {

    // MARK: - Outputs 흉내낼 Subject/Relay

    let placesRelay = BehaviorRelay<[Place]>(value: [])
    let errorRelay = BehaviorRelay<NetworkError?>(value: nil)
    let characterRelay = BehaviorRelay<String>(value: "A")
    let isInitialLoadingRelay = BehaviorRelay<Bool>(value: false)
    let isFetchingNextRelay = BehaviorRelay<Bool>(value: false)
    let forceMediumRelay = PublishRelay<Void>()
    let restoreDetentsRelay = PublishRelay<Void>()

    private let disposeBag = DisposeBag()

    // MARK: - Input tracking

    private(set) var viewLoadedCallCount = 0
    private(set) var closeButtonTapCount = 0
    private(set) var placeCellTappedIds: [String] = []
    private(set) var bottomReachedCallCount = 0
    private(set) var refetchButtonTapCount = 0

    func transform(input: PlacesByCharacterBottomSheetViewModel.Input) -> PlacesByCharacterBottomSheetViewModel.Output {

        input.viewLoaded$
            .subscribe(onNext: { [weak self] in
                self?.viewLoadedCallCount += 1
            })
            .disposed(by: disposeBag)

        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.closeButtonTapCount += 1
            })
            .disposed(by: disposeBag)

        input.placeCellTapped$
            .subscribe(onNext: { [weak self] placeId in
                self?.placeCellTappedIds.append(placeId)
            })
            .disposed(by: disposeBag)

        input.bottomReached$
            .subscribe(onNext: { [weak self] in
                self?.bottomReachedCallCount += 1
            })
            .disposed(by: disposeBag)

        input.refetchButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.refetchButtonTapCount += 1
            })
            .disposed(by: disposeBag)

        return PlacesByCharacterBottomSheetViewModel.Output(
            places$: placesRelay.asObservable(),
            error$: errorRelay.asObservable(),
            character$: characterRelay.asObservable(),
            isInitialLoading$: isInitialLoadingRelay.asObservable(),
            isFetchingNext$: isFetchingNextRelay.asObservable(),
            forceMedium$: forceMediumRelay.asObservable(),
            restoreDetents$: restoreDetentsRelay.asObservable()
        )
    }
}
