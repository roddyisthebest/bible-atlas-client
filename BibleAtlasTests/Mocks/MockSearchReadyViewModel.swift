//
//  MockSearchReadyViewModel.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/22/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

@testable import BibleAtlas

final class MockSearchReadyViewModel: SearchReadyViewModelProtocol {
    func transform(input: SearchReadyViewModel.Input) -> SearchReadyViewModel.Output {
        return .init(
            popularPlaces$: .just([]), recentSearches$: .just([]),
            errorToFetchPlaces$: .just(nil), errorToFetchRecentSearches$: .just(nil),
            isFetching$: .just(false)
        )
    }
}



