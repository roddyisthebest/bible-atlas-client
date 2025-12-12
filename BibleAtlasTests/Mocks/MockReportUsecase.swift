//
//  MockReportUsecase.swift
//  BibleAtlasTests
//

import Foundation
@testable import BibleAtlas

final class MockReportUsecase: ReportUsecaseProtocol {
    
    private(set) var receivedComments: [String] = []
    private(set) var receivedTypes: [ReportType] = []
    
    var resultToReturn: Result<Report, NetworkError> = .failure(.clientError("no stub"))
    
    func createReport(comment: String, type: ReportType) async -> Result<Report, NetworkError> {
        receivedComments.append(comment)
        receivedTypes.append(type)
        return resultToReturn
    }
}
