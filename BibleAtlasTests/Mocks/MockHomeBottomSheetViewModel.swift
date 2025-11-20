//
//  MockHomeBottomSheetViewModel.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/22/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

@testable import BibleAtlas

final class MockHomeBottomSheetViewModel: HomeBottomSheetViewModelProtocol {
    // Inputs (VC가 바인딩해서 쓸 것)

    let keyword$ = BehaviorRelay<String>(value: "")
    let cancelButtonTapped$ = PublishRelay<Void>()
    let isSearchingMode$ = BehaviorRelay<Bool>(value: false)

    // 내부 상태 시뮬레이션용
    let _profile$ = BehaviorRelay<User?>(value: nil)
    let _isLoggedIn$ = BehaviorRelay<Bool>(value: false)
    let _screenMode$ = BehaviorRelay<HomeScreenMode>(value: .home)
    let _forceMedium$ = PublishRelay<Void>();
    let _restoreDetents$ = PublishRelay<Void>()
    let _isSearchingMode$ = BehaviorRelay<Bool>(value: false)


    struct IO {
        let profile$: Observable<User?>
        let isLoggedIn$: Observable<Bool>
        let screenMode$: Observable<HomeScreenMode>
        let keyword$: BehaviorRelay<String>
        let keywordText$: Driver<String>
        let isSearchingMode$: Observable<Bool>
    }

    func transform(input: HomeBottomSheetViewModel.Input) -> HomeBottomSheetViewModel.Output {
        // 실전 VM 로직 재현 대신, 노출용 스트림을 모킹
        return .init(
            profile$: _profile$.asObservable(),
            isLoggedIn$: _isLoggedIn$.asObservable(),
            screenMode$: _screenMode$.asObservable(),
            keyword$: keyword$,
            keywordText$: keyword$.asDriver(onErrorJustReturn: ""),
            isSearchingMode$: _isSearchingMode$.asObservable(),
            forceMedium$: _forceMedium$.asObservable(),
            restoreDetents$: _restoreDetents$.asObservable()
        )
    }
}
