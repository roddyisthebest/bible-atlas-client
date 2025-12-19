//
//  MapUsecaseTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
import MapKit
@testable import BibleAtlas

final class MapUsecaseTests: XCTestCase {

    private var sut: MapUsecase!
    private var mockRepository: MockMapRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockMapRepository()
        sut = MapUsecase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func test_getGeoJson_delegatesToRepository_and_returnsResult() async {
        // given
        let expectedPlaceId = "test-place-id"
        mockRepository.resultToReturn = .success([])

        // when
        let result = await sut.getGeoJson(placeId: expectedPlaceId)

        // then
        XCTAssertEqual(mockRepository.calledPlaceId, expectedPlaceId)

        switch result {
        case .success(let features):
            XCTAssertEqual(features.count, 0)
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func test_getGeoJson_propagatesFailure_fromRepository() async {
        // given
        let expectedPlaceId = "test-place-id"
        mockRepository.resultToReturn = .failure(.clientError("repo-error"))

        // when
        let result = await sut.getGeoJson(placeId: expectedPlaceId)

        // then
        XCTAssertEqual(mockRepository.calledPlaceId, expectedPlaceId)

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .clientError("repo-error"))
        }
    }
}



