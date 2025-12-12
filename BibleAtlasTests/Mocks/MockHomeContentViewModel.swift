//
//  MockHomeContentViewModel.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/22/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

@testable import BibleAtlas



final class MockHomeContentViewModel: HomeContentViewModelProtocol {
    // Inputs captured for assertions if needed
    private(set) var lastInput: HomeContentViewModel.Input?

    // Subjects to drive outputs
    private let profileSubject = BehaviorSubject<User?>(value: nil)
    private let isLoggedInSubject = BehaviorSubject<Bool>(value: false)

    private let likePlacesCountSubject = BehaviorSubject<Int>(value: 0)
    private let savePlacesCountSubject = BehaviorSubject<Int>(value: 0)
    private let memoPlacesCountSubject = BehaviorSubject<Int>(value: 0)

    private let recentSearchesSubject = BehaviorSubject<[RecentSearchItem]>(value: [])
    private let errorToFetchRecentSearchesSubject = BehaviorSubject<RecentSearchError?>(value: nil)

    private let loadingSubject = BehaviorSubject<Bool>(value: false)
    private let forceMediumSubject = PublishSubject<Void>()
    private let restoreDetentsSubject = PublishSubject<Void>()

    private let disposeBag = DisposeBag()

    init() {}

    func transform(input: HomeContentViewModel.Input) -> HomeContentViewModel.Output {
        self.lastInput = input
        return .init(
            profile$: profileSubject.asObservable(),
            isLoggedIn$: isLoggedInSubject.asObservable(),
            likePlacesCount$: likePlacesCountSubject.asObservable(),
            savePlacesCount$: savePlacesCountSubject.asObservable(),
            memoPlacesCount$: memoPlacesCountSubject.asObservable(),
            recentSearches$: recentSearchesSubject.asObservable(),
            errorToFetchRecentSearches$: errorToFetchRecentSearchesSubject.asObservable(),
            loading$: loadingSubject.asObservable(),
            forceMedium$: forceMediumSubject.asObservable(),
            restoreDetents$: restoreDetentsSubject.asObservable()
        )
    }

    // MARK: - Test control helpers
    func setCounts(like: Int, save: Int, memo: Int) {
        likePlacesCountSubject.onNext(like)
        savePlacesCountSubject.onNext(save)
        memoPlacesCountSubject.onNext(memo)
    }

    func setLoading(_ loading: Bool) { loadingSubject.onNext(loading) }

    func setRecentSearches(_ items: [RecentSearchItem]) { recentSearchesSubject.onNext(items) }

    func setError(_ error: RecentSearchError?) { errorToFetchRecentSearchesSubject.onNext(error) }

    func emitForceMedium() { forceMediumSubject.onNext(()) }

    func setLoggedIn(_ isLoggedIn: Bool) { isLoggedInSubject.onNext(isLoggedIn) }

    func setProfile(_ profile: User?) { profileSubject.onNext(profile) }
}
