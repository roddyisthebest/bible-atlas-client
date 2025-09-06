//
//  CollectionStore.swift
//  BibleAtlas
//
//  Created by 배성연 on 8/2/25.
//

import Foundation
import RxRelay
struct CollectionState {
    var likedPlaceIds: Set<String>
    var bookmarkedPlaceIds: Set<String>
    var memoedPlaceIds: Set<String>
}

enum CollectionAction:Equatable {
    static func == (lhs: CollectionAction, rhs: CollectionAction) -> Bool {
        switch (lhs, rhs) {
        case let (.like(a), .like(b)):
            return a == b
        case let (.unlike(a), .unlike(b)):
            return a == b
        case let (.bookmark(a), .bookmark(b)):
            return a == b
        case let (.unbookmark(a), .unbookmark(b)):
            return a == b
        case let (.addMemo(a), .addMemo(b)):
            return a == b
        case let (.removeMemo(a), .removeMemo(b)):
            return a == b
        case (.reset, .reset):
            return true
        case let (.initialize(a), .initialize(b)):
            return a == b
        default:
            return false
        }
    }

    
    case like(String)
    case unlike(String)
    case bookmark(String)
    case unbookmark(String)
    case addMemo(String)
    case removeMemo(String)
    case reset
    case initialize(MyCollectionPlaceIds)
}


protocol CollectionStoreProtocol {
    var state$: BehaviorRelay<CollectionState> { get }
    func dispatch(_ action: CollectionAction)
}


final class CollectionStore: CollectionStoreProtocol {
    let state$ = BehaviorRelay<CollectionState>(
        value: CollectionState(
            likedPlaceIds: [],
            bookmarkedPlaceIds: [],
            memoedPlaceIds: []
        )
    )
    
    func dispatch(_ action: CollectionAction) {
        var state = state$.value
        
        switch action {
        case .like(let placeId):
            state.likedPlaceIds.insert(placeId)
            
        case .unlike(let placeId):
            state.likedPlaceIds.remove(placeId)
            
        case .bookmark(let placeId):
            state.bookmarkedPlaceIds.insert(placeId)
            
        case .unbookmark(let placeId):
            state.bookmarkedPlaceIds.remove(placeId)
            
        case .addMemo(let placeId):
            state.memoedPlaceIds.insert(placeId)
            
        case .removeMemo(let placeId):
            state.memoedPlaceIds.remove(placeId)
            
        case .initialize(let initial):
            state = CollectionState(
                likedPlaceIds: Set(initial.liked),
                bookmarkedPlaceIds: Set(initial.bookmarked),
                memoedPlaceIds: Set(initial.memoed)
            )
            
        case .reset:
            state = CollectionState(
                likedPlaceIds: Set<String>(),
                bookmarkedPlaceIds: Set<String>(),
                memoedPlaceIds: Set<String>()
            )
        }
        
        state$.accept(state)
    }
}

