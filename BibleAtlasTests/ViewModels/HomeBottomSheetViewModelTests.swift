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

class MockBottomSheetNavigator: BottomSheetNavigator {
    var presentedSheet: BottomSheetType?
    var isDismissed = false

    func present(_ type: BottomSheetType) { presentedSheet = type }
    func dismiss(animated: Bool) { isDismissed = true }
    func dismissFromDetail(animated: Bool) {}
    // 프로젝트에 replace가 실제로 있으면 유지, 없으면 지워
    func replace(with type: BottomSheetType) {}
    func setPresenter(_ presenter: Presentable?) {}

    func reset() { presentedSheet = nil }
}

final class StubAppStore: AppStoreProtocol {
    let state$ = BehaviorRelay<AppState>(value: AppState(profile: nil, isLoggedIn: false))

    func simulate(profile: User?) {
        state$.accept(.init(profile: profile, isLoggedIn: profile != nil))
    }

    func dispatch(_ action: AppAction) {
        // Optional
    }
}

final class HomeBottomSheetViewModelTests: XCTestCase {

    private var vm: HomeBottomSheetViewModel!
    private var navigator: MockBottomSheetNavigator!
    private var appStore: StubAppStore!
    private var notificationService: MockNotificationService!

    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!

    override func setUp() {
        super.setUp()

        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)

