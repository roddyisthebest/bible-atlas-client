//
//  MyPageBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/18/25.
//

import XCTest
import RxRelay
import RxTest
import RxBlocking
import RxSwift

@testable import BibleAtlas
final class MyPageBottomSheetViewModelTests: XCTestCase {
    
    private var navigator:MockBottomSheetNavigator!
    private var appStore:MockAppStore!
    private var disposeBag:DisposeBag!
    
    private var user = User(id: 1, name:"test-user", role: .USER, avatar: "test")
    
    override func setUp(){
        super.setUp()
        self.navigator = MockBottomSheetNavigator();
        self.appStore = MockAppStore(state:AppState(profile: nil, isLoggedIn: false));
        self.disposeBag = DisposeBag()
    }
    
    func test_menuItems_staticContent_isCorrect(){
        let vm = MyPageBottomSheetViewModel(navigator: navigator, appStore: appStore)
            
        XCTAssertEqual(vm.menuItems.count, 2)

        XCTAssertEqual(vm.menuItems[0].bottomSheetType, .accountManagement)
        XCTAssertEqual(vm.menuItems[1].bottomSheetType, nil)

        
    }
    func test_profile_stream_updates_whenAppStoreStateChanges(){
        let vm = MyPageBottomSheetViewModel(navigator: navigator, appStore: appStore)

        let output = vm.transform(input: MyPageBottomSheetViewModel.Input(closeButtonTapped$: .empty(), menuItemCellTapped$: .empty()))
        
        let profileExp = expectation(description: "profile set");
        var gotProfile:User?
        output.profile$.skip(1).compactMap{$0}.subscribe(onNext:{
            profile in
            gotProfile = profile
            profileExp.fulfill()
        }).disposed(by: disposeBag)
        
        
        appStore.dispatch(.login(user))
        
        wait(for:[profileExp],timeout: 1.0)
        XCTAssertEqual(gotProfile, user)
        
    }
    
    func test_closeButtonTapped_dismisses(){
        let vm = MyPageBottomSheetViewModel(navigator: navigator, appStore: appStore)
        
        let closeButtonTapped$ = PublishRelay<Void>();
        
        let _ = vm.transform(input: MyPageBottomSheetViewModel.Input(closeButtonTapped$: closeButtonTapped$.asObservable(), menuItemCellTapped$: .empty()))
            
        closeButtonTapped$.accept(())
        XCTAssertTrue(navigator.isDismissed)
    }
    
    func test_menuItemCellTapped_withBottomSheetType_presents(){
        
        let vm = MyPageBottomSheetViewModel(navigator: navigator, appStore: appStore)
        
        let menuItem:MenuItem = MenuItem(nameText: "test", iconImage: "test", iconBackground: .circleButtonBkg, bottomSheetType: .accountManagement)
        let menuItemCellTapped$ = PublishRelay<MenuItem>();
        
        let _ = vm.transform(input: MyPageBottomSheetViewModel.Input(closeButtonTapped$: .empty(), menuItemCellTapped$: menuItemCellTapped$.asObservable()))
            
        menuItemCellTapped$.accept((menuItem))
        XCTAssertEqual(navigator.presentedSheet, menuItem.bottomSheetType)
    }
    
    func test_menuItemCellTapped_withoutBottomSheetType_doesNothing(){
        
        let vm = MyPageBottomSheetViewModel(navigator: navigator, appStore: appStore)
        
        let menuItem:MenuItem = MenuItem(nameText: "test", iconImage: "test", iconBackground: .circleButtonBkg)
        let menuItemCellTapped$ = PublishRelay<MenuItem>();
        
        let _ = vm.transform(input: MyPageBottomSheetViewModel.Input(closeButtonTapped$: .empty(), menuItemCellTapped$: menuItemCellTapped$.asObservable()))
        
        
        
        
        menuItemCellTapped$.accept((menuItem))
        
        
        
        
        XCTAssertNil(navigator.presentedSheet)
        
        
    }

}
