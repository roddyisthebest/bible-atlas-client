//
//  MainViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/5/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas
import MapKit

final class MainViewModelTests: XCTestCase {
    
    var notificationService:MockNotificationService!
    var navigator: MockBottomSheetNavigator!
    var placeUsecase:MockPlaceusecase!
    var mapUsecase:MockMapUsecase!
    
    var schedular: TestScheduler!
    var disposeBag: DisposeBag!
    
    override func setUp(){
        super.setUp()

        self.mapUsecase = MockMapUsecase()
        self.placeUsecase = MockPlaceusecase();
        self.schedular = TestScheduler(initialClock: 0);
        self.disposeBag = DisposeBag();
        self.notificationService = MockNotificationService()
        self.navigator = MockBottomSheetNavigator()
    }
    
    func test_viewLoaded_success_shouldToggleLoading_andUpdatePlaces() throws {
        
        let exp = expectation(description: "places set");
        placeUsecase.placesWithRepresentativePointExp = exp
        let places = [
            Place(id: "1", name: "wo", koreanName: "테스트", isModern: true, description: "desc", koreanDescription: "koreanDesc", stereo: .child, likeCount: 1, types: [])]
        placeUsecase.placesWithRepresentativePointResult = .success(ListResponse(total: 1, page: 0, limit: 10, data: places))
        
        let vm = MainViewModel(bottomSheetCoordinator: navigator, mapUseCase: mapUsecase, placeUsecase: placeUsecase, notificationService: notificationService)
        
        let viewLoaded$ = PublishRelay<Void>();
        
        let output = vm.transform(input: MainViewModel.Input(viewLoaded$:viewLoaded$.asObservable(), placeAnnotationTapped$: .empty()))
        
        var histories:[Bool] = []
        
        let loadingExp = expectation(description: "loading toggle");
        loadingExp.expectedFulfillmentCount = 2;
        output.isLoading$.skip(1).take(2).subscribe(onNext:{
            isLoading in
            histories.append(isLoading)
            loadingExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        viewLoaded$.accept(())
        
        wait(for:[exp, loadingExp])
        
        
        let settledPlaces = try output.placesWithRepresentativePoint$.toBlocking(timeout: 1).first()
        
        
        XCTAssertEqual(settledPlaces?.count, 1)
        XCTAssertEqual(histories, [true, false])
        
        
    }
    
    
    func test_fetchGeoJsonRequired_success_shouldSetSelectedId_resetError_toggleLoading_andEmitGeoJson() throws{
        
        let exp = expectation(description: "geojson set")
        let geoJSONFeatures:[MKGeoJSONFeature] = [
        MKGeoJSONFeature()]
        let result:Result<[MKGeoJSONFeature],BibleAtlas.NetworkError> = .success(geoJSONFeatures)

        mapUsecase.exp = exp;
        mapUsecase.result = result
        
        let vm = MainViewModel(bottomSheetCoordinator: navigator, mapUseCase: mapUsecase, placeUsecase: placeUsecase, notificationService: notificationService)
        
        
        let output = vm.transform(input: MainViewModel.Input(viewLoaded$: .empty(), placeAnnotationTapped$: .empty()))

    
        notificationService.post(.fetchGeoJsonRequired, object:"test-placeId")
        
        wait(for:[exp])
        
        let settledPlaceId = try output.selectedPlaceId$.toBlocking(timeout: 1).first();
        
        let settledGeoJsonRender = try output.geoJsonRender$.toBlocking(timeout: 1).first();
        
        
        XCTAssertEqual(settledPlaceId, "test-placeId")
        XCTAssertEqual(settledGeoJsonRender?.count, 1)
    }

    
    func test_fetchGeoJsonRequired_failure_shouldToggleLoading_emitError_andNotEmitGeoJson()
    {
        let exp = expectation(description: "geojson set")

        mapUsecase.exp = exp;
        mapUsecase.result = .failure(.clientError("test-error"))
        
        let vm = MainViewModel(bottomSheetCoordinator: navigator, mapUseCase: mapUsecase, placeUsecase: placeUsecase, notificationService: notificationService)
        
        
        let output = vm.transform(input: MainViewModel.Input(viewLoaded$: .empty(), placeAnnotationTapped$: .empty()))

        var gotLoadingHistories:[Bool] = []

        let loadingExp = expectation(description: "loading toggle")
        loadingExp.expectedFulfillmentCount = 2
        
        
        let geoNotEmitted = expectation(description: "geojson should NOT emit")
        geoNotEmitted.isInverted = true
        output.geoJsonRender$
            .subscribe(onNext: { _ in geoNotEmitted.fulfill() })
            .disposed(by: disposeBag)
        
        
        output.isLoading$.skip(1).subscribe(onNext:{ isLoading in
            gotLoadingHistories.append(isLoading)
            loadingExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        notificationService.post(.fetchGeoJsonRequired, object:"test-placeId")
        

        
        var gotError:NetworkError?;
        let errorExp = expectation(description: "error set")
        output.error$.compactMap{$0}.subscribe(onNext:{ error in
            gotError = error
            errorExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        
        
        wait(for:[exp, errorExp, loadingExp, geoNotEmitted], timeout: 2.0)

        
        
        
        XCTAssertEqual(gotError, .clientError("test-error"))
        XCTAssertEqual(gotLoadingHistories, [true,false])

    }
    
    func test_placeAnnotationTap_withDifferentId_shouldPresentPlaceDetail()
    {
        
        let vm = MainViewModel(bottomSheetCoordinator: navigator, mapUseCase: mapUsecase, placeUsecase: placeUsecase, notificationService: notificationService)
        
        let placeAnnotationTapped$ = PublishRelay<String>();
        let _ = vm.transform(input: MainViewModel.Input(viewLoaded$: .empty(), placeAnnotationTapped$: placeAnnotationTapped$.asObservable()))
        
        let placeId = "test-placeId"
        let anotherPlaceId = "test-placeId2"

        notificationService.post(.fetchGeoJsonRequired, object: placeId)
        
        placeAnnotationTapped$.accept(anotherPlaceId)
        
        XCTAssertEqual(navigator.presentedSheet, .placeDetail(anotherPlaceId))
  
    }
    
    func test_placeAnnotationTap_withSameId_shouldNotPresent(){
        let vm = MainViewModel(bottomSheetCoordinator: navigator, mapUseCase: mapUsecase, placeUsecase: placeUsecase, notificationService: notificationService)
        
        let placeAnnotationTapped$ = PublishRelay<String>();
        let _ = vm.transform(input: MainViewModel.Input(viewLoaded$: .empty(), placeAnnotationTapped$: placeAnnotationTapped$.asObservable()))
        
        let placeId = "test-placeId"

        
        notificationService.post(.fetchGeoJsonRequired, object: placeId)
        
        placeAnnotationTapped$.accept(placeId)
        
        XCTAssertNil(navigator.presentedSheet)
        
        
        
    }

    
}
