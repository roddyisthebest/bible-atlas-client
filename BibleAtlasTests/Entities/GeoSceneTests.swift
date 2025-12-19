//
//  GeoSceneTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/20/25.
//

import XCTest
import CoreLocation
@testable import BibleAtlas

final class GeoSceneTests: XCTestCase {

    // MARK: - GeoShape: point

    func test_pointShape_storesIdAndCoordinate() {
        // given
        let coord = CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0)
        let shape = GeoShape.point(id: "p1", coord: coord)

        // when + then
        switch shape {
        case .point(let id, let storedCoord):
            XCTAssertEqual(id, "p1")
            XCTAssertEqual(storedCoord.latitude, coord.latitude, accuracy: 0.000001)
            XCTAssertEqual(storedCoord.longitude, coord.longitude, accuracy: 0.000001)
        default:
            XCTFail("Expected .point, but got different case")
        }
    }

    // MARK: - GeoShape: polyline

    func test_polylineShape_storesIdAndCoordinates() {
        // given
        let coords = [
            CLLocationCoordinate2D(latitude: 10.0, longitude: 20.0),
            CLLocationCoordinate2D(latitude: 11.0, longitude: 21.0),
            CLLocationCoordinate2D(latitude: 12.0, longitude: 22.0)
        ]
        let shape = GeoShape.polyline(id: "line-1", coords: coords)

        // when + then
        switch shape {
        case .polyline(let id, let storedCoords):
            XCTAssertEqual(id, "line-1")
            XCTAssertEqual(storedCoords.count, coords.count)

            zip(storedCoords, coords).forEach { stored, expected in
                XCTAssertEqual(stored.latitude, expected.latitude, accuracy: 0.000001)
                XCTAssertEqual(stored.longitude, expected.longitude, accuracy: 0.000001)
            }
        default:
            XCTFail("Expected .polyline, but got different case")
        }
    }

    // MARK: - GeoShape: polygon

    func test_polygonShape_storesIdAndRings() {
        // given
        let outerRing = [
            CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
            CLLocationCoordinate2D(latitude: 0.0, longitude: 1.0),
            CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0),
            CLLocationCoordinate2D(latitude: 1.0, longitude: 0.0)
        ]

        let innerRing = [
            CLLocationCoordinate2D(latitude: 0.2, longitude: 0.2),
            CLLocationCoordinate2D(latitude: 0.2, longitude: 0.8),
            CLLocationCoordinate2D(latitude: 0.8, longitude: 0.8),
            CLLocationCoordinate2D(latitude: 0.8, longitude: 0.2)
        ]

        let rings = [outerRing, innerRing]

        let shape = GeoShape.polygon(id: "poly-1", rings: rings)

        // when + then
        switch shape {
        case .polygon(let id, let storedRings):
            XCTAssertEqual(id, "poly-1")
            XCTAssertEqual(storedRings.count, rings.count)

            for (storedRing, expectedRing) in zip(storedRings, rings) {
                XCTAssertEqual(storedRing.count, expectedRing.count)
                for (storedCoord, expectedCoord) in zip(storedRing, expectedRing) {
                    XCTAssertEqual(storedCoord.latitude, expectedCoord.latitude, accuracy: 0.000001)
                    XCTAssertEqual(storedCoord.longitude, expectedCoord.longitude, accuracy: 0.000001)
                }
            }
        default:
            XCTFail("Expected .polygon, but got different case")
        }
    }

    // MARK: - GeoScene

    func test_geoScene_storesShapesInOrder() {
        // given
        let p = GeoShape.point(
            id: "p1",
            coord: CLLocationCoordinate2D(latitude: 1.0, longitude: 2.0)
        )
        let line = GeoShape.polyline(
            id: "l1",
            coords: [
                CLLocationCoordinate2D(latitude: 3.0, longitude: 4.0)
            ]
        )
        let poly = GeoShape.polygon(
            id: "poly1",
            rings: [[CLLocationCoordinate2D(latitude: 5.0, longitude: 6.0)]]
        )

        let scene = GeoScene(shapes: [p, line, poly])

        // when
        let shapes = scene.shapes

        // then
        XCTAssertEqual(shapes.count, 3)

        // 첫 번째는 point
        switch shapes[0] {
        case .point(let id, _):
            XCTAssertEqual(id, "p1")
        default:
            XCTFail("Expected first shape to be .point")
        }

        // 두 번째는 polyline
        switch shapes[1] {
        case .polyline(let id, _):
            XCTAssertEqual(id, "l1")
        default:
            XCTFail("Expected second shape to be .polyline")
        }

        // 세 번째는 polygon
        switch shapes[2] {
        case .polygon(let id, _):
            XCTAssertEqual(id, "poly1")
        default:
            XCTFail("Expected third shape to be .polygon")
        }
    }
}
