//
//  BibleBookCellTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
import UIKit
@testable import BibleAtlas

final class BibleBookCellTests: XCTestCase {

    func test_setBibleBook_setsLabelsCorrectly() {
        // given
        let cell = BibleBookCell(frame: .zero)

        // 실제 enum 케이스 하나 사용 (프로젝트에서 사용하는 거면 무엇이든 상관 없음)
        let bibleBook: BibleBook = .Acts
        let placeCount = 7
        let bibleBookCount = BibleBookCount(bible: bibleBook, placeCount: placeCount)

        let expectedName = bibleBook.title()
        let expectedTwoChars = String(
            bibleBook.code
                .uppercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(2)
        )
        let expectedPlacesText = L10n.Common.placesCount(placeCount)

        // when
        cell.setBibleBook(bibleBookCount: bibleBookCount)
        cell.layoutIfNeeded()

        // then
        // nameLabel 검증
        let nameLabel = findLabel(in: cell.contentView) { label in
            label.text == expectedName
        }
        XCTAssertNotNil(nameLabel, "nameLabel 이 기대한 제목(\(expectedName))으로 설정되어야 합니다.")

        // numberLabel 검증
        let numberLabel = findLabel(in: cell.contentView) { label in
            label.text == expectedPlacesText
        }
        XCTAssertNotNil(numberLabel, "numberLabel 이 기대한 place count 텍스트(\(expectedPlacesText))로 설정되어야 합니다.")

        // bibleBookLabel 검증 (2글자 코드)
        let codeLabel = findLabel(in: cell.contentView) { label in
            label.text == expectedTwoChars
        }
        XCTAssertNotNil(codeLabel, "bibleBookLabel 이 기대한 코드(\(expectedTwoChars))로 설정되어야 합니다.")
    }

    // MARK: - Helpers

    /// view 트리 안에서 조건을 만족하는 UILabel 하나 찾아주는 헬퍼
    private func findLabel(in view: UIView, where predicate: (UILabel) -> Bool) -> UILabel? {
        if let label = view as? UILabel, predicate(label) {
            return label
        }
        for subview in view.subviews {
            if let found = findLabel(in: subview, where: predicate) {
                return found
            }
        }
        return nil
    }
}
