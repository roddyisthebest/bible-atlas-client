//
//  MockReportApiService.swift
//  BibleAtlasTests
//

import Foundation
@testable import BibleAtlas

final class MockReportApiService: ReportApiServiceProtocol {

    // 호출 여부 & 인자 기록용
    private(set) var receivedComment: String?
    private(set) var receivedType: ReportType?
    private(set) var callCount: Int = 0

    // 테스트에서 주입할 결과값
    var resultToReturn: Result<Report, NetworkError> = .failure(.failToJSONSerialize("stub"))

    func createReport(comment: String, type: ReportType) async -> Result<Report, NetworkError> {
        callCount += 1
        receivedComment = comment
        receivedType = type
        return resultToReturn
    }
}
