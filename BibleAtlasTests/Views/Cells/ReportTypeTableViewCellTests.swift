//
//  ReportTypeTableViewCellTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
@testable import BibleAtlas

final class ReportTypeTableViewCellTests: XCTestCase {

    // MARK: - Helpers

    private func makeCell() -> ReportTypeTableViewCell {
        return ReportTypeTableViewCell(style: .default,
                                       reuseIdentifier: ReportTypeTableViewCell.identifier)
    }

    /// contentView 안에서 우리가 올린 UIStackView, UILabel, UIImageView를 꺼내오는 헬퍼
    private func extractSubviews(from cell: ReportTypeTableViewCell)
    -> (stackView: UIStackView, label: UILabel, icon: UIImageView) {

        // contentView에 추가된 stackView 찾기
        guard let stackView = cell.contentView.subviews.first(where: { $0 is UIStackView }) as? UIStackView else {
            fatalError("UIStackView not found in ReportTypeTableViewCell.contentView")
        }

        guard let label = stackView.arrangedSubviews.first(where: { $0 is UILabel }) as? UILabel else {
            fatalError("UILabel not found in stackView.arrangedSubviews")
        }

        guard let icon = stackView.arrangedSubviews.first(where: { $0 is UIImageView }) as? UIImageView else {
            fatalError("UIImageView not found in stackView.arrangedSubviews")
        }

        return (stackView, label, icon)
    }

    // MARK: - 기본 UI 구성 확인

    func test_init_addsStackViewAndSubviews() {
        // given
        let cell = makeCell()

        // when
        let (stackView, label, icon) = extractSubviews(from: cell)

        // then
        XCTAssertTrue(stackView is UIStackView)
        XCTAssertTrue(label is UILabel)
        XCTAssertTrue(icon is UIImageView)
    }

    // MARK: - setReportType 매핑 확인

    func test_setReportType_spam_setsCorrectTextAndCheckVisible() {
        // given
        let cell = makeCell()
        let (_, label, icon) = extractSubviews(from: cell)

        // when
        cell.setReportType(report: .spam, isCheck: true)

        // then
        XCTAssertEqual(label.text, L10n.PlaceReport.Types.spam)
        XCTAssertFalse(icon.isHidden)
    }

    func test_setReportType_inappropriate_setsCorrectText() {
        // given
        let cell = makeCell()
        let (_, label, _) = extractSubviews(from: cell)

        // when
        cell.setReportType(report: .inappropriate, isCheck: false)

        // then
        XCTAssertEqual(label.text, L10n.PlaceReport.Types.inappropriate)
    }

    func test_setReportType_hateSpeech_setsCorrectText() {
        // given
        let cell = makeCell()
        let (_, label, _) = extractSubviews(from: cell)

        // when
        cell.setReportType(report: .hateSpeech, isCheck: false)

        // then
        XCTAssertEqual(label.text, L10n.PlaceReport.Types.hateSpeech)
    }

    func test_setReportType_falseInformation_setsCorrectText() {
        // given
        let cell = makeCell()
        let (_, label, _) = extractSubviews(from: cell)

        // when
        cell.setReportType(report: .falseInfomation, isCheck: false)

        // then
        XCTAssertEqual(label.text, L10n.PlaceReport.Types.falseInfo)
    }

    func test_setReportType_personalInformation_setsCorrectText() {
        // given
        let cell = makeCell()
        let (_, label, _) = extractSubviews(from: cell)

        // when
        cell.setReportType(report: .personalInfomation, isCheck: false)

        // then
        XCTAssertEqual(label.text, L10n.PlaceReport.Types.personalInfo)
    }

    func test_setReportType_etc_setsCorrectText() {
        // given
        let cell = makeCell()
        let (_, label, _) = extractSubviews(from: cell)

        // when
        cell.setReportType(report: .etc, isCheck: false)

        // then
        XCTAssertEqual(label.text, L10n.PlaceReport.Types.etc)
    }

    // MARK: - 체크 아이콘 토글 확인

    func test_setReportType_togglesCheckIconVisibility() {
        // given
        let cell = makeCell()
        let (_, _, icon) = extractSubviews(from: cell)

        // when & then
        cell.setReportType(report: .spam, isCheck: true)
        XCTAssertFalse(icon.isHidden)

        cell.setReportType(report: .spam, isCheck: false)
        XCTAssertTrue(icon.isHidden)
    }
}
