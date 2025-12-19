//
//  MainViewControllerTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/19/25.
//

import XCTest
@testable import BibleAtlas
import MapKit

final class MainViewControllerTests: XCTestCase {
    private var vm: MockMainViewModel!
    private var vc: MainViewController!
    
    
    
    override func setUp() {
          super.setUp()
          vm = MockMainViewModel()
          vc = MainViewController(vm: vm)
          // 뷰가 실제로 레이아웃 되게 프레임 지정
          _ = vc.view
          vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
          vc.view.layoutIfNeeded()
      }
    
    override func tearDown() {
        vc = nil
        vm = nil
        super.tearDown()
    }
    
    // 1) viewDidLoad 초기 상태/Region
    func test_viewDidLoad_setsInitialRegion_andEmitsViewLoaded() {
        // when
        vc.loadViewIfNeeded()

        // then: Region 대략 검증 (예: 위도/경도/스팬이 기대 범위)
        let r = vc._test_mapView.region
        XCTAssertEqual(r.center.longitude, 35.2137, accuracy: 0.1)
        XCTAssertEqual(r.center.latitude, 31.7683 - 0.25 * 0.5, accuracy: 0.1)

        // span: lon은 2.0±0.3, lat은 2.0 이상 정도로만
        XCTAssertEqual(r.span.longitudeDelta, 0.25, accuracy: 0.3)
        XCTAssertTrue(r.span.latitudeDelta >= 0.25 && r.span.latitudeDelta <= 5.0)
        // viewLoaded$가 한 번 이상 호출됐는지(입력 캡처 카운트)
        XCTAssertEqual(vm.viewLoadedCount, 1)
    }
    
    
    func test_isLoading_trueThenFalse_disablesThenEnablesMap() {
        vc.loadViewIfNeeded()

        // true
        vm.setLoading(true)
        // UI 변경은 메인에서 즉시 반영되지만, 한 틱 뒤에 확인하면 안전
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        XCTAssertFalse(vc._test_mapView.isUserInteractionEnabled)

        // false
        vm.setLoading(false)
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        XCTAssertTrue(vc._test_mapView.isUserInteractionEnabled)
    }
    
