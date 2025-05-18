//
//  AppStore.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/17/25.
//

import Foundation
import RxSwift
import RxRelay

struct AppState {
    var profile: User?
    var isLoggedIn: Bool
}

enum AppAction {
    case login(User)
    case logout
}

protocol AppStoreProtocol {
    var state$: BehaviorRelay<AppState> { get }
    func dispatch(_ action: AppAction)
}

// ✅ AppStore 구현
final class AppStore: AppStoreProtocol {
    let state$ = BehaviorRelay<AppState>(value: AppState(profile: nil, isLoggedIn:false ))

    func dispatch(_ action: AppAction) {
        var state = state$.value

        switch action {
        case .login(let profile):
            state.profile = profile
            state.isLoggedIn = true

        case .logout:
            state.profile = nil
            state.isLoggedIn = false
        }

        state$.accept(state)
    }
}

