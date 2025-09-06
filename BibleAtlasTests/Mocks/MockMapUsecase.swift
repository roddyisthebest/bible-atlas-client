//
//  MockBottomSheetNavigator.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/5/25.
//

import Foundation
import MapKit
import XCTest

@testable import BibleAtlas



final class MockMapUsecase: MapUsecaseProtocol{
    
    
    var result: Result<[MKGeoJSONFeature],BibleAtlas.NetworkError>?
    var exp: XCTestExpectation?
    
    func getGeoJson(placeId: String) async -> Result<[MKGeoJSONFeature], BibleAtlas.NetworkError> {
        defer{
            exp?.fulfill()
        }
        return result ?? .failure(.clientError("not-implemented"))
    }
    
    
}
