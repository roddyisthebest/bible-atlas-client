//
//  ReportService.swift
//  BibleAtlas
//
//  Created by 배성연 on 11/15/25.
//

import Foundation
import Alamofire

protocol ReportApiServiceProtocol {
    func createReport(comment:String, type: ReportType) async -> Result<Report,NetworkError>
}

final class ReportApiService:ReportApiServiceProtocol {
    private let apiClient: AuthorizedApiClientProtocol
    private let url: String
        
    init(apiClient: AuthorizedApiClientProtocol, url: String) {
        self.apiClient = apiClient
        self.url = url
    }
    
    
    func createReport(comment: String, type:ReportType = .other) async -> Result<Report, NetworkError> {
        let json: [String: String] = ["comment": comment, "type": type.rawValue]
        
        guard let body = try? JSONSerialization.data(withJSONObject: json, options: []) else {
             return .failure(.failToJSONSerialize("json 직렬화 에러"))
        }
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        return await apiClient.postData(url: "\(url)/report", parameters: nil, body: body, headers: headers)
        
    }
    
    
    
}