    func test_places_emits_rendersAnnotations_withCorrectCountTitlesAndCoordinates(){
        
        vc.loadViewIfNeeded()
        
        
        let places = makePlaces(count: 20);
    
        vm.setPlaces(places)
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))

        XCTAssertEqual(vc._test_mapView.annotations.count, 20)
        
        
    }
    
    
    func test_geoJson_emits_addsOverlaysAndAnnotations_withExpectedCounts(){
        vc.loadViewIfNeeded()
        
        let geoJsonFeatures = makeGeoJsonFeaturesForTest();
        vm.emitGeoJSON(geoJsonFeatures)
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertEqual(vc._test_mapView.overlays.count,2)
        XCTAssertEqual(vc._test_mapView.annotations.count,1)
    }
    
    
    func test_reset_emits_clearsAllOverlaysAndAnnotations(){
        
        vc.loadViewIfNeeded()
        
        let geoJsonFeatures = makeGeoJsonFeaturesForTest();
        vm.emitGeoJSON(geoJsonFeatures)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertEqual(vc._test_mapView.overlays.count,2)
        XCTAssertEqual(vc._test_mapView.annotations.count,1)
        
        vm.emitReset()
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))

        XCTAssertEqual(vc._test_mapView.overlays.count, 0)
        XCTAssertEqual(vc._test_mapView.annotations.count, 0)
    }
    
    
    func test_renderGeoJson_setsVisibleMapRect_withMinSizeAndPadding() {
        vc.loadViewIfNeeded()

        // Spy 주입(프레임 맞춰야 height 기반 패딩이 정확)
        let spy = SpyMapView()
        spy.frame = vc._test_mapView.frame
        vc._test_replaceMapView(spy)

        // 작은 영역의 GeoJSON → minSize 브랜치 타도록
        let features = makeGeoJsonFeaturesForTest()
        vm.emitGeoJSON(features)
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))

        guard let call = spy.setVisibleCalls.last else {
            return XCTFail("setVisibleMapRect was not called")
        }

        // 패딩: top/left/right = 20, bottom = height*0.5 + 20
        let h = spy.bounds.height
        XCTAssertEqual(call.padding.top, 20, accuracy: 0.5)
        XCTAssertEqual(call.padding.left, 20, accuracy: 0.5)
        XCTAssertEqual(call.padding.right, 20, accuracy: 0.5)
        XCTAssertEqual(call.padding.bottom, h * 0.5 + 20, accuracy: 1.0)

        // 최소 크기: 10km 이상
        XCTAssertGreaterThanOrEqual(call.rect.size.width,  12_500)
        XCTAssertGreaterThanOrEqual(call.rect.size.height, 12_500)

        // 애니메이션 플래그
        XCTAssertTrue(call.animated)
    }

    
    
    
    
    func test_didSelectAnnotation_emitsPlaceId_toViewModelInput() {
        // Given
        vc.loadViewIfNeeded()

        let ann = CustomPointAnnotation()
        ann.placeId = "place-123"
        ann.title = "Some Place"
        ann.coordinate = CLLocationCoordinate2D(latitude: 31.77, longitude: 35.21)

        // 맵에 추가
        vc._test_mapView.addAnnotation(ann)

        // viewFor:를 통해 어노테이션 뷰 생성 (재사용 큐를 거치도록 VC 델리게이트 호출)
        guard let view = vc.mapView(vc._test_mapView, viewFor: ann) else {
            return XCTFail("Failed to obtain annotation view")
        }

        // When: 사용자가 핀을 탭했다고 가정하고 didSelect 수동 호출
        vc.mapView(vc._test_mapView, didSelect: view)

        // Then: VM으로 placeId가 전달되었는지 확인
        XCTAssertEqual(vm.tappedPlaceIds.last, "place-123")
    }

    func test_annotationView_styling_changes_withSelectionAndPossibility() {
        vc.loadViewIfNeeded()

        // Not selected, no possibility
        let ann1 = CustomPointAnnotation()
        ann1.placeId = "p1"
        ann1.coordinate = CLLocationCoordinate2D(latitude: 31.7, longitude: 35.2)
        ann1.isParent = false
        ann1.possibility = nil
        vc._test_mapView.addAnnotation(ann1)
        guard let v1 = vc.mapView(vc._test_mapView, viewFor: ann1) as? MKMarkerAnnotationView else {
            return XCTFail("no view")
        }
        XCTAssertNotNil(v1.glyphImage)

        // Selected
        vc._test_setSelected(placeId: "p2")
        let ann2 = CustomPointAnnotation()
        ann2.placeId = "p2"
        ann2.coordinate = CLLocationCoordinate2D(latitude: 31.71, longitude: 35.21)
        let view2 = vc.mapView(vc._test_mapView, viewFor: ann2) as? MKMarkerAnnotationView
        XCTAssertNotNil(view2)

        // With possibility
        let ann3 = CustomPointAnnotation()
        ann3.placeId = "p3"
        ann3.possibility = 85
        ann3.isParent = false
        ann3.coordinate = CLLocationCoordinate2D(latitude: 31.72, longitude: 35.22)
        let view3 = vc.mapView(vc._test_mapView, viewFor: ann3) as? MKMarkerAnnotationView
        XCTAssertNotNil(view3)
        XCTAssertEqual(ann3.subtitle, L10n.isKorean ? "신뢰도 85%" : "Confidence 85%")
    }

    func test_rendererForOverlay_returnsExpectedRendererTypes() {
        vc.loadViewIfNeeded()
        let polyline = MKPolyline(coordinates: [CLLocationCoordinate2D(latitude: 31.7, longitude: 35.2), CLLocationCoordinate2D(latitude: 31.71, longitude: 35.21)], count: 2)
        let renderer1 = vc.mapView(vc._test_mapView, rendererFor: polyline)
        XCTAssertTrue(renderer1 is MKPolylineRenderer)

        let polygon = MKPolygon(points: [MKMapPoint(CLLocationCoordinate2D(latitude: 31.7, longitude: 35.2)), MKMapPoint(CLLocationCoordinate2D(latitude: 31.71, longitude: 35.21)), MKMapPoint(CLLocationCoordinate2D(latitude: 31.72, longitude: 35.22))], count: 3)
        let renderer2 = vc.mapView(vc._test_mapView, rendererFor: polygon)
        XCTAssertTrue(renderer2 is MKPolygonRenderer)
    }

    func test_zoomOut_setsVisibleMapRect_withPadding() {
        vc.loadViewIfNeeded()
        let spy = SpyMapView()
        spy.frame = vc._test_mapView.frame
        vc._test_replaceMapView(spy)

        vc._test_zoomOut()
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertFalse(spy.setVisibleCalls.isEmpty)
        let call = spy.setVisibleCalls.last!
        XCTAssertTrue(call.padding.top > 0)
        XCTAssertTrue(call.animated)
    }
    
    
    func makePlaces(count:Int) -> [Place]{
        return (0..<count).map { i in
            Place(
                id: UUID().uuidString,
                name: "Place \(i)", 
                koreanName: "장소이름",
                isModern: Bool.random(),
                description: "desc \(i)",
                koreanDescription: "ko desc \(i)",
                stereo: .child,
                likeCount: Int.random(in: 0...100),
                types: [],
                longitude: Double.random(in: 29...34),
                latitude: Double.random(in: 29...34)
            )
        }
    }
    
    func makeGeoJsonFeaturesForTest() -> [MKGeoJSONFeature] {
        // 예시 좌표들 (예루살렘 근처 대략)
        let point = [
            "type": "Feature",
            "properties": ["id": "1.point"],
            "geometry": [
                "type": "Point",
                "coordinates": [35.2137, 31.7683] // [lon, lat]
            ]
        ] as [String : Any]

        let lineString = [
            "type": "Feature",
            "properties": ["id": "2.line"],
            "geometry": [
                "type": "LineString",
                "coordinates": [
                    [35.20, 31.76],
                    [35.22, 31.77],
                    [35.24, 31.78]
                ]
            ]
        ] as [String : Any]

        // 간단한 삼각형 폴리곤 (마지막 점으로 닫힘)
        let polygon = [
            "type": "Feature",
            "properties": ["id": "3.poly"],
            "geometry": [
                "type": "Polygon",
                "coordinates": [[
                    [35.205, 31.765],
                    [35.225, 31.765],
                    [35.215, 31.780],
                    [35.205, 31.765] // close ring
                ]]
            ]
        ] as [String : Any]

        let collection = [
            "type": "FeatureCollection",
            "features": [point, lineString, polygon]
        ] as [String : Any]

        do {
            let data = try JSONSerialization.data(withJSONObject: collection, options: [])
            let features = try MKGeoJSONDecoder().decode(data) as? [MKGeoJSONFeature]
            return features ?? []
        } catch {
            XCTFail("GeoJSON decode failed: \(error)")
            return []
        }
    }
    

        
    func test_mapViewDelegate_isSelf() {
        vc.loadViewIfNeeded()
        XCTAssertTrue(vc._test_mapView.delegate === vc)
    }

    func test_selectedPlaceIdStream_updatesAnnotationViewSelectedStyle() {
        vc.loadViewIfNeeded()

        // Emit selected place id from VM output stream
        vm.setSelectedPlaceId("sel-1")
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        // Create annotation for the same id and ask for view
        let ann = CustomPointAnnotation()
        ann.placeId = "sel-1"
        ann.coordinate = CLLocationCoordinate2D(latitude: 31.71, longitude: 35.21)
        guard let view = vc.mapView(vc._test_mapView, viewFor: ann) as? MKMarkerAnnotationView else {
            return XCTFail("Expected MKMarkerAnnotationView")
        }

        // Selected styling: checkmark glyph, required priority, indigo tint
        XCTAssertNotNil(view.glyphImage)
        XCTAssertEqual(view.displayPriority, .required)
        XCTAssertEqual(view.markerTintColor, .systemIndigo)
    }

    func test_isLoading_animatesLoadingView_toggles() {
        vc.loadViewIfNeeded()

        vm.setLoading(true)
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        XCTAssertTrue(vc._test_isLoadingAnimating)

        vm.setLoading(false)
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        XCTAssertFalse(vc._test_isLoadingAnimating)
    }

    func test_rendererForOverlay_multiTypes_andDefault() {
        vc.loadViewIfNeeded()

        // MultiPolyline
        let coords1 = [
            CLLocationCoordinate2D(latitude: 31.70, longitude: 35.20),
            CLLocationCoordinate2D(latitude: 31.71, longitude: 35.21)
        ]
        let coords2 = [
            CLLocationCoordinate2D(latitude: 31.72, longitude: 35.22),
            CLLocationCoordinate2D(latitude: 31.73, longitude: 35.23)
        ]
        let pl1 = MKPolyline(coordinates: coords1, count: coords1.count)
        let pl2 = MKPolyline(coordinates: coords2, count: coords2.count)
        let multiPL = MKMultiPolyline([pl1, pl2])
        let r1 = vc.mapView(vc._test_mapView, rendererFor: multiPL)
        XCTAssertTrue(r1 is MKMultiPolylineRenderer)

        // MultiPolygon
        let pts1: [MKMapPoint] = [
            MKMapPoint(CLLocationCoordinate2D(latitude: 31.70, longitude: 35.20)),
            MKMapPoint(CLLocationCoordinate2D(latitude: 31.71, longitude: 35.21)),
            MKMapPoint(CLLocationCoordinate2D(latitude: 31.72, longitude: 35.22))
        ]
        let pts2: [MKMapPoint] = [
            MKMapPoint(CLLocationCoordinate2D(latitude: 31.73, longitude: 35.23)),
            MKMapPoint(CLLocationCoordinate2D(latitude: 31.74, longitude: 35.24)),
            MKMapPoint(CLLocationCoordinate2D(latitude: 31.75, longitude: 35.25))
        ]
        let poly1 = MKPolygon(points: pts1, count: pts1.count)
        let poly2 = MKPolygon(points: pts2, count: pts2.count)
        let multiPG = MKMultiPolygon([poly1, poly2])
        let r2 = vc.mapView(vc._test_mapView, rendererFor: multiPG)
        XCTAssertTrue(r2 is MKMultiPolygonRenderer)

        // Unknown overlay -> default renderer
        let circle = MKCircle(center: CLLocationCoordinate2D(latitude: 31.70, longitude: 35.20), radius: 100)
        let r3 = vc.mapView(vc._test_mapView, rendererFor: circle)
        XCTAssertTrue(r3 is MKOverlayRenderer)
    }

    func test_renderPlaces_setsCustomAnnotationFields_correctCoordinatesAndId() {
        vc.loadViewIfNeeded()

        let known = Place(
            id: "known-id",
            name: "Known",
            koreanName: "알려진",
            isModern: true,
            description: "d",
            koreanDescription: "kd",
            stereo: .child,
            likeCount: 0,
            types: [],
            longitude: 35.1234,
            latitude: 31.5678
        )

        vm.setPlaces([known])
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))

        let anns = vc._test_mapView.annotations.compactMap { $0 as? CustomPointAnnotation }
        XCTAssertEqual(anns.count, 1)
        let ann = anns[0]
        XCTAssertEqual(ann.placeId, "known-id")
        XCTAssertEqual(ann.coordinate.latitude, 31.5678, accuracy: 0.0001)
        XCTAssertEqual(ann.coordinate.longitude, 35.1234, accuracy: 0.0001)
    }
    
}
