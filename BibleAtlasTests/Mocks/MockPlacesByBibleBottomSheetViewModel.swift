//
//  MockPlacesByBibleBottomSheetViewModel.swift
//  BibleAtlasTests
//

import Foundation
import RxSwift
@testable import BibleAtlas

final class MockPlacesByBibleBottomSheetViewModel: PlacesByBibleBottomSheetViewModelProtocol {

    // MARK: - Output Subjects (VC에서 bind 받을 애들)

    let placesSubject = BehaviorSubject<[Place]>(value: [])
    let errorSubject = BehaviorSubject<NetworkError?>(value: nil)
    let bibleSubject = BehaviorSubject<BibleBook>(value: .Exod)
    let isInitialLoadingSubject = BehaviorSubject<Bool>(value: false)
    let isFetchingNextSubject = BehaviorSubject<Bool>(value: false)
    let forceMediumSubject = PublishSubject<Void>()
    let restoreDetentsSubject = PublishSubject<Void>()

    // MARK: - 입력 이벤트 추적용

    private(set) var viewLoadedCallCount = 0
    private(set) var closeButtonTapCount = 0
    private(set) var placeCellTapIds: [String] = []
    private(set) var bottomReachedCallCount = 0
    private(set) var refetchTapCount = 0

    private let disposeBag = DisposeBag()

    // MARK: - Transform

    func transform(input: PlacesByBibleBottomSheetViewModel.Input) -> PlacesByBibleBottomSheetViewModel.Output {

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
                self?.placeCellTapIds.append(placeId)
            })
            .disposed(by: disposeBag)

        input.bottomReached$
            .subscribe(onNext: { [weak self] in
                self?.bottomReachedCallCount += 1
            })
            .disposed(by: disposeBag)

        input.refetchButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.refetchTapCount += 1
            })
            .disposed(by: disposeBag)

        return PlacesByBibleBottomSheetViewModel.Output(
            places$: placesSubject.asObservable(),
            error$: errorSubject.asObservable(),
            bible$: bibleSubject.asObservable(),
            isInitialLoading$: isInitialLoadingSubject.asObservable(),
            isFetchingNext$: isFetchingNextSubject.asObservable(),
            forceMedium$: forceMediumSubject.asObservable(),
            restoreDetents$: restoreDetentsSubject.asObservable()
        )
    }
}
