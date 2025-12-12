//
//  MockMapApiService.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

@testable import BibleAtlas
import MapKit

// MARK: - MockMapApiService

final class MockMapApiService: MapApiServiceProtocol {

    var calledPlaceId: String?
    var resultToReturn: Result<[MKGeoJSONFeature], NetworkError> = .failure(.clientError("default"))

    func getGeoJson(placeId: String) async -> Result<[MKGeoJSONFeature], NetworkError> {
        calledPlaceId = placeId
        return resultToReturn
    }
}
