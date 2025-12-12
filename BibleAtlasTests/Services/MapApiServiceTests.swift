//
//  MapApiServiceTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/9/25.
//

import XCTest
import MapKit
@testable import BibleAtlas

final class MapApiServiceTests: XCTestCase {

    private var mockClient: MockAuthorizedApiClient!
    private var sut: MapApiService!
    private let baseURL = "https://example.com/api"

    override func setUp() {
        super.setUp()
        mockClient = MockAuthorizedApiClient()
        sut = MapApiService(apiClient: mockClient, url: baseURL)
    }

    override func tearDown() {
        sut = nil
        mockClient = nil
        super.tearDown()
    }

    /// 성공 케이스: 유효한 GeoJSON 이 들어오면 MKGeoJSONFeature 배열로 디코딩된다
    func test_getGeoJson_success_decodesFeatures() async {
        // given
        let placeId = "123"

        // 간단한 FeatureCollection GeoJSON
        let geoJson: [String: Any] = [
            "type": "FeatureCollection",
            "features": [
                [
                    "type": "Feature",
                    "geometry": [
                        "type": "Point",
                        "coordinates": [127.0, 37.0]
                    ],
                    "properties": [
                        "name": "test-point"
                    ]
                ]
            ]
        ]

        let data = try! JSONSerialization.data(withJSONObject: geoJson, options: [])

        mockClient.rawGetResult = .success(data)

        // when
        let result = await sut.getGeoJson(placeId: placeId)

        // then
        // URL이 제대로 들어갔는지
        XCTAssertEqual(
            mockClient.lastRequestURL,
            "\(baseURL)/place/\(placeId)/geojson"
        )

        switch result {
        case .success(let features):
            XCTAssertEqual(features.count, 1)

            let feature = features.first!
            // geometry/props 까지 대충 한 번 찍어보기
            XCTAssertFalse(feature.geometry.isEmpty)

        case .failure(let error):
            XCTFail("Expected success, got failure: \(error)")
        }
    }

    /// 디코딩 실패 시 .failToDecode 로 떨어지는지 확인
    func test_getGeoJson_decodingFailure_returnsFailToDecode() async {
        // given
        let placeId = "456"
        // GeoJSON 형식이 아닌 이상한 데이터
        let invalidData = Data("not-geojson".utf8)

        mockClient.rawGetResult = .success(invalidData)

        // when
        let result = await sut.getGeoJson(placeId: placeId)

        // then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .failToDecode:
            break // ✅ 기대한 에러 타입
        default:
            XCTFail("Expected .failToDecode, got \(error)")
        }
    }

    /// apiClient 가 실패를 리턴하면 그대로 NetworkError를 전달하는지 확인
    func test_getGeoJson_clientFailure_propagatesError() async {
        // given
        let placeId = "789"
        mockClient.rawGetResult = .failure(.serverError(500))

        // when
        let result = await sut.getGeoJson(placeId: placeId)

        // then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .serverError(let code):
            XCTAssertEqual(code, 500)
        default:
            XCTFail("Expected .serverError(500), got \(error)")
        }
    }
}
