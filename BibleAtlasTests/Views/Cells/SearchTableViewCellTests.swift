//
//  SearchTableViewCellTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/7/25.
//

import XCTest
@testable import BibleAtlas

final class SearchTableViewCellTests: XCTestCase {

    private var sut: SearchTableViewCell!

    override func setUp() {
        super.setUp()
        sut = SearchTableViewCell(style: .default,
                                  reuseIdentifier: SearchTableViewCell.identifier)
        sut.layoutIfNeeded()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - init / hierarchy / style

    func test_init_setsUpHierarchyAndStyle() {
        // hierarchy: subviews가 contentView 아래에 잘 붙었는지 대략 검증
        XCTAssertTrue(sut._test_searchIcon.isDescendant(of: sut.contentView))
        XCTAssertTrue(sut._test_searchLabel.isDescendant(of: sut.contentView))
        XCTAssertTrue(sut._test_circleIcon.isDescendant(of: sut.contentView))
        XCTAssertTrue(sut._test_typeLabel.isDescendant(of: sut.contentView))

        // style: 배경색
        XCTAssertEqual(sut.contentView.backgroundColor, .mainBkg)
    }

    // MARK: - setCotent: 정상 타입일 때 라벨 세팅

    func test_setContent_setsLabels_whenPlaceTypeIsKnown() {
        // given
        let placeTypeName: PlaceTypeName = .river   // 아무 타입 하나
        let item = RecentSearchItem(
            id: "1",
            name: "Jordan River",
            koreanName: "요단강",
            type: placeTypeName.rawValue
        )

        // when
        sut.setCotent(recentSearchItem: item)
        sut.layoutIfNeeded()

        // then
        // L10n.isEnglish 여부에 따라 영/한 중 하나이므로 둘 중 하나인지만 체크
        XCTAssertTrue(
            [item.name, item.koreanName].contains(sut._test_searchLabel.text),
            "searchLabel.text should be either English or Korean name"
        )

        let expectedTypeTexts = [placeTypeName.titleEn, placeTypeName.titleKo]
        XCTAssertNotNil(sut._test_typeLabel.text)
        XCTAssertTrue(
            expectedTypeTexts.contains(sut._test_typeLabel.text!),
            "typeLabel.text should be either English or Korean title"
        )
    }

    // MARK: - setCotent: 알 수 없는 타입일 때 typeLabel 은 nil

    func test_setContent_setsTypeLabelNil_whenPlaceTypeIsUnknown() {
        // given
        let item = RecentSearchItem(
            id: "2",
            name: "Unknown Place",
            koreanName: "알 수 없는 장소",
            type: "some-unknown-type"   // PlaceTypeName(rawValue:) 실패
        )

        // when
        sut.setCotent(recentSearchItem: item)
        sut.layoutIfNeeded()

        // then
        XCTAssertTrue(
            [item.name, item.koreanName].contains(sut._test_searchLabel.text),
            "searchLabel.text should still be set"
        )
        XCTAssertNil(
            sut._test_typeLabel.text,
            "Unknown type string should make typeLabel.text nil"
        )
    }
}
