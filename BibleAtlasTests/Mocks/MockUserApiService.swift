//
//  MockUserApiService.swift
//  BibleAtlasTests
//

import Foundation
@testable import BibleAtlas

final class MockUserApiService: UserApiServiceProtocol {
    
    // MARK: - getPlaces 추적용
    private(set) var getPlacesCalled = false
    private(set) var lastGetPlacesLimit: Int?
    private(set) var lastGetPlacesPage: Int?
    private(set) var lastGetPlacesFilter: PlaceFilter?
    var getPlacesResult: Result<ListResponse<Place>, NetworkError> =
        .failure(.clientError("no stub for getPlaces"))
    
    // MARK: - getMyCollectionPlaceIds 추적용
    private(set) var getMyCollectionCalled = false
    var getMyCollectionResult: Result<MyCollectionPlaceIds, NetworkError> =
        .failure(.clientError("no stub for getMyCollectionPlaceIds"))
    
    // MARK: - getProfile 추적용
    private(set) var getProfileCalled = false
    var getProfileResult: Result<User, NetworkError> =
        .failure(.clientError("no stub for getProfile"))
    
    // MARK: - Protocol 구현
    
    func getPlaces(limit: Int?, page: Int?, filter: PlaceFilter?) async -> Result<ListResponse<Place>, NetworkError> {
        getPlacesCalled = true
        lastGetPlacesLimit = limit
        lastGetPlacesPage = page
        lastGetPlacesFilter = filter
        return getPlacesResult
    }
    
    func getMyCollectionPlaceIds() async -> Result<MyCollectionPlaceIds, NetworkError> {
        getMyCollectionCalled = true
        return getMyCollectionResult
    }
    
    func getProfile() async -> Result<User, NetworkError> {
        getProfileCalled = true
        return getProfileResult
    }
}
