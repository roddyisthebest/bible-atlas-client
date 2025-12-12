// PlaceTypesBottomSheetMocks.swift
// 테스트 타겟에 넣기 (@testable import BibleAtlas)

import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockPlaceTypesBottomSheetViewModel: PlaceTypesBottomSheetViewModelProtocol {
    
    // MARK: - Inputs 기록용
    private(set) var receivedInput: PlaceTypesBottomSheetViewModel.Input?
    private(set) var placeTypeTapCount = 0
    private(set) var closeTapCount = 0
    private(set) var bottomReachedCount = 0
    private(set) var refetchTapCount = 0
    
    // MARK: - Outputs를 흉내내는 Subject
    let placeTypesSubject = BehaviorSubject<[PlaceTypeWithPlaceCount]>(value: [])
    let errorSubject = BehaviorSubject<NetworkError?>(value: nil)
    let isInitialLoadingSubject = BehaviorSubject<Bool>(value: false)
    let isFetchingNextSubject = BehaviorSubject<Bool>(value: false)
    let forceMediumSubject = PublishSubject<Void>()
    let restoreDetentsSubject = PublishSubject<Void>()
    
    private let disposeBag = DisposeBag()
    
    func transform(input: PlaceTypesBottomSheetViewModel.Input) -> PlaceTypesBottomSheetViewModel.Output {
        receivedInput = input
        
        input.placeTypeCellTapped$
            .subscribe(onNext: { [weak self] _ in
                self?.placeTypeTapCount += 1
            })
            .disposed(by: disposeBag)
        
        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.closeTapCount += 1
            })
            .disposed(by: disposeBag)
        
        input.bottomReached$
            .subscribe(onNext: { [weak self] in
                self?.bottomReachedCount += 1
            })
            .disposed(by: disposeBag)
        
        input.refetchButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.refetchTapCount += 1
            })
            .disposed(by: disposeBag)
        
        return PlaceTypesBottomSheetViewModel.Output(
            placeTypes$: placeTypesSubject.asObservable(),
            error$: errorSubject.asObservable(),
            isInitialLoading$: isInitialLoadingSubject.asObservable(),
            isFetchingNext$: isFetchingNextSubject.asObservable(),
            forceMedium$: forceMediumSubject.asObservable(),
            restoreDetents$: restoreDetentsSubject.asObservable()
        )
    }
}
