//
//  ReportRepository.swift
//  BibleAtlas
//
//  Created by 배성연 on 11/15/25.
//

import Foundation

public struct ReportRepository:ReportRepositoryProtocol {
    let reportApiService:ReportApiServiceProtocol

    func createReport(comment: String, type: ReportType) async -> Result<Report, NetworkError> {
        return await reportApiService.createReport(comment: comment, type: type)
    }
    
}
