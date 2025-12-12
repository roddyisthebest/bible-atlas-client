//
//  MockPopularPlacesBottomSheetViewModelForVC.swift
//  BibleAtlasTests
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockPopularPlacesBottomSheetViewModel: PopularPlacesBottomSheetViewModelProtocol {

    // MARK: - Output Subjects (VC가 구독할 것들)

    let placesSubject = BehaviorSubject<[Place]>(value: [])
    let errorSubject = BehaviorSubject<NetworkError?>(value: nil)
    let isInitialLoadingSubject = BehaviorSubject<Bool>(value: false)
    let isFetchingNextSubject = BehaviorSubject<Bool>(value: false)
    let forceMediumSubject = PublishSubject<Void>()
    let restoreDetentsSubject = PublishSubject<Void>()

    // MARK: - 입력 추적용

    private(set) var viewLoadedCallCount = 0
    private(set) var closeButtonTapCount = 0
    private(set) var bottomReachedCallCount = 0
    private(set) var refetchButtonTapCount = 0
    private(set) var selectedPlaceIds: [String] = []

    private let disposeBag = DisposeBag()

    // MARK: - transform

    func transform(input: PopularPlacesBottomSheetViewModel.Input)
        -> PopularPlacesBottomSheetViewModel.Output
    {
        // viewLoaded / refetchButton
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

        // close 버튼
        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.closeButtonTapCount += 1
            })
            .disposed(by: disposeBag)

        // 셀 선택
        input.cellSelected$
            .subscribe(onNext: { [weak self] placeId in
                self?.selectedPlaceIds.append(placeId)
            })
            .disposed(by: disposeBag)

        // 바닥 도달
        input.bottomReached$
            .subscribe(onNext: { [weak self] in
                self?.bottomReachedCallCount += 1
            })
            .disposed(by: disposeBag)

        return PopularPlacesBottomSheetViewModel.Output(
            places$: placesSubject.asObservable(),
            error$: errorSubject.asObservable(),
            isInitialLoading$: isInitialLoadingSubject.asObservable(),
            isFetchingNext$: isFetchingNextSubject.asObservable(),
            forceMedium$: forceMediumSubject.asObservable(),
            restoreDetents$: restoreDetentsSubject.asObservable()
        )
    }
}
