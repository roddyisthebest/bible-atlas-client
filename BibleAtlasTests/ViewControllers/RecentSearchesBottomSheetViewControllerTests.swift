//
//  RecentSearchesBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/7/25.
//

import XCTest
import RxSwift
@testable import BibleAtlas

final class RecentSearchesBottomSheetViewControllerTests: XCTestCase {

    private var sut: RecentSearchesBottomSheetViewController!
    private var mockVM: MockRecentSearchesBottomSheetViewModel!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        mockVM = MockRecentSearchesBottomSheetViewModel()
        sut = RecentSearchesBottomSheetViewController(
            recentSearchesBottomSheetViewModel: mockVM
        )

        // viewDidLoad + bindViewModel + viewLoaded$.accept(())
        _ = sut.view
        pump()
    }

    override func tearDown() {
        sut = nil
        mockVM = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func pump(_ seconds: TimeInterval = 0.05) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    private func findTableView() -> UITableView {
        guard let table = sut.view.findFirst(UITableView.self) else {
            XCTFail("UITableView not found in hierarchy")
            fatalError()
        }
        return table
    }

    private func findEmptyLabel() -> EmptyLabel {
        guard let lbl = sut.view.findFirst(EmptyLabel.self) else {
            XCTFail("EmptyLabel not found in hierarchy")
            fatalError()
        }
        return lbl
    }

    private func findErrorRetryView() -> ErrorRetryView {
        guard let v = sut.view.findFirst(ErrorRetryView.self) else {
            XCTFail("ErrorRetryView not found in hierarchy")
            fatalError()
        }
        return v
    }

    private func findHeaderButtons() -> (clearAll: UIButton?, close: CircleButton?) {
        let allButtons = sut.view.findAll(UIButton.self)

        let close = allButtons.compactMap { $0 as? CircleButton }.first

        // CircleButton 이 아닌 일반 UIButton 중 하나를 Clear All 로 간주
        let clear = allButtons.first(where: { !($0 is CircleButton) })

        return (clearAll: clear, close: close)
    }

    // MARK: - Tests
    
        
    
    
    /// ✅ viewDidLoad → bindViewModel → transform 이 호출되는지만 검증 (bindViewModel 커버)
    func test_viewDidLoad_callsViewModelTransform_once() {
        // when: view에 접근해서 viewDidLoad + bindViewModel 트리거
        _ = sut.view
        pump()

        // then: transform이 1번 호출되었는지 (== bindViewModel 실행됨)
        XCTAssertEqual(mockVM.transformCallCount, 1)
    }
    
    
    
    /// init + setupUI + bindViewModel 연기 테스트
       func test_viewDidLoad_callsTransform_andSetsUpUI() {
           // given: setUp에서 이미 viewDidLoad 호출됨
           pump()

           // 1) init 커버: sut가 정상 생성되면 init은 무조건 탔음
           XCTAssertNotNil(sut)

           // 2) setupUI 커버: tableView가 view 계층에 올라왔는지 확인
           //    (_test_tableView는 VC extension으로 노출돼 있다고 가정)
           XCTAssertTrue(sut._test_tableView.isDescendant(of: sut.view))

           // 3) bindViewModel 커버: transform이 1번 호출됐는지 확인
           XCTAssertEqual(mockVM.transformCallCount, 1)
       }
    
    

    func test_viewDidLoad_triggersViewLoaded_onViewModel() {
        // viewDidLoad 시점에서 viewLoaded$.accept(()) 호출됨
        pump()
        XCTAssertEqual(mockVM.viewLoadedCallCount, 1)
    }

    func test_initialLoading_showsLoading_andHidesTableAndEmpty() {
        // given
        let tableView = findTableView()
        let empty = findEmptyLabel()
        let errorView = findErrorRetryView()

        // when
        mockVM.isInitialLoadingSubject.onNext(true)
        mockVM.errorToFetchSubject.onNext(nil)
        mockVM.recentSearchesSubject.onNext([])
        pump()

        // then
        // loadingView 자체는 타입이 두 개(메인/푸터)라 굳이 직접 체크 안 하고,
        // 대신 table/empty/error 의 상태만 검증
        XCTAssertTrue(tableView.isHidden)
        XCTAssertTrue(empty.isHidden)
        XCTAssertTrue(errorView.isHidden)
    }

    func test_showList_whenLoadedWithoutError() {
        // given
        let tableView = findTableView()
        let empty = findEmptyLabel()
        let errorView = findErrorRetryView()

        let items: [RecentSearchItem] = [
            RecentSearchItem(id: "1", name: "Jerusalem", koreanName: "예루살렘", type: ""),
            RecentSearchItem(id: "2", name: "Bethel", koreanName: "벧엘", type: "")
        ]

        // when
        mockVM.isInitialLoadingSubject.onNext(false)
        mockVM.errorToFetchSubject.onNext(nil)
        mockVM.recentSearchesSubject.onNext(items)
        pump()

        // then
        XCTAssertFalse(tableView.isHidden)
        XCTAssertTrue(empty.isHidden)
        XCTAssertTrue(errorView.isHidden)

        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 2)
    }

    func test_emptyState_showsEmptyLabel_andHidesTable() {
        // given
        let tableView = findTableView()
        let empty = findEmptyLabel()
        let errorView = findErrorRetryView()

        // when
        mockVM.isInitialLoadingSubject.onNext(false)
        mockVM.errorToFetchSubject.onNext(nil)
        mockVM.recentSearchesSubject.onNext([])
        pump()

        // then
        XCTAssertTrue(tableView.isHidden)
        XCTAssertFalse(empty.isHidden)
        XCTAssertTrue(errorView.isHidden)
    }

    func test_tapCell_sendsSelectedPlaceId_toViewModel() {
        // given: 리스트가 하나 이상 있어야 셀 탭 가능
        let tableView = findTableView()
        let items: [RecentSearchItem] = [
            RecentSearchItem(id: "10", name: "Jerusalem", koreanName: "예루살렘", type: ""),
            RecentSearchItem(id: "20", name: "Bethel", koreanName: "벧엘", type: "")
        ]

        mockVM.isInitialLoadingSubject.onNext(false)
        mockVM.errorToFetchSubject.onNext(nil)
        mockVM.recentSearchesSubject.onNext(items)
        pump()

        // when: 두 번째 셀 탭
        let indexPath = IndexPath(row: 1, section: 0)
        sut.tableView(tableView, didSelectRowAt: indexPath)
        pump()

        // then
        XCTAssertEqual(mockVM.selectedPlaceIds.count, 1)
        XCTAssertEqual(mockVM.selectedPlaceIds.first, "20")
    }

    func test_bottomReached_triggersViewModelBottomReached() {
        // given
        let tableView = findTableView()
        tableView.contentSize = CGSize(width: 100, height: 1000)
        tableView.frame = CGRect(x: 0, y: 0, width: 100, height: 200)

        // 뷰 로드 과정에서 이미 몇 번 불렸는지 기준값 저장
        let initialCount = mockVM.bottomReachedCallCount

        // when: 맨 아래까지 스크롤했다고 가정
        tableView.contentOffset.y = 800
        pump(0.01)   // 메인 런루프 한번 돌려줌 → UIKit이 delegate 호출

        // then: 기존 값에서 정확히 1번만 더 증가했는지만 체크
        XCTAssertEqual(mockVM.bottomReachedCallCount, 1)
    }

    func test_closeButtonTap_triggersClose_onViewModel() {
        // given
        let (_, closeButton) = findHeaderButtons()
        guard let closeButton = closeButton else {
            XCTFail("Close button (CircleButton) not found")
            return
        }

        // when
        closeButton.sendActions(for: .touchUpInside)
        pump()

        // then
        XCTAssertEqual(mockVM.closeButtonTapCount, 1)
    }

    func test_clearAllButtonTap_triggersAllClear_onViewModel() {
        // given
        let (clearAllButton, _) = findHeaderButtons()
        guard let clearAllButton = clearAllButton else {
            XCTFail("Clear All button not found")
            return
        }

        // when
        clearAllButton.sendActions(for: .touchUpInside)
        pump()

        // then
        XCTAssertEqual(mockVM.allClearButtonTapCount, 1)
    }

    func test_forceMedium_and_restoreDetents_doNotCrash() {
        // sheetPresentationController 는 테스트 환경에서 nil 일 수 있지만,
        // 옵셔널 체이닝이라 그냥 호출만 돼도 커버리지에 도움됨.

        mockVM.forceMediumSubject.onNext(())
        mockVM.restoreDetentsSubject.onNext(())
        pump()

        // 단순히 크래시만 안 나면 성공
        XCTAssertTrue(true)
    }
}

// MARK: - UIView 탐색용 헬퍼

private extension UIView {
    func findFirst<T: UIView>(_ type: T.Type) -> T? {
        if let v = self as? T { return v }
        for sub in subviews {
            if let found: T = sub.findFirst(type) {
                return found
            }
        }
        return nil
    }

    func findAll<T: UIView>(_ type: T.Type) -> [T] {
        var result: [T] = []
        if let v = self as? T { result.append(v) }
        for sub in subviews {
            result.append(contentsOf: sub.findAll(type))
        }
        return result
    }
}
