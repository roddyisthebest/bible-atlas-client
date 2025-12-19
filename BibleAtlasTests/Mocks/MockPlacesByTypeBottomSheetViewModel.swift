//
//  MockPlacesByTypeBottomSheetViewModelForVC.swift
//  BibleAtlasTests
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockPlacesByTypeBottomSheetViewModel: PlacesByTypeBottomSheetViewModelProtocol {

    // MARK: - Outputs 흉내내는 Subject들

    /// VC에서 바인딩해서 tableView에 뿌릴 places
    let placesSubject = BehaviorSubject<[Place]>(value: [])

    /// 에러 상태 (nil or NetworkError)
    let errorSubject = BehaviorSubject<NetworkError?>(value: nil)

    /// 헤더 타이틀에 들어갈 PlaceTypeName
    let typeNameSubject = BehaviorSubject<PlaceTypeName?>(value: nil)

    /// 초기 로딩 여부
    let isInitialLoadingSubject = BehaviorSubject<Bool>(value: false)

    /// 페이지네이션 로딩 여부 (footer 로딩뷰)
    let isFetchingNextSubject = BehaviorSubject<Bool>(value: false)

    /// 시트 detent 강제 medium
    let forceMediumSubject = PublishSubject<Void>()

    /// detent 복원
    let restoreDetentsSubject = PublishSubject<Void>()

    // MARK: - Input 추적용 (테스트 검증용)

    private(set) var viewLoadedCallCount = 0
    private(set) var placeCellTappedIds: [String] = []
    private(set) var closeButtonTapCount = 0
    private(set) var bottomReachedCallCount = 0
    private(set) var refetchButtonTapCount = 0

    private let disposeBag = DisposeBag()

    // MARK: - transform

    func transform(input: PlacesByTypeBottomSheetViewModel.Input) -> PlacesByTypeBottomSheetViewModel.Output {

        input.viewLoaded$
            .subscribe(onNext: { [weak self] in
                self?.viewLoadedCallCount += 1
            })
            .disposed(by: disposeBag)

        input.placeCellTapped$
            .subscribe(onNext: { [weak self] placeId in
                self?.placeCellTappedIds.append(placeId)
            })
            .disposed(by: disposeBag)

        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.closeButtonTapCount += 1
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

        return PlacesByTypeBottomSheetViewModel.Output(
            places$: placesSubject.asObservable(),
            error$: errorSubject.asObservable(),
            typeName$: typeNameSubject.asObservable(),
            isInitialLoading$: isInitialLoadingSubject.asObservable(),
            isFetchingNext$: isFetchingNextSubject.asObservable(),
            forceMedium$: forceMediumSubject.asObservable(),
            restoreDetents$: restoreDetentsSubject.asObservable()
        )
    }
}
