//
//  MapRepositoryTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
import MapKit
@testable import BibleAtlas

final class MapRepositoryTests: XCTestCase {

    private var sut: MapRepository!
    private var mockApiService: MockMapApiService!

    override func setUp() {
        super.setUp()
        mockApiService = MockMapApiService()
        sut = MapRepository(mapApiService: mockApiService)
    }

    override func tearDown() {
        sut = nil
        mockApiService = nil
        super.tearDown()
    }

    func test_getGeoJson_delegatesToApiService_and_returnsResult() async {
        // given
        let expectedPlaceId = "test-place-id"
        mockApiService.resultToReturn = .success([])

        // when
        let result = await sut.getGeoJson(placeId: expectedPlaceId)

        // then
        XCTAssertEqual(mockApiService.calledPlaceId, expectedPlaceId)

        switch result {
        case .success(let features):
            XCTAssertEqual(features.count, 0)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func test_getGeoJson_propagatesFailure() async {
        // given
        let expectedPlaceId = "test-place-id"
        mockApiService.resultToReturn = .failure(.clientError("test-error"))

        // when
        let result = await sut.getGeoJson(placeId: expectedPlaceId)

        // then
        XCTAssertEqual(mockApiService.calledPlaceId, expectedPlaceId)

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .clientError("test-error"))
        }
    }
}



