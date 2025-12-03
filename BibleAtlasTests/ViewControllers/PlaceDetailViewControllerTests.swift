//
//  PlaceDetailViewControllerTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/21/25.
//

import XCTest
@testable import BibleAtlas

final class PlaceDetailViewControllerTests: XCTestCase {

    
    private var vm:MockPlaceDetailViewModel!;
    private var vc:PlaceDetailViewController!
    
    private var placeId = "test-place-id"
    override func setUp(){
        super.setUp()
        vm = MockPlaceDetailViewModel()
        vc = PlaceDetailViewController(placeDetailViewModel: vm, placeId: placeId)
        
        _ = vc.view;
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()
    }
    
    override func tearDown(){
        vc = nil
        vm = nil
        super.tearDown()
    }
   
    func test_viewDidLoad_emitsViewLoaded_showsLoading_hidesBodyAndError_initially(){
        
        vm.setLoadError(nil)
        vm.setLoading(true)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertEqual(vm.viewLoadedCount, 1)
        XCTAssertTrue(vc._test_isLoadingVisible)
        XCTAssertTrue(vc._test_isBodyHidden)
        XCTAssertFalse(vc._test_isErrorVisible)

    }
    
    
    
    func test_isLoading_false_hidesLoading_showsBody_hidesError(){
        vm.setLoading(false)
        vm.setLoadError(nil)
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertFalse(vc._test_isBodyHidden)
        XCTAssertFalse(vc._test_isErrorVisible)
        
    }
    
    
    func test_loadError_showsError_hidesBodyAndStopsLoading(){
        
        vm.setLoadError(.clientError("test-error"))
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        
        XCTAssertFalse(vc._test_isLoadingVisible)
        XCTAssertTrue(vc._test_isBodyHidden)

        
    }
    
    func test_place_emit_updatesTitleDescriptionGeneration_andShowsBody(){
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "street yo", koreanDescription: "요요", stereo: .child, likeCount: 2, types: [])
        vm.emit(place: place)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        
        
        let expectedTitle = L10n.isEnglish ? place.name : place.koreanName
        let expectedDescription = L10n.isEnglish ? place.description : place.koreanDescription

        
        
