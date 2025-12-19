//
//  MockPlaceCharactersBottomSheetViewModel.swift
//  BibleAtlasTests
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockPlaceCharactersBottomSheetViewModel: PlaceCharactersBottomSheetViewModelProtocol {
    
    // MARK: - Output Relays (VC가 구독하는 애들)
    let placeCharactersRelay = BehaviorRelay<[PlacePrefix]>(value: [])
    let errorRelay = BehaviorRelay<NetworkError?>(value: nil)
    let isInitialLoadingRelay = BehaviorRelay<Bool>(value: false)
    let forceMediumRelay = PublishRelay<Void>()
    let restoreDetentsRelay = PublishRelay<Void>()
    
    // MARK: - Input tracking
    private(set) var viewLoadedCallCount = 0
    private(set) var refetchButtonTapCount = 0
    private(set) var closeButtonTapCount = 0
    private(set) var lastTappedCharacter: String?
    
    private let disposeBag = DisposeBag()
    
    func transform(input: PlaceCharactersBottomSheetViewModel.Input) -> PlaceCharactersBottomSheetViewModel.Output {
        
        input.viewLoaded$
            .subscribe(onNext: { [weak self] in
                self?.viewLoadedCallCount += 1
            })
            .disposed(by: disposeBag)
        
        input.refetchButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.refetchButtonTapCount += 1
            })
            .disposed(by: disposeBag)
        
        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.closeButtonTapCount += 1
            })
            .disposed(by: disposeBag)
        
        input.placeCharacterCellTapped$
            .subscribe(onNext: { [weak self] character in
                self?.lastTappedCharacter = character
            })
            .disposed(by: disposeBag)
        
        return PlaceCharactersBottomSheetViewModel.Output(
            placeCharacter$: placeCharactersRelay.asObservable(),
            error$: errorRelay.asObservable(),
            isInitialLoading$: isInitialLoadingRelay.asObservable(),
            forceMedium$: forceMediumRelay.asObservable(),
            restoreDetents$: restoreDetentsRelay.asObservable()
        )
    }
}
