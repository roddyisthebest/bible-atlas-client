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
    var screenMode$: RxSwift.Observable<HomeScreenMode>
    
    var keyword$: RxSwift.Observable<String>
    
    init(
        screenMode$: RxSwift.Observable<HomeScreenMode> = .never(),
        keyword$: RxSwift.Observable<String> = .never()
    ) {
        self.screenMode$ = screenMode$
        self.keyword$ = keyword$
    }

    // ====== VC 테스트에서 직접 컨트롤할 출력 스트림들 ======
    let _profile$ = BehaviorRelay<User?>(value: nil)
    let _isLoggedIn$ = BehaviorRelay<Bool>(value: false)
    let _screenMode$ = BehaviorRelay<HomeScreenMode>(value: .home)

    let _forceMedium$ = PublishRelay<Void>()
    let _restoreDetents$ = PublishRelay<Void>()


    // ====== transform에서 넘어온 Input을 잡아두고 싶으면 (선택) ======
    private(set) var lastInput: HomeBottomSheetViewModel.Input?

    func transform(input: HomeBottomSheetViewModel.Input) -> HomeBottomSheetViewModel.Output {
        // Input 보관 (원하면 테스트에서 검증 가능)
        lastInput = input

        // VC가 구독하는 Output만 구성해서 반환
        return .init(
            profile$: _profile$.asObservable(),
            isLoggedIn$: _isLoggedIn$.asObservable(),
            screenMode$: _screenMode$.asDriver(),
            keywordText$: keyword$.asDriver(onErrorJustReturn: ""),
            // ✅ 리팩 버전 VC는 isSearchingMode$를 더 안쓰면 "빈 스트림"으로 안전하게
            forceMedium$: _forceMedium$.asObservable(),
            restoreDetents$: _restoreDetents$.asObservable()
        )
    }
}

