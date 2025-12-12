//
//  PopularPlaceTableViewCellTests.swift
//  BibleAtlasTests
//

import XCTest
@testable import BibleAtlas

final class PopularPlaceTableViewCellTests: XCTestCase {

    private var sut: PopularPlaceTableViewCell!

    override func setUp() {
        super.setUp()
        sut = PopularPlaceTableViewCell(style: .default,
                                        reuseIdentifier: PopularPlaceTableViewCell.identifier)
        sut.layoutIfNeeded()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 기본 텍스트 바인딩

    func test_setContent_setsNameAndLikeTexts() {
        // given
        let place = Place(
            id: "p1",
            name: "Jerusalem",
            koreanName: "예루살렘",
            isModern: false,
            description: "desc",
            koreanDescription: "k-desc",
            stereo: .child,
            likeCount: 42,
            types: []
        )

        // when
        sut.setCotent(place: place)

        // then
        XCTAssertEqual(sut._test_searchLabel.text, "Jerusalem")
        XCTAssertEqual(sut._test_likeLabel.text, "42 likes")
    }

    // MARK: - 타입이 1개일 때 분기 커버

    func test_setContent_withSingleType_runsSingleTypeBranch_withoutCrash() {
        // given
        let type = PlaceType(id: 1, name: .river)
        let place = Place(
            id: "p2",
            name: "Jordan",
            koreanName: "요단강",
            isModern: false,
            description: "desc",
            koreanDescription: "k-desc",
            stereo: .child,
            likeCount: 10,
            types: [type]
        )

        // when
        sut.setCotent(place: place)

        // then
        XCTAssertEqual(sut._test_searchLabel.text, "Jordan")
        XCTAssertEqual(sut._test_likeLabel.text, "10 likes")
        // 이미지 에셋은 없을 수 있으니 nil 이어도 상관 없음, 크래시만 안 나면 OK
        _ = sut._test_placeIcon.image
    }

    // MARK: - 타입이 0개일 때 else 분기

    func test_setContent_withZeroTypes_goesToElseBranch() {
        // given
        let place = Place(
            id: "p3",
            name: "Unknown place",
            koreanName: "알 수 없는 장소",
            isModern: false,
            description: "desc",
            koreanDescription: "k-desc",
            stereo: .child,
            likeCount: 0,
            types: []
        )

        // when
        sut.setCotent(place: place)

        // then
        XCTAssertEqual(sut._test_searchLabel.text, "Unknown place")
        XCTAssertEqual(sut._test_likeLabel.text, "0 likes")
        _ = sut._test_placeIcon.image
    }

    // MARK: - 타입이 여러 개일 때 else 분기

    func test_setContent_withMultipleTypes_goesToElseBranch() {
        // given
        let types = [
            PlaceType(id: 1, name: .river),
            PlaceType(id: 2, name: .mountain) // 실제 enum에 맞게 수정
        ]
        let place = Place(
            id: "p4",
            name: "Mixed place",
            koreanName: "복합 장소",
            isModern: false,
            description: "desc",
            koreanDescription: "k-desc",
            stereo: .child,
            likeCount: 5,
            types: types
        )

        // when
        sut.setCotent(place: place)

        // then
        XCTAssertEqual(sut._test_searchLabel.text, "Mixed place")
        XCTAssertEqual(sut._test_likeLabel.text, "5 likes")
        _ = sut._test_placeIcon.image
    }
}
