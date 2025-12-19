//
//  MenuTableViewCellTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/7/25.
//

import XCTest
@testable import BibleAtlas

final class MenuTableViewCellTests: XCTestCase {

    private var sut: MenuTableViewCell!

    override func setUp() {
        super.setUp()
        sut = MenuTableViewCell(style: .default, reuseIdentifier: MenuTableViewCell.identifier)
        sut.frame = CGRect(x: 0, y: 0, width: 320, height: 60)
        sut.layoutIfNeeded()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 초기 레이아웃 / 기본 상태

    func test_init_setsUpHierarchyAndConstraints() {
        // stackView가 contentView 안에 있어야 함
        XCTAssertTrue(sut.contentView.subviews.contains(sut._test_stackView))

        // iconWrapper는 titleStackView의 arrangedSubview 이어야 함
        XCTAssertTrue(
            sut._test_titleStackView.arrangedSubviews.contains(where: { $0 === sut._test_iconWrapper }),
            "iconWrapper should be in titleStackView.arrangedSubviews"
        )

        // 이름 라벨이 존재하는지
        XCTAssertNotNil(sut._test_nameLabel)

        // iconWrapper 크기 제약이 제대로 들어갔는지 (대략적 체크)
        sut.layoutIfNeeded()
        XCTAssertEqual(sut._test_iconWrapper.bounds.width,
                       CGFloat(sut.iconWrapperLength),
                       accuracy: 0.5)
        XCTAssertEqual(sut._test_iconWrapper.bounds.height,
                       CGFloat(sut.iconWrapperLength),
                       accuracy: 0.5)
    }


    // MARK: - setMenu(contentText == nil) → 화살표 아이콘 표시

    func test_setMenu_withoutContentText_addsArrowIconAndNoContentLabel() {
        // given
        let item = MenuItem(
            nameText: "Account Management",
            iconImage: "person.fill",
            iconBackground: .red,
            contentText: nil,
            bottomSheetType: nil
        )

        // when
        sut.setMenu(menuItem: item)
        sut.layoutIfNeeded()

        // then: 텍스트 / 아이콘 / 배경색 검증
        XCTAssertEqual(sut._test_nameLabel.text, "Account Management")

        // SF Symbol명이 제대로 반영됐는지 (systemName으로 만든 이미지)
        XCTAssertNotNil(sut._test_icon.image)

        XCTAssertEqual(sut._test_iconWrapper.backgroundColor, .red)

        // stackView 안에 arrowIcon은 있어야 하고,
        // contentLabel은 아직 없어야 함
        let arranged = sut._test_stackView.arrangedSubviews
        XCTAssertTrue(arranged.contains(where: { $0 === sut._test_arrowIcon }))
        XCTAssertFalse(arranged.contains(where: { $0 === sut._test_contentLabel }))
    }

    // MARK: - setMenu(contentText != nil) → contentLabel 표시, 화살표 대신

    func test_setMenu_withContentText_addsContentLabelAndNoArrowIcon() {
        // given
        let item = MenuItem(
            nameText: "App Version",
            iconImage: "v.circle.fill",
            iconBackground: .blue,
            contentText: "1.0.0",
            bottomSheetType: nil
        )

        // when
        sut.setMenu(menuItem: item)
        sut.layoutIfNeeded()

        // then: 이름/내용 텍스트 검증
        XCTAssertEqual(sut._test_nameLabel.text, "App Version")
        XCTAssertEqual(sut._test_contentLabel.text, "1.0.0")
        XCTAssertEqual(sut._test_iconWrapper.backgroundColor, .blue)

        let arranged = sut._test_stackView.arrangedSubviews

        // contentLabel은 있어야 함
        XCTAssertTrue(arranged.contains(where: { $0 === sut._test_contentLabel }))

        // 이 한 번의 호출 기준으론 arrowIcon은 추가되지 않아야 함
        XCTAssertFalse(arranged.contains(where: { $0 === sut._test_arrowIcon }))
    }
}
