//
//  MockRecentSearchesBottomSheetViewModel.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockRecentSearchesBottomSheetViewModel: RecentSearchesBottomSheetViewModelProtocol {
    
    // MARK: - Output Subjects (테스트에서 직접 onNext로 UI 구동)
    let recentSearchesSubject = PublishSubject<[RecentSearchItem]>()
    let errorToFetchSubject = PublishSubject<RecentSearchError?>()
    let errorToInteractSubject = PublishSubject<RecentSearchError?>()
    let isInitialLoadingSubject = PublishSubject<Bool>()
    let isFetchingNextSubject = PublishSubject<Bool>()
    let forceMediumSubject = PublishSubject<Void>()
    let restoreDetentsSubject = PublishSubject<Void>()
    
    var transformCallCount = 0

    // MARK: - 입력 이벤트 기록용
    private(set) var viewLoadedCallCount = 0
    private(set) var closeButtonTapCount = 0
    private(set) var bottomReachedCallCount = 0
    private(set) var retryButtonTapCount = 0
    private(set) var allClearButtonTapCount = 0
    private(set) var selectedPlaceIds: [String] = []
    
    private let disposeBag = DisposeBag()
    
    func transform(input: RecentSearchesBottomSheetViewModel.Input)
        -> RecentSearchesBottomSheetViewModel.Output {
        
        transformCallCount += 1

        // ✅ viewLoaded$
        input.viewLoaded$
            .subscribe(onNext: { [weak self] in
                self?.viewLoadedCallCount += 1
            })
            .disposed(by: disposeBag)
        
        // ✅ closeButtonTapped$
        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.closeButtonTapCount += 1
            })
            .disposed(by: disposeBag)
        
        // ✅ cellSelected$
        input.cellSelected$
            .subscribe(onNext: { [weak self] placeId in
                self?.selectedPlaceIds.append(placeId)
            })
            .disposed(by: disposeBag)
        
        // ✅ bottomReached$
        input.bottomReached$
            .subscribe(onNext: { [weak self] in
                self?.bottomReachedCallCount += 1
            })
            .disposed(by: disposeBag)
        
        // ✅ retryButtonTapped$
        input.retryButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.retryButtonTapCount += 1
            })
            .disposed(by: disposeBag)
        
        // ✅ allClearButtonTapped$
        input.allClearButtonTapped$
            .subscribe(onNext: { [weak self] in
                self?.allClearButtonTapCount += 1
            })
            .disposed(by: disposeBag)
        
        // VC에서 구독할 Output들은 Subject를 asObservable로 감싸서 돌려줌
        return RecentSearchesBottomSheetViewModel.Output(
            recentSearches$: recentSearchesSubject.asObservable(),
            errorToFetch$: errorToFetchSubject.asObservable(),
            errorToInteract$: errorToInteractSubject.asObservable(),
            isInitialLoading$: isInitialLoadingSubject.asObservable(),
            isFetchingNext$: isFetchingNextSubject.asObservable(),
            forceMedium$: forceMediumSubject.asObservable(),
            restoreDetents$: restoreDetentsSubject.asObservable()
        )
    }
}
