//
//  ReportBottomSheetViewModelTests.swift
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

final class PlaceReportBottomSheetViewModelTests: XCTestCase {

    var navigator: MockBottomSheetNavigator!
    var placeUsecase: MockPlaceusecase!
    var schedular: TestScheduler!
    var disposeBag: DisposeBag!
    
    var reportType = PlaceReportType.etc
    var placeId = "test"
    
    override func setUp(){
        super.setUp()
        
        self.navigator = MockBottomSheetNavigator();
        self.placeUsecase = MockPlaceusecase();
        self.schedular = TestScheduler(initialClock: 0);
        self.disposeBag = DisposeBag();
    }

    func test_cancelButtonTap_shouldDismissNavigator(){
        let vm = PlaceReportBottomSheetViewModel(navigator: navigator, reportType: reportType, placeUsecase: placeUsecase, placeId: placeId);
        
        let cancelButtonTapped$ = PublishRelay<Void>();
        let _ = vm.transform(input: PlaceReportBottomSheetViewModel.Input(cancelButttonTapped$: cancelButtonTapped$.asObservable(), placeTypeCellTapped$: .empty(), confirmButtonTapped$: .empty()))
        
        cancelButtonTapped$.accept(())
        
        XCTAssertTrue(navigator.isDismissed)
        
    }
    
    func test_placeTypeCellTap_shouldUpdateReportType() throws{
        
        let reportType = PlaceReportType.etc
        let placeId = "test"
        
        let vm = PlaceReportBottomSheetViewModel(navigator: navigator, reportType: reportType, placeUsecase: placeUsecase, placeId: placeId);
        
        let placeTypeCellTapped$ = PublishRelay<PlaceReportType>();
        
        
        let output = vm.transform(input: PlaceReportBottomSheetViewModel.Input(cancelButttonTapped$: .empty(), placeTypeCellTapped$: placeTypeCellTapped$.asObservable(), confirmButtonTapped$: .empty()))
        
        placeTypeCellTapped$.accept(.inappropriate)
        
        let changedType = try output.reportType$.toBlocking(timeout: 1).first()!
        
        XCTAssertEqual(changedType, .inappropriate)
        
        
    }

    
    func test_confirmTap_withoutPlaceId_shouldEmitClientError_placeId() throws{
        let vm = PlaceReportBottomSheetViewModel(navigator: navigator, reportType: .etc, placeUsecase: placeUsecase, placeId: nil)
        
        let confirmButtonTapped$ = PublishRelay<String>();
        
        
        let output = vm.transform(input: PlaceReportBottomSheetViewModel.Input(cancelButttonTapped$: .empty(), placeTypeCellTapped$: .empty(), confirmButtonTapped$: confirmButtonTapped$.asObservable()))
        
        
        confirmButtonTapped$.accept("pov:test")
        
        
        let clientError = try output.clientError$.toBlocking(timeout: 1).first()!
            
        XCTAssertEqual(clientError, PlaceReportClientError.placeId)
        
    }

    func test_confirmTap_withoutReportType_shouldEmitClientError_placeType() throws{
        let vm = PlaceReportBottomSheetViewModel(navigator: navigator, reportType: nil, placeUsecase: placeUsecase, placeId: placeId)
        
        let confirmButtonTapped$ = PublishRelay<String>();
        
        
        let output = vm.transform(input: PlaceReportBottomSheetViewModel.Input(cancelButttonTapped$: .empty(), placeTypeCellTapped$: .empty(), confirmButtonTapped$: confirmButtonTapped$.asObservable()))
        
        
        confirmButtonTapped$.accept("pov:test")
        
        
        let clientError = try output.clientError$.toBlocking(timeout: 1).first()!
            
        XCTAssertEqual(clientError, PlaceReportClientError.placeType)
        
    }
    
    
    func test_confirmTap_success_shouldToggleLoading_andEmitSuccess() throws{
    
        let exp = expectation(description: "waiting api request")
        placeUsecase.createReportExp = exp;
        placeUsecase.createReportResultToReturn = .success(1233)

        let vm = PlaceReportBottomSheetViewModel(navigator: navigator, reportType: .etc, placeUsecase: placeUsecase, placeId: placeId)
        
        let confirmButtonTapped$ = PublishRelay<String>();
        
        
        let output = vm.transform(input: PlaceReportBottomSheetViewModel.Input(cancelButttonTapped$: .empty(), placeTypeCellTapped$: .empty(), confirmButtonTapped$: confirmButtonTapped$.asObservable()))
        
        var histories:[Bool] = []
        
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2;
        output.isLoading$.skip(1).take(2).subscribe(onNext:{
            isLoading in
            histories.append(isLoading)
            loadingExp.fulfill()
            
        }).disposed(by: disposeBag)
        
        
        confirmButtonTapped$.accept("pov:test")
            
        wait(for:[exp,loadingExp], timeout: 1)
        XCTAssertEqual(histories, [true, false])
        
        let isSuccess = try output.isSuccess$.toBlocking().first()!
        XCTAssertEqual(isSuccess, true)
        
    }
    
    func test_confirmTap_failure_shouldToggleLoading_andEmitNetworkError() throws{
        
        let exp = expectation(description: "waiting api request")
        placeUsecase.createReportExp = exp;
        placeUsecase.createReportResultToReturn = .failure(.clientError("test-error"))

        let vm = PlaceReportBottomSheetViewModel(navigator: navigator, reportType: .etc, placeUsecase: placeUsecase, placeId: placeId)
        
        let confirmButtonTapped$ = PublishRelay<String>();
        
        
        let output = vm.transform(input: PlaceReportBottomSheetViewModel.Input(cancelButttonTapped$: .empty(), placeTypeCellTapped$: .empty(), confirmButtonTapped$: confirmButtonTapped$.asObservable()))
        
        var histories:[Bool] = []
        
        let loadingExp = expectation(description: "loading toggled")
        loadingExp.expectedFulfillmentCount = 2;

        output.isLoading$.skip(1).take(2).subscribe(onNext:{
            isLoading in
            histories.append(isLoading)
            loadingExp.fulfill()
            
        }).disposed(by: disposeBag)
        
        
        confirmButtonTapped$.accept("pov:test")
            
        wait(for:[exp,loadingExp], timeout: 1)
        XCTAssertEqual(histories, [true, false])
        
        let networkError = try output.networkError$.toBlocking(timeout: 1).first()!
        XCTAssertEqual(networkError, .clientError("test-error"))
    }

    func test_selectReportType_thenConfirm_shouldCallUsecaseWithSelectedType(){
        let exp = expectation(description: "waiting api request")
        placeUsecase.createReportExp = exp;
        placeUsecase.createReportResultToReturn = .success(1233)
        
        let vm = PlaceReportBottomSheetViewModel(navigator: navigator, reportType: .etc, placeUsecase: placeUsecase, placeId: placeId)
        
        let confirmButtonTapped$ = PublishRelay<String>();
        let placeTypeCellTapped$ = PublishRelay<PlaceReportType>();
        
        let _ = vm.transform(input: PlaceReportBottomSheetViewModel.Input(cancelButttonTapped$: .empty(), placeTypeCellTapped$: placeTypeCellTapped$.asObservable(), confirmButtonTapped$: confirmButtonTapped$.asObservable()))
        
        placeTypeCellTapped$.accept(.inappropriate)
        confirmButtonTapped$.accept("test")
        wait(for:[exp], timeout: 1)

        XCTAssertEqual(placeUsecase.reportType, .inappropriate)
    
    }

    
}
