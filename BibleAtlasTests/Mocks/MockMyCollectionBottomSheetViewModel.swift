//
//  MockMyCollectionBottomSheetViewModel.swift
//  BibleAtlasTests
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockMyCollectionBottomSheetViewModel: MyCollectionBottomSheetViewModelProtocol {
    
    // MARK: - Outputs 대체용 Relay
    let placesRelay = BehaviorRelay<[Place]>(value: [])
    let errorRelay = BehaviorRelay<NetworkError?>(value: nil)
    let filterRelay: BehaviorRelay<PlaceFilter>
    let isInitialLoadingRelay = BehaviorRelay<Bool>(value: false)
    let isFetchingNextRelay = BehaviorRelay<Bool>(value: false)
    let forceMediumRelay = PublishRelay<Void>()
    let restoreDetentsRelay = PublishRelay<Void>()
    
    // MARK: - Input 기록용
    private(set) var myCollectionViewLoadedCount = 0
    private(set) var closeButtonTapCount = 0
    private(set) var selectedPlaceIds: [String] = []
    private(set) var bottomReachedCount = 0
    private(set) var refetchButtonTapCount = 0
    
    private let disposeBag = DisposeBag()
    
    init(initialFilter: PlaceFilter = .like) {
        self.filterRelay = BehaviorRelay(value: initialFilter)
    }
    
    func transform(input: MyCollectionBottomSheetViewModel.Input) -> MyCollectionBottomSheetViewModel.Output {
        
        input.myCollectionViewLoaded$
            .subscribe(onNext: { [weak self] in
                self?.myCollectionViewLoadedCount += 1
            })
            .disposed(by: disposeBag)
        
        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.closeButtonTapCount += 1
            })
            .disposed(by: disposeBag)
        
        input.placeTabelCellSelected$
            .subscribe(onNext: { [weak self] placeId in
                self?.selectedPlaceIds.append(placeId)
            })
            .disposed(by: disposeBag)
        
        input.bottomReached$
            .subscribe(onNext: { [weak self] in
                self?.bottomReachedCount += 1
            })
            .disposed(by: disposeBag)
        
        input.refetchButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.refetchButtonTapCount += 1
            })
            .disposed(by: disposeBag)
        
        return MyCollectionBottomSheetViewModel.Output(
            places$: placesRelay.asObservable(),
            error$: errorRelay.asObservable(),
            filter$: filterRelay.asObservable(),
            isInitialLoading$: isInitialLoadingRelay.asObservable(),
            isFetchingNext$: isFetchingNextRelay.asObservable(),
            forceMedium$: forceMediumRelay.asObservable(),
            restoreDetents$: restoreDetentsRelay.asObservable()
        )
    }
}
