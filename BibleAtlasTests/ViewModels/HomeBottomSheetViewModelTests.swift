//
//  HomeBottomSheetViewModelTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 8/4/25.
//

import XCTest
import RxRelay
import RxSwift
import RxTest
import RxBlocking

@testable import BibleAtlas


final class MockBottomSheetNavigator:BottomSheetNavigator{
    var presentedSheet: BottomSheetType?
    
    func present(_ type: BottomSheetType) {
         presentedSheet = type
     }

    func dismiss(animated: Bool) {}
    func dismissFromDetail(animated: Bool) {}
    func replace(with type: BottomSheetType) {}
    func setPresenter(_ presenter: Presentable?) {}
    
    func reset(){
        presentedSheet = nil
    }
    
}

final class StubAppStore: AppStoreProtocol {
    let state$ = BehaviorRelay<AppState>(value: AppState(profile: nil, isLoggedIn: false))
    
    func simulate(profile: User?) {
        state$.accept(.init(profile: profile, isLoggedIn: profile != nil))
    }
    
    func dispatch(_ action: AppAction) {
        // Optional: state 조작 구현
    }
}


final class HomeBottomSheetViewModelTests:XCTestCase{
    private var vm: HomeBottomSheetViewModel!
    private var navigator: MockBottomSheetNavigator!
    private var appStore: StubAppStore!
    
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    
    override func setUp() {
        super.setUp();
        
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        
        navigator = MockBottomSheetNavigator()
        appStore = StubAppStore()
      
    }
  
    func makeViewModel() -> HomeBottomSheetViewModel {
        HomeBottomSheetViewModel(
            navigator: navigator,
            appStore: appStore,
            authUseCase: nil,
            recentSearchService: nil
        )
    }
    
    
    
    func test_initial_state() {
         let vm = makeViewModel()
         XCTAssertEqual(vm.keyword$.value, "")
         XCTAssertEqual(vm.isSearchingMode$.value, false)
     }
    
    
    func test_editingDidBegin_sets_isSearchingMode_true() {
        let editingBegin$ = scheduler.createColdObservable([.next(10, ())])
        let vm = makeViewModel()

        _ = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: editingBegin$.asObservable()
        ))

        let observer = scheduler.createObserver(Bool.self)
        vm.isSearchingMode$
            .subscribe(observer)
            .disposed(by: disposeBag)
        

        scheduler.start()
        XCTAssertEqual(observer.events.last?.value.element, true)
    }
    
    
    func test_cancelButtonTapped_resets_keyword_and_searchingMode() {
        let cancel$ = scheduler.createColdObservable([.next(5, ())])
        let vm = makeViewModel()
        
        vm.isSearchingMode$.accept(true)
        vm.keyword$.accept("some search")

        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: cancel$.asObservable(),
            editingDidBegin$: .empty()
        ))

        let observer = scheduler.createObserver(HomeScreenMode.self)
        output.screenMode$
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        
        scheduler.start()

        XCTAssertEqual(vm.keyword$.value, "")
        XCTAssertEqual(vm.isSearchingMode$.value, false)
        let emitted = observer.events.compactMap { $0.value.element }

        XCTAssertEqual(emitted, [.searching, .home])
    }
    
    
    func test_screenMode_changes_correctly(){
        let vm = makeViewModel()
        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: .empty()
        ))
        let observer = scheduler.createObserver(HomeScreenMode.self)
        output.screenMode$
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        vm.isSearchingMode$.accept(true) // → .searchReady
        vm.keyword$.accept("abc") // → .searching
        vm.isSearchingMode$.accept(false) // → .home

        
        let emitted = observer.events.compactMap { $0.value.element }
        XCTAssertEqual(emitted, [.home, .searchReady, .searching, .home])
        
        
    }
    
    
    func test_avatarButtonTapped_navigates_to_mypage_or_login() {
        let tap$ = PublishRelay<Void>()
        appStore.simulate(profile: User(id: 123, name: "User", role:.USER,avatar: "test"))

        let vm = makeViewModel()

         // 1. 로그인 상태

        
         _ = vm.transform(input: .init(
             avatarButtonTapped$: tap$.asObservable(),
             cancelButtonTapped$: .empty(),
             editingDidBegin$: .empty()
         ))
        tap$.accept(())
        XCTAssertEqual(navigator.presentedSheet, .myPage)

        // 2. 로그아웃 상태
        navigator.reset()
        appStore.simulate(profile: nil)
            
        
        
        tap$.accept(())
        XCTAssertEqual(navigator.presentedSheet, .login)
     }
    
    
    func test_appStoreState_update_reflects_in_viewModel() {
        let vm = makeViewModel()

        let profileObserver = scheduler.createObserver(User?.self)
        let isLoggedInObserver = scheduler.createObserver(Bool.self)

        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: .empty()
        ))

        output.profile$
            .subscribe(profileObserver)
            .disposed(by: disposeBag)

        output.isLoggedIn$
            .subscribe(isLoggedInObserver)
            .disposed(by: disposeBag)

        // 앱 스토어 상태 변경 시뮬레이션
        appStore.simulate(profile: User(id: 999, name: "Tester", role: .USER, avatar: "avatar"))
        scheduler.start()

        XCTAssertEqual(profileObserver.events.last?.value.element??.name, "Tester")
        XCTAssertEqual(isLoggedInObserver.events.last?.value.element, true)
    }
    
    
    func test_keywordText_driver_emits_updated_text() {
        let vm = makeViewModel()
        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: .empty()
        ))

        vm.keyword$.accept("hello world")
        
        let result = try? output.keywordText$.toBlocking(timeout: 1).first()
        XCTAssertEqual(result, "hello world")
    }

    
}
