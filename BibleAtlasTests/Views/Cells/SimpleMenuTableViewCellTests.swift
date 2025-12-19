//
//  SimpleMenuTableViewCellTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/7/25.
//

import XCTest
@testable import BibleAtlas

final class SimpleMenuTableViewCellTests: XCTestCase {

    private var sut: SimpleMenuTableViewCell!

    override func setUp() {
        super.setUp()
        sut = SimpleMenuTableViewCell(style: .default,
                                      reuseIdentifier: SimpleMenuTableViewCell.identifier)
        sut.layoutIfNeeded()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 초기 UI 세팅 검증

    func test_init_setsUpStackViewAndSubViews() {
        // stackView가 contentView에 추가되어 있어야 함
        XCTAssertTrue(sut.contentView.subviews.contains(sut._test_stackView))

        // stackView 안에 nameLabel, arrowIcon 둘 다 들어있어야 함
        XCTAssertTrue(sut._test_stackView.arrangedSubviews.contains(sut._test_nameLabel))
        XCTAssertTrue(sut._test_stackView.arrangedSubviews.contains(sut._test_arrowIcon))

        // 기본 텍스트 컬러 / 아이콘 컬러
        XCTAssertEqual(sut._test_nameLabel.textColor, .mainText)
        XCTAssertEqual(sut._test_arrowIcon.tintColor, .mainText)
    }

    // MARK: - setMenu: isMovable = true → 화살표 표시

    func test_setMenu_movable_showsArrowAndSetsText_withDefaultColor() {
        // given
        let item = SimpleMenuItem(
            id: .navigateCS,
            nameText: "고객센터",
            isMovable: true,
            textColor: nil
        )

        // when
        sut.setMenu(menuItem: item)

        // then
        XCTAssertEqual(sut._test_nameLabel.text, "고객센터")
        XCTAssertFalse(sut._test_arrowIcon.isHidden)       // isMovable = true → 화살표 보임
        XCTAssertEqual(sut._test_nameLabel.textColor, .mainText) // textColor nil → 기본 mainText 유지
    }

    // MARK: - setMenu: isMovable = false → 화살표 숨김

    func test_setMenu_notMovable_hidesArrow() {
        // given
        let item = SimpleMenuItem(
            id: .logout,
            nameText: "로그아웃",
            isMovable: false,
            textColor: nil
        )

        // when
        sut.setMenu(menuItem: item)

        // then
        XCTAssertEqual(sut._test_nameLabel.text, "로그아웃")
        XCTAssertTrue(sut._test_arrowIcon.isHidden)        // isMovable = false → 화살표 숨김
    }

    // MARK: - setMenu: custom textColor 전달 시 라벨 색상 변경

    func test_setMenu_withCustomTextColor_overridesLabelColor() {
        // given
        let customColor = UIColor.primaryRed   // 프로젝트에서 쓰는 강조색이라고 가정
        let item = SimpleMenuItem(
            id: .withdrawal,
            nameText: "회원 탈퇴",
            isMovable: false,
            textColor: customColor
        )

        // when
        sut.setMenu(menuItem: item)

        // then
        XCTAssertEqual(sut._test_nameLabel.text, "회원 탈퇴")
        XCTAssertEqual(sut._test_nameLabel.textColor, customColor)
        XCTAssertTrue(sut._test_arrowIcon.isHidden)        // isMovable = false 그대로 유지
    }
}