        XCTAssertEqual(vc._test_titleText, expectedTitle)
        XCTAssertEqual(vc._test_descriptionText, expectedDescription)
        
    }
    
    
    func test_place_withNoRelations_showsRelatedPlaceEmptyView(){
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "street yo", koreanDescription: "요요", stereo: .child, likeCount: 2, types: [])
        vm.emit(place: place)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        
        XCTAssertFalse(vc._test_isRelatedPlaceTableVisible)
        XCTAssertFalse(vc._test_isRelatedVerseTableVisible)

    }
    
    func test_bibles_emit_showsOrHidesRelatedVerseEmptyView(){
        let bibles = [Bible(bookName: .Acts, verses: ["12:21"]), Bible(bookName: .Chr1, verses: ["12:31","21:21"])]
        
        vm.emit(bibles:(bibles,0))
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertTrue(vc._test_isRelatedVerseTableVisible)
    }
    
    func test_like_isLiking_true_disablesButton_showsSpinner_hidesTitleImage(){
        
        vm.setLiking(true)
        let place = Place(id: "test", name: "test", koreanName: "test", isModern: true, description: "street yo", koreanDescription: "요요", stereo: .child, likeCount: 2, types: [])
        vm.emit(place: place)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertFalse(vc._test_likeButtonEnabled)
        XCTAssertNil(vc._test_likeButtonTitle)
        XCTAssertNil(vc._test_likeButtonImage)
        
        XCTAssertTrue(vc._test_isLikeLoadingVisible)
    }
    
    
    func test_like_isLiking_false_enablesButton_showsTitleImage(){
        let place = Place(id: "test", name: "test", koreanName: "test", isModern: true, description: "street yo", koreanDescription: "요요", stereo: .child, likeCount: 2, types: [])
        vm.emit(place: place)
        vm.setLiking(false)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        XCTAssertTrue(vc._test_likeButtonEnabled)
        XCTAssertEqual(vc._test_likeButtonTitle, L10n.PlaceDetail.likes(place.likeCount))
        XCTAssertNotNil(vc._test_likeButtonImage)
        
    }
    
    func test_like_placeLiked_true_appliesActiveStyle_andTitleCount(){
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "street yo", koreanDescription: "요요", stereo: .child, likeCount: 2, types: [], isLiked:true)
        vm.emit(place: place)
        
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertEqual(vc._test_likeButton?.backgroundColor, .primaryBlue)
        XCTAssertEqual(vc._test_likeButton?.titleColor(for: .normal), .white)
        XCTAssertEqual(vc._test_likeButton?.tintColor, .white)
        XCTAssertEqual(vc._test_likeButton?.title(for: .normal), L10n.PlaceDetail.likes(place.likeCount))

    }
    
    func test_like_placeLiked_false_appliesInactiveStyle_andTitleCount(){
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "street yo", koreanDescription: "요요", stereo: .child, likeCount: 2, types: [], isLiked:false)
        
        vm.emit(place: place)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertEqual(vc._test_likeButton?.backgroundColor, .circleButtonBkg)
        XCTAssertEqual(vc._test_likeButton?.titleColor(for: .normal), .mainText)
        XCTAssertEqual(vc._test_likeButton?.tintColor, .mainText)
        XCTAssertEqual(vc._test_likeButton?.title(for: .normal), L10n.PlaceDetail.likes(place.likeCount))
        
    }
    
    
    func test_save_isSaving_true_showsSpinner(){
        
        vm.setSaving(true)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        
        XCTAssertEqual(vc._test_saveButton?.isEnabled, false)
        XCTAssertNil(vc._test_saveButton?.image(for: .normal))

    }
    
    func test_save_isSaving_false_hidesSpinner(){
        vm.setSaving(false)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertEqual(vc._test_saveButton?.isEnabled, true)
        XCTAssertEqual(vc._test_saveButton?._test_loadingView.isHidden, true)
        
    }
    
    
    func test_memo_visible_whenLoggedIn_andPlaceHasMemo(){
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "street yo", koreanDescription: "요요", stereo: .child, likeCount: 2, types: [], memo:PlaceMemo(user: 3, place: "tes", text: "nocap"))
        vm.setLoggedIn(true)
        vm.emit(place: place)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertEqual(vc._test_memoButton?.isHidden, false)
        XCTAssertEqual(vc._test_memoLabel?.text, "nocap")

    }
    func test_memo_hidden_whenLoggedOut_orNoMemo(){
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "street yo", koreanDescription: "요요", stereo: .child, likeCount: 2, types: [])
        vm.setLoggedIn(true)
        vm.emit(place: place)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertEqual(vc._test_memoButton?.isHidden, true)
    
    }
    
    
    func test_tapClose_emitsCloseInput(){
        vc._test_tapClose();
        XCTAssertEqual(vm.closeTapCount, 1)
    }
    
    func test_tapBack_emitsBackInput(){
        vc._test_tapBack();
        XCTAssertEqual(vm.backTapCount, 1)
    }
    
    func test_tapLike_emitsLikeInput(){
        vc._test_tapLike();
        XCTAssertEqual(vm.likeTapCount, 1)
    }
    
    func test_tapMemo_emitsMemoInput(){
        vc._test_tapMemo();
        XCTAssertEqual(vm.memoTapCount, 1)
    }
    
    func test_selectRelatedPlaceRow_emitsPlaceId_toViewModelInput(){
        let dummyPlaceId = "relation-test"
        let dummyPlace = Place(id: dummyPlaceId, name: "test", koreanName: "테스트", isModern: true, description: "street yo", koreanDescription: "요요", stereo: .child, likeCount: 2, types: [])
        
        
        let place = Place(id: "test", name: "test", koreanName: "테스트", isModern: true, description: "street yo", koreanDescription: "요요", stereo: .child, likeCount: 2, types: [], childRelations: [PlaceRelation(id: 12, place: dummyPlace, possibility: 20)])
        
        vm.emit(place: place)
        
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        vc._test_selectRelatedPlaceRow(0)
        
        
        XCTAssertEqual(vm.tappedPlaceIds.last, dummyPlaceId)
        
    }
    
    func test_tapVerseCell_emitsVerse_toViewModelInput(){
        
        vm.emit(bibles: ([Bible(bookName: .Acts, verses: ["12:21","12:23"])],0))
            
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        guard let cell = vc._test_makeVerseCell(row: 0) else { XCTFail("cell nil"); return }

        
        cell._test_fireTap(verse: "gen 12:21")

        XCTAssertEqual(vm.tappedVerses.last, "gen 12:21")
        
    }
    
    func test_moreButton_visible_whenExceedBookCount(){
    
        vm.emit(bibles: ([], 3))
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))

        XCTAssertTrue(vc._relatedVerseMoreButtonVisible)
    }
    
    
}
