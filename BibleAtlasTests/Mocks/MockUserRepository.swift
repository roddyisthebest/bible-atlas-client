//
//  MockUserRepository.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/10/25.
//

import Foundation
@testable import BibleAtlas

final class MockUserRepository: UserRepositoryProtocol {

    // MARK: - Tracking flags
    private(set) var isGetPlacesCalled = false
    private(set) var isGetProfileCalled = false
    private(set) var isGetMyCollectionPlaceIdsCalled = false

    // MARK: - Captured arguments
    private(set) var capturedLimit: Int?
    private(set) var capturedPage: Int?
    private(set) var capturedFilter: PlaceFilter?

    // MARK: - Results to return
    var getPlacesResult: Result<ListResponse<Place>, NetworkError>!
    var getProfileResult: Result<User, NetworkError>!
    var getMyCollectionPlaceIdsResult: Result<MyCollectionPlaceIds, NetworkError>!

    // MARK: - Protocol methods

    func getPlaces(limit: Int?, page: Int?, filter: PlaceFilter?) async -> Result<ListResponse<Place>, NetworkError> {
        isGetPlacesCalled = true

        capturedLimit = limit
        capturedPage = page
        capturedFilter = filter

        return getPlacesResult
    }

    func getProfile() async -> Result<User, NetworkError> {
        isGetProfileCalled = true
        return getProfileResult
    }

    func getMyCollectionPlaceIds() async -> Result<MyCollectionPlaceIds, NetworkError> {
        isGetMyCollectionPlaceIdsCalled = true
        return getMyCollectionPlaceIdsResult
    }
}
