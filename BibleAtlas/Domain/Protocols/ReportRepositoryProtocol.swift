//
//  ReportRepositoryProtocol.swift
//  BibleAtlas
//
//  Created by 배성연 on 11/15/25.
//

import Foundation

protocol ReportRepositoryProtocol{
    func createReport(comment:String, type:ReportType) async -> Result<Report, NetworkError>
}
