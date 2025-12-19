//
//  MKMapRectExtensionTests.swift
//  BibleAtlasTests
//

import XCTest
import MapKit
@testable import BibleAtlas

final class MKMapRectExtensionTests: XCTestCase {
    
    func test_initForRegion_createsRectThatCoversRegion() {
        // given
        let center = CLLocationCoordinate2D(latitude: 37.0, longitude: 127.0)
        let span = MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 20.0)
        let region = MKCoordinateRegion(center: center, span: span)
        
        // when
        let rect = MKMapRect(for: region)
        
        // then: width / height 는 양수
        XCTAssertGreaterThan(rect.size.width, 0)
        XCTAssertGreaterThan(rect.size.height, 0)
        
        // region top-left, bottom-right
        let expectedTopLeft = CLLocationCoordinate2D(
            latitude: region.center.latitude + (region.span.latitudeDelta / 2),
            longitude: region.center.longitude - (region.span.longitudeDelta / 2)
        )
        let expectedBottomRight = CLLocationCoordinate2D(
            latitude: region.center.latitude - (region.span.latitudeDelta / 2),
            longitude: region.center.longitude + (region.span.longitudeDelta / 2)
        )
        
        let topLeftPoint = MKMapPoint(expectedTopLeft)
        let bottomRightPoint = MKMapPoint(expectedBottomRight)
        
        // rect가 양 끝 지점을 포함하는지
        XCTAssertTrue(rect.contains(topLeftPoint))
        XCTAssertTrue(rect.contains(bottomRightPoint))
        
    }

    
    
    func test_scaled_aroundCenterBy2_expandsRectCorrectly() {
        // given
        let original = MKMapRect(x: 0, y: 0, width: 10, height: 10)
        let anchor = MKMapPoint(x: 5, y: 5) // 중심
        let scale = 2.0
        
        // when
        let scaledRect = original.scaled(around: anchor, by: scale)
        
        // then
        XCTAssertEqual(scaledRect.origin.x, -5, accuracy: 1e-9)
        XCTAssertEqual(scaledRect.origin.y, -5, accuracy: 1e-9)
        XCTAssertEqual(scaledRect.size.width, 20, accuracy: 1e-9)
        XCTAssertEqual(scaledRect.size.height, 20, accuracy: 1e-9)
    }

    func test_scaled_aroundCenterByHalf_shrinksRectCorrectly() {
        // given
        let original = MKMapRect(x: 0, y: 0, width: 10, height: 10)
        let anchor = MKMapPoint(x: 5, y: 5)
        let scale = 0.5
        
        // when
        let scaledRect = original.scaled(around: anchor, by: scale)
        
        // then
        // dx = -5 → newOrigin.x = 5 + (-5 * 0.5) = 2.5
        XCTAssertEqual(scaledRect.origin.x, 2.5, accuracy: 1e-9)
        XCTAssertEqual(scaledRect.origin.y, 2.5, accuracy: 1e-9)
        XCTAssertEqual(scaledRect.size.width, 5, accuracy: 1e-9)
        XCTAssertEqual(scaledRect.size.height, 5, accuracy: 1e-9)
    }


    
    
}