        navigator = MockBottomSheetNavigator()
        appStore = StubAppStore()
        notificationService = MockNotificationService()
    }

    override func tearDown() {
        vm = nil
        navigator = nil
        appStore = nil
        notificationService = nil
        disposeBag = nil
        scheduler = nil
        super.tearDown()
    }

    private func makeViewModel() -> HomeBottomSheetViewModel {
        HomeBottomSheetViewModel(
            navigator: navigator,
            appStore: appStore,
            authUseCase: nil,
            recentSearchService: nil,
            notificationService: notificationService,
            schedular: scheduler
        )
    }

    private func pump(_ seconds: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    // MARK: - Tests

    func test_initial_state_emits_home_and_emptyKeyword() {
        let vm = makeViewModel()

        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: .empty(),
            keywordChanged$: .empty()
        ))

        var modes: [HomeScreenMode] = []
        var keywords: [String] = []

        output.screenMode$
            .drive(onNext: { modes.append($0) })
            .disposed(by: disposeBag)

        output.keywordText$
            .drive(onNext: { keywords.append($0) })
            .disposed(by: disposeBag)

        pump()

        XCTAssertEqual(modes.first, .home)
        XCTAssertEqual(keywords.first, "")
    }

    func test_editingDidBegin_whenHome_movesTo_searchReady() {
        let vm = makeViewModel()

        let editingBegin$ = scheduler.createColdObservable([.next(10, ())])
        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: editingBegin$.asObservable(),
            keywordChanged$: .empty()
        ))

        var modes: [HomeScreenMode] = []
        output.screenMode$
            .drive(onNext: { modes.append($0) })
            .disposed(by: disposeBag)

        scheduler.start()
        pump()

        // home -> searchReady
        XCTAssertEqual(modes, [.home, .searchReady])
    }

    func test_keywordChanged_whenInSearchReady_movesTo_searching_and_emptyMovesBackTo_searchReady() {
        let vm = makeViewModel()

        let editingBegin$ = scheduler.createColdObservable([.next(10, ())])
        let keywordChanged$ = scheduler.createColdObservable([
            .next(20, "  abc  "),   // -> searching ("abc")
            .next(30, "   ")        // -> searchReady
        ])

        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: editingBegin$.asObservable(),
            keywordChanged$: keywordChanged$.asObservable()
        ))

        var modes: [HomeScreenMode] = []
        var keywords: [String] = []

        output.screenMode$
            .drive(onNext: { modes.append($0) })
            .disposed(by: disposeBag)

        output.keywordText$
            .drive(onNext: { keywords.append($0) })
            .disposed(by: disposeBag)

        scheduler.start()
        pump()

        XCTAssertEqual(modes, [.home, .searchReady, .searching, .searchReady])
        // keywordText$는 trim된 값으로 들어감
        XCTAssertTrue(keywords.contains("abc"))
        XCTAssertEqual(keywords.last, "")
    }

    func test_cancelButtonTapped_resets_to_home_and_clearsKeyword() {
        let vm = makeViewModel()

        let editingBegin$ = scheduler.createColdObservable([.next(10, ())])
        let keywordChanged$ = scheduler.createColdObservable([.next(20, "Jerusalem")])
        let cancel$ = scheduler.createColdObservable([.next(30, ())])

        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: cancel$.asObservable(),
            editingDidBegin$: editingBegin$.asObservable(),
            keywordChanged$: keywordChanged$.asObservable()
        ))

        var modes: [HomeScreenMode] = []
        var keywords: [String] = []

        output.screenMode$
            .drive(onNext: { modes.append($0) })
            .disposed(by: disposeBag)

        output.keywordText$
            .drive(onNext: { keywords.append($0) })
            .disposed(by: disposeBag)

        scheduler.start()
        pump()

        // home -> searchReady -> searching -> home
        XCTAssertEqual(modes, [.home, .searchReady, .searching, .home])
        // cancel에서 keyword ""로 초기화
        XCTAssertEqual(keywords.last, "")
    }

    func test_avatarButtonTapped_navigates_to_mypage_or_login() {
        let tap$ = PublishRelay<Void>()
        let vm = makeViewModel()

        _ = vm.transform(input: .init(
            avatarButtonTapped$: tap$.asObservable(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: .empty(),
            keywordChanged$: .empty()
        ))

        // 1) 로그인 상태
        appStore.simulate(profile: User(id: 123, name: "User", role: .USER, avatar: "test"))
        pump()

        tap$.accept(())
        XCTAssertEqual(navigator.presentedSheet, .myPage)

        // 2) 로그아웃 상태
        navigator.reset()
        appStore.simulate(profile: nil)
        pump()

        tap$.accept(())
        XCTAssertEqual(navigator.presentedSheet, .login)
    }

    func test_appStoreState_update_reflects_in_output() {
        let vm = makeViewModel()

        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: .empty(),
            keywordChanged$: .empty()
        ))

        var lastProfile: User?
        var lastIsLoggedIn: Bool?

        output.profile$
            .subscribe(onNext: { lastProfile = $0 })
            .disposed(by: disposeBag)

        output.isLoggedIn$
            .subscribe(onNext: { lastIsLoggedIn = $0 })
            .disposed(by: disposeBag)

        appStore.simulate(profile: User(id: 999, name: "Tester", role: .USER, avatar: "avatar"))
        pump()

        XCTAssertEqual(lastProfile?.name, "Tester")
        XCTAssertEqual(lastIsLoggedIn, true)
    }

    func test_keywordText_driver_emits_trimmed_text_from_keywordChanged_input() {
        let vm = makeViewModel()

        let keywordChanged$ = scheduler.createColdObservable([.next(10, "  hello world  ")])

        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: .empty(),
            keywordChanged$: keywordChanged$.asObservable()
        ))

        var keywords: [String] = []
        output.keywordText$
            .drive(onNext: { keywords.append($0) })
            .disposed(by: disposeBag)

        scheduler.start()
        pump()

        XCTAssertTrue(keywords.contains("hello world"))
        XCTAssertEqual(keywords.last, "hello world")
    }

    func test_postCommandSheet_forceMedium_emits_forceMedium() {
        let vm = makeViewModel()

        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: .empty(),
            keywordChanged$: .empty()
        ))

        let exp = expectation(description: "forceMedium emit")
        output.forceMedium$
            .subscribe(onNext: { exp.fulfill() })
            .disposed(by: disposeBag)

        notificationService.post(.sheetCommand, object: SheetCommand.forceMedium)
        wait(for: [exp], timeout: 1.0)
    }

    func test_postCommandSheet_restoreDetents_emits_restoreDetents() {
        let vm = makeViewModel()

        let output = vm.transform(input: .init(
            avatarButtonTapped$: .empty(),
            cancelButtonTapped$: .empty(),
            editingDidBegin$: .empty(),
            keywordChanged$: .empty()
        ))

        let exp = expectation(description: "restoreDetents emit")
        output.restoreDetents$
            .subscribe(onNext: { exp.fulfill() })
            .disposed(by: disposeBag)

        notificationService.post(.sheetCommand, object: SheetCommand.restoreDetents)
        wait(for: [exp], timeout: 1.0)
    }
}
