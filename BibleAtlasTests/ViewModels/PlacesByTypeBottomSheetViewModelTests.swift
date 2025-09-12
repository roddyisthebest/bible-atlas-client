//
//  PlacesByTypeBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/10/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas

final class PlacesByTypeBottomSheetViewModelTests: XCTestCase {

//navigator:BottomSheetNavigator?,
//     placeUsecase:PlaceUsecaseProtocol?,
//     placeTypeName:PlaceTypeName

    private var placeUsecase:MockPlaceusecase!
    private var navigator:MockBottomSheetNavigator!
    private var disposeBag:DisposeBag!
    
    override func setUp(){
        super.setUp()
        placeUsecase = MockPlaceusecase();
        navigator = MockBottomSheetNavigator();
        disposeBag = DisposeBag();
    }
    
    func test_viewLoaded_success_replacesPlaces_setsLoadingFalse_updatesTotal_clearsError(){
        
        
    }
    
    
}
