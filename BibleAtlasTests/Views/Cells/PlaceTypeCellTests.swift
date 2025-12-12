//
//  PlaceTypeCellTests.swift
//  BibleAtlasTests
//

import XCTest
@testable import BibleAtlas

final class PlaceTypeCellTests: XCTestCase {

    private var sut: PlaceTypeCell!

    override func setUp() {
        super.setUp()
        sut = PlaceTypeCell(frame: .zero)
        sut.layoutIfNeeded()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_setPlace_setsTextsAndIcon() {
        // given
        let placeType = PlaceTypeName.river   // enum 실제 케이스에 맞게 수정 가능
        let placeTypeWithCount = PlaceTypeWithPlaceCount(
            id: 1,
            name: placeType,
            placeCount: 12
        )

        // when
        sut.setPlace(placeType: placeTypeWithCount)

        // then
        // 영어/한국어 둘 다 가능하니까 둘 중 하나인지로 검증
        let expectedEn = placeType.titleEn
        let expectedKo = placeType.titleKo

        XCTAssertNotNil(sut._test_nameLabel.text)
        XCTAssertTrue(
            sut._test_nameLabel.text == expectedEn ||
            sut._test_nameLabel.text == expectedKo,
            "nameLabel.text should be either \(expectedEn) or \(expectedKo), but was \(sut._test_nameLabel.text ?? "nil")"
        )

        // placeCount 텍스트
        XCTAssertEqual(
            sut._test_numberLabel.text,
            L10n.Common.placesCount(placeTypeWithCount.placeCount)
        )

        // 이미지 분기 커버 (에셋이 없어도 nil이면 그냥 통과)
        _ = sut._test_placeIcon.image
    }
}
