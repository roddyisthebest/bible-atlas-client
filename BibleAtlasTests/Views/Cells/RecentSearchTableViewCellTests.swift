//
//  RecentSearchTableViewCellTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/7/25.
//

import XCTest
@testable import BibleAtlas

final class RecentSearchTableViewCellTests: XCTestCase {

    private var sut: RecentSearchTableViewCell!

    override func setUp() {
        super.setUp()
        sut = RecentSearchTableViewCell(style: .default,
                                        reuseIdentifier: RecentSearchTableViewCell.identifier)
        sut.layoutIfNeeded()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_init_setsUpLayoutAndStyle() {
        // 레이아웃이 정상적으로 잡혔는지 정도만 가볍게 체크
        XCTAssertEqual(sut._test_iconWrapper.layer.cornerRadius, 15)
        XCTAssertEqual(sut._test_searchIcon.tintColor, .white)
        XCTAssertEqual(sut.backgroundColor, .mainItemBkg)

        // stackView 안에 아이콘 + 라벨이 들어가 있는지도 확인
        XCTAssertTrue(sut._test_containerStackView.arrangedSubviews.contains(sut._test_iconWrapper))
        XCTAssertTrue(sut._test_containerStackView.arrangedSubviews.contains(sut._test_searchLabel))
    }

    func test_setText_setsEitherEnglishOrKoreanText() {
        // given
        let en = "Abraham"
        let ko = "아브라함"

        // when
        sut.setText(text: en, koreanText: ko)

        // then
        // L10n.isEnglish 플래그에 따라 둘 중 하나가 들어가므로,
        // 둘 중 하나인지로만 검증
        let labelText = sut._test_searchLabel.text
        XCTAssertNotNil(labelText)

        XCTAssertTrue(
            labelText == en || labelText == ko,
            "searchLabel.text should be either '\(en)' or '\(ko)', but was '\(labelText ?? "nil")'"
        )
    }
}
