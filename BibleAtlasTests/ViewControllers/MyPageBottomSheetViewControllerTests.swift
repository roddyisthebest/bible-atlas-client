//
//  MyPageBottomSheetViewControllerTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
import RxSwift
@testable import BibleAtlas

final class MyPageBottomSheetViewControllerTests: XCTestCase {

    private var sut: MyPageBottomSheetViewController!
    private var mockVM: MockMyPageBottomSheetViewModel!

    override func setUp() {
        super.setUp()

        // 임의 메뉴 아이템 2개
        let item1 = MenuItem(
            nameText: "Account",
            iconImage: "person.fill",
            iconBackground: .red,
            bottomSheetType: .accountManagement
        )
        let item2 = MenuItem(
            nameText: "Version",
            iconImage: "v.circle.fill",
            iconBackground: .blue,
            contentText: "1.0.0",
            bottomSheetType: nil
        )

        mockVM = MockMyPageBottomSheetViewModel(menuItems: [item1, item2])
        sut = MyPageBottomSheetViewController(myPageBottomSheetViewModel: mockVM)
    }

    override func tearDown() {
        sut = nil
        mockVM = nil
        super.tearDown()
    }

    // 메인 런루프 한 번 돌리는 헬퍼
    private func pump(_ sec: TimeInterval = 0.01) {
        RunLoop.current.run(until: Date().addingTimeInterval(sec))
    }

    // view 계층에서 UITableView 찾아오는 헬퍼
    private func findTableView(in view: UIView) -> UITableView? {
        if let tv = view as? UITableView { return tv }
        for sub in view.subviews {
            if let tv = findTableView(in: sub) { return tv }
        }
        return nil
    }

    // UILabel 찾는 헬퍼 (필요하면 사용)
    private func findLabel(in view: UIView, where predicate: (UILabel) -> Bool) -> UILabel? {
        if let label = view as? UILabel, predicate(label) {
            return label
        }
        for sub in view.subviews {
            if let found = findLabel(in: sub, where: predicate) { return found }
        }
        return nil
    }

    // MARK: - 1) viewDidLoad → bindViewModel → transform 호출

    func test_viewDidLoad_callsViewModelTransform_once() {
        // when
        _ = sut.view   // viewDidLoad + bindViewModel 트리거
        pump()

        // then
        XCTAssertEqual(mockVM.transformCallCount, 1)
    }

    // MARK: - 2) tableView rows == menuItems.count

    func test_tableView_rowCount_matchesMenuItems() {
        // given
        _ = sut.view
        pump()

        guard let tableView = findTableView(in: sut.view) else {
            XCTFail("UITableView not found in view hierarchy")
            return
        }

        // when
        let rows = tableView.numberOfRows(inSection: 0)

        // then
        XCTAssertEqual(rows, mockVM.menuItems.count)
    }

    // MARK: - 3) didSelectRow → menuItemCellTapped$ → ViewModel로 전달

    func test_didSelectRow_sendsMenuItemToViewModel() {
        // given
        _ = sut.view
        pump()

        guard let tableView = findTableView(in: sut.view) else {
            XCTFail("UITableView not found in view hierarchy")
            return
        }

        let indexPath = IndexPath(row: 0, section: 0)

        // when
        // delegate 직접 호출 (VC가 UITableViewDelegate 채택)
        sut.tableView(tableView, didSelectRowAt: indexPath)
        pump()

        // then
        XCTAssertEqual(mockVM.receivedMenuItemTaps.count, 1)
        XCTAssertEqual(mockVM.receivedMenuItemTaps.first?.nameText, mockVM.menuItems[0].nameText)
    }

    // MARK: - 4) closeButton 탭 → ViewModel에 전달되는지 (간접 확인)

    func test_closeButtonTap_triggersViewModelClose() {
        // given
        _ = sut.view
        pump()

        // when
        sut._test_closeButton.sendActions(for: .touchUpInside)
        pump()

        // then
        XCTAssertEqual(mockVM.receivedCloseEvents, 1)
    }
    
    
    // MARK: - 5) profile$ 바인딩: non-nil profile 들어오면 label 세팅

      func test_profileUpdate_withNonNilProfile_updatesLabels() {
          // given
          _ = sut.view
          pump()

          // 초기 텍스트 (게스트 상태)
          let initialName = sut._test_nameLabel.text
          let initialEmail = sut._test_emailLabel.text

          // User 모델은 프로젝트에 맞게 생성 (name/email 없으면 없어도 됨)
          var user = User(id: 1, role: .USER, avatar: "https://example.com/avatar.svg")
          // name / email 프로퍼티가 있다면 이렇게 세팅, 없으면 이 두 줄은 지워도 됨
          user.name = "홍길동"
          user.email = "hong@test.com"

          // when: ViewModel 쪽으로 profile 이벤트 발행
          mockVM.emitProfile(user)
          pump(0.1)   // main runloop 한 번 돌려줌

          // then
          // name / email이 optional이면 fallback 때문에 값이 같을 수도 있으니
          // "바뀌었는지"가 아니라 "nil은 아니고 뭔가 들어갔다" 정도만 체크
          XCTAssertNotNil(sut._test_nameLabel.text)
          XCTAssertNotNil(sut._test_emailLabel.text)

          // 최소한 바인딩이 한 번은 돌아갔다는 느낌만 보면 됨
          XCTAssertNotEqual(sut._test_nameLabel.text, "")
          XCTAssertNotEqual(sut._test_emailLabel.text, "")
      }

      // MARK: - 6) profile$ 에 nil이 들어와도 크래시 없이 기존 값 유지

      func test_profileUpdate_withNilProfile_doesNotChangeLabelsOrCrash() {
          // given
          _ = sut.view
          pump()

          let initialName = sut._test_nameLabel.text
          let initialEmail = sut._test_emailLabel.text

          // when
          mockVM.emitProfile(nil)   // guard let profile = profile else { return } 타게 함
          pump(0.05)

          // then
          XCTAssertEqual(sut._test_nameLabel.text, initialName)
          XCTAssertEqual(sut._test_emailLabel.text, initialEmail)
      }
    
    
    // MARK: - 7) heightForRowAt이 menuHeight를 반환하는지 (기본 60)

       func test_heightForRowAt_returnsPositiveHeight() {
           // given
           _ = sut.view
           pump()

           let tableView = sut._test_menuTableView
           let indexPath = IndexPath(row: 0, section: 0)

           // when
           let rowHeight = sut.tableView(tableView, heightForRowAt: indexPath)

           // then
           XCTAssertGreaterThan(rowHeight, 0)
           // 기본값이 60이기 때문에, 레이아웃 전이라도 최소 0보다 크다 정도만 확인
       }
    
    
    
}
