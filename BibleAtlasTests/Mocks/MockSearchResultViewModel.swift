//
//  MockSearchResultViewModel.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/22/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

@testable import BibleAtlas

final class MockSearchResultViewModel: SearchResultViewModelProtocol {
    func transform(input: BibleAtlas.SearchResultViewModel.Input) -> BibleAtlas.SearchResultViewModel.Output {
        .init(places$: .just([]), errorToFetchPlaces$: .just(nil), errorToSaveRecentSearch$: .just(nil), isSearching$: .just(false), isFetchingNext$: .just(false), isSearchingMode$: .just(false), debouncedKeyword$: .just(""))
    }
    
   
    
}
