//
//  MockReportRepository.swift
//  BibleAtlasTests
//

import Foundation
@testable import BibleAtlas

final class MockReportRepository: ReportRepositoryProtocol {

    // 호출 기록용
    private(set) var callCount: Int = 0
    private(set) var receivedComment: String?
    private(set) var receivedType: ReportType?

    // 테스트에서 주입할 결과
    var resultToReturn: Result<Report, NetworkError>!

    func createReport(comment: String, type: ReportType) async -> Result<Report, NetworkError> {
        callCount += 1
        receivedComment = comment
        receivedType = type
        return resultToReturn
    }
}
