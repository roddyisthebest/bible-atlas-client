//
//  NetworkError.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation

public struct ErrorResponse: Decodable {
    let message: String
    let error: String?
    let statusCode: Int?
}

public enum NetworkError:Error {
    case urlError
    case invalid
    case failToDecode(String)
    case failToEncode(String)
    case dataNil
    case serverErrorWithMessage(ErrorResponse)
    case serverError(Int)
    case clientError(String)
    
    public var description: String {
        switch self {
        case .urlError:
            return "URL이 올바르지 않습니다."
        case .invalid:
            return "응답값이 유효하지 않습니다."
        case .failToDecode(let desc):
            return "디코딩 에러: \(desc)"
        case .failToEncode(let desc):
            return "엔코딩 에러: \(desc)"
        case .dataNil:
            return "데이터가 없습니다."
        case .serverError(let statusCode):
            return "서버에러: \(statusCode)"
        case .serverErrorWithMessage(let errorResponse):
            return errorResponse.message
        case .clientError(let msg):
            return "클라이언트에서 서버 요청 실패 \(msg)"
        }
    }
}
