//
//  PlaceCharacterCellTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/7/25.
//

import XCTest
@testable import BibleAtlas

final class PlaceCharacterCellTests: XCTestCase {

    // MARK: - Helpers

    private func makeSUT(frame: CGRect = CGRect(x: 0, y: 0, width: 100, height: 100)) -> PlaceCharacterCell {
        let cell = PlaceCharacterCell(frame: frame)
        cell.layoutIfNeeded()
        return cell
    }

    /// 뷰 계층에서 UILabel 전부 모으는 헬퍼
    private func findAllLabels(in view: UIView) -> [UILabel] {
        var result: [UILabel] = []
        if let label = view as? UILabel {
            result.append(label)
        }
        for sub in view.subviews {
            result.append(contentsOf: findAllLabels(in: sub))
        }
        return result
    }

    // MARK: - init / layout

    func test_init_setsUpStackViewHierarchy() {
        // given
        let cell = makeSUT()

        // when
        let stackViews = cell.contentView.subviews.compactMap { $0 as? UIStackView }

        // then: 컨테이너 스택뷰가 최소 하나는 있어야 함
        XCTAssertFalse(stackViews.isEmpty, "PlaceCharacterCell should have a UIStackView in contentView")

        // 그리고 그 스택 뷰 안에 최소 2개의 arrangedSubviews(iconWrapper + numberLabel)가 있어야 함
        guard let containerStack = stackViews.first else {
            return XCTFail("Container stack view not found")
        }
        XCTAssertGreaterThanOrEqual(
            containerStack.arrangedSubviews.count,
            2,
            "Container stack view should have at least 2 arranged subviews (iconWrapper, numberLabel)"
        )
    }

    // MARK: - setPlaceCharacter

    func test_setPlaceCharacter_setsCharacterAndCountText() {
        // given
        let cell = makeSUT()
        let prefix = PlacePrefix(prefix: "a", placeCount: "3")

        // when
        cell.setPlaceCharacter(placeCharacter: prefix)
        cell.layoutIfNeeded()

        let labels = findAllLabels(in: cell.contentView)

        // then: characterLabel에는 "A"가 들어가야 함 (uppercased)
        let characterLabel = labels.first(where: { $0.text == "A" })
        XCTAssertNotNil(characterLabel, "characterLabel should display prefix.uppercased()")

        // numberLabel에는 "3"과 "place" 관련 문자열이 들어가야 함
        // (L10n.Common.placesCount(3) -> "3 places" 같은 형식이라고 가정)
        let numberLabel = labels.first(where: { $0.text?.contains("3") == true })
        XCTAssertNotNil(numberLabel, "numberLabel should include the placeCount number")

        // 가능하면 "place" 단어까지 체크 (영문 기준)
        XCTAssertEqual(numberLabel?.text, L10n.Common.placesCount(3))

    }

    func test_setPlaceCharacter_withInvalidCount_fallsBackToZero() {
        // given: placeCount가 숫자가 아닐 때 -> Int(...) ?? 0 이므로 0 places 가 되어야 함
        let cell = makeSUT()
        let prefix = PlacePrefix(prefix: "b", placeCount: "abc")

        // when
        cell.setPlaceCharacter(placeCharacter: prefix)
        cell.layoutIfNeeded()

        let labels = findAllLabels(in: cell.contentView)

        // "B"가 characterLabel에 들어가야 함
        let characterLabel = labels.first(where: { $0.text == "B" })
        XCTAssertNotNil(characterLabel, "characterLabel should display prefix.uppercased() for invalid count as well")

        // count는 0 으로 포맷되었는지 확인
        let numberLabel = labels.first(where: { $0.text?.contains("0") == true })
        XCTAssertNotNil(numberLabel, "numberLabel should fall back to 0 when placeCount cannot be parsed as Int")
    }
}
