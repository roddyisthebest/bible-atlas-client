//
//  ReportUsecase.swift
//  BibleAtlas
//
//  Created by 배성연 on 11/15/25.
//

import Foundation

protocol ReportUsecaseProtocol {
    func createReport(comment:String, type:ReportType) async -> Result<Report, NetworkError>
}


public struct ReportUsecase:ReportUsecaseProtocol {
    let repository: ReportRepositoryProtocol
    
    func createReport(comment: String, type: ReportType) async -> Result<Report, NetworkError> {
        await repository.createReport(comment: comment, type: type)
    }
    
}
