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
    func transform(input: BibleAtlas.HomeContentViewModel.Input) -> BibleAtlas.HomeContentViewModel.Output {
        .init(profile$: .just(nil), isLoggedIn$: .just(false), likePlacesCount$: .just(1), savePlacesCount$: .just(1), memoPlacesCount$: .just(1), recentSearches$: .just([]), errorToFetchRecentSearches$: .just(nil), loading$: .just(false), forceMedium$: .just(()), restoreDetents$: .just(()) )
    }
}


