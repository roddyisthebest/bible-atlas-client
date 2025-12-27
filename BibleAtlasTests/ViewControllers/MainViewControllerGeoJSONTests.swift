//
//  MainViewControllerGeoJSONTests.swift
//  BibleAtlasTests
//
//  Created by Tests.
//

import XCTest
@testable import BibleAtlas
import MapKit

final class MainViewControllerGeoJSONTests: XCTestCase {
    private var vm: MockMainViewModel!
    private var vc: MainViewController!

    override func setUp() {
        super.setUp()
        vm = MockMainViewModel()
        vc = MainViewController(vm: vm)
        _ = vc.view
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()
    }

    override func tearDown() {
        vc = nil
        vm = nil
        super.tearDown()
    }

    func test_geoJson_multiGeometries_addsMultiOverlays_andSetsVisibleRect() {
        vc.loadViewIfNeeded()

        // Spy map view to capture setVisibleMapRect
        let spy = SpyMapView2()
        spy.frame = vc._test_mapView.frame
        vc._test_replaceMapView(spy)

        let features = makeMultiGeoJsonFeaturesForTest()
        vm.emitGeoJSON(features)
        RunLoop.current.run(until: Date().addingTimeInterval(0.03))

        // Expect at least 2 overlays (one multipolyline + one multipolygon)
        XCTAssertGreaterThanOrEqual(vc._test_mapView.overlays.count, 2)
        // setVisibleMapRect should be called
        XCTAssertFalse(spy.setVisibleCalls.isEmpty)
        let call = spy.setVisibleCalls.last!
        XCTAssertTrue(call.animated)
        XCTAssertGreaterThan(call.padding.bottom, 0)
    }

    func test_geoJson_point_propertiesMapping_setsCustomAnnotationFields() {
        vc.loadViewIfNeeded()

        // Build a FeatureCollection with a Point that has properties id/possibility/isParent
        let point: [String: Any] = [
            "type": "Feature",
            "properties": ["id": "abc.def", "possibility": 70, "isParent": true],
            "geometry": [
                "type": "Point",
                "coordinates": [35.20, 31.76]
            ]
        ]
        let collection: [String: Any] = [
            "type": "FeatureCollection",
            "features": [point]
        ]

        let data = try! JSONSerialization.data(withJSONObject: collection)
        let features = try! MKGeoJSONDecoder().decode(data) as! [MKGeoJSONFeature]

        vm.emitGeoJSON(features)
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))

        // Find our CustomPointAnnotation and verify mapped properties
        let customAnns = vc._test_mapView.annotations.compactMap { $0 as? CustomPointAnnotation }
        XCTAssertEqual(customAnns.count, 1)
        let ann = customAnns[0]
        XCTAssertEqual(ann.placeId, "abc")
        XCTAssertEqual(ann.possibility, 70)
        XCTAssertEqual(ann.isParent, true)
    }

    func test_annotationView_isParent_setsLowPriority_andGlyphTextNil() {
        vc.loadViewIfNeeded()

        let ann = CustomPointAnnotation()
        ann.isParent = true
        ann.possibility = nil
        ann.placeId = "pid"
        ann.coordinate = CLLocationCoordinate2D(latitude: 31.70, longitude: 35.20)

        let view = vc.mapView(vc._test_mapView, viewFor: ann) as? MKMarkerAnnotationView
        XCTAssertNotNil(view)
        // isParent 분기에서는 보조 톤 + 시계 아이콘, displayPriority 낮음
        XCTAssertEqual(view?.displayPriority, .defaultLow)
        XCTAssertNil(view?.glyphText)
    }

    // MARK: - Helpers

    private func makeMultiGeoJsonFeaturesForTest() -> [MKGeoJSONFeature] {
        // MultiLineString
        let multiLine: [String: Any] = [
            "type": "Feature",
            "properties": ["id": "m1.line"],
            "geometry": [
                "type": "MultiLineString",
                "coordinates": [
                    [[35.10, 31.70], [35.20, 31.80]],
                    [[35.00, 31.60], [35.30, 31.90]]
                ]
            ]
        ]

        // MultiPolygon (two simple triangles)
        let multiPoly: [String: Any] = [
            "type": "Feature",
            "properties": ["id": "m2.poly"],
            "geometry": [
                "type": "MultiPolygon",
                "coordinates": [
                    [[[35.205, 31.765], [35.225, 31.765], [35.215, 31.780], [35.205, 31.765]]],
                    [[[35.10, 31.70], [35.12, 31.70], [35.11, 31.72], [35.10, 31.70]]]
                ]
            ]
        ]

        let collection: [String: Any] = [
            "type": "FeatureCollection",
            "features": [multiLine, multiPoly]
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: collection, options: [])
            let features = try MKGeoJSONDecoder().decode(data) as? [MKGeoJSONFeature]
            return features ?? []
        } catch {
            XCTFail("GeoJSON decode failed: \(error)")
            return []
        }
    }
}

// MARK: - SpyMapView2

final class SpyMapView2: MKMapView {
    struct SetVisibleCall { let rect: MKMapRect; let padding: UIEdgeInsets; let animated: Bool }
    private(set) var setVisibleCalls: [SetVisibleCall] = []

    override func setVisibleMapRect(_ mapRect: MKMapRect, edgePadding insets: UIEdgeInsets, animated: Bool) {
        setVisibleCalls.append(SetVisibleCall(rect: mapRect, padding: insets, animated: animated))
        super.setVisibleMapRect(mapRect, edgePadding: insets, animated: animated)
    }
}
