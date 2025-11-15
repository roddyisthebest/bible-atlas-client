//
//  NetworkError.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation

public struct ErrorResponse: Decodable, Equatable, Encodable {
    let message: String
    let error: String?
    let statusCode: Int?
}

public enum NetworkError:Error,Equatable {
    case urlError
    case invalid
    case failToDecode(String)
    case failToEncode(String)
    case dataNil
    case serverErrorWithMessage(ErrorResponse)
    case serverError(Int)
    case clientError(String)
    case failToJSONSerialize(String)
    
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.urlError, .urlError),
             (.invalid, .invalid),
             (.dataNil, .dataNil):
            return true
        case (.failToDecode(let l), .failToDecode(let r)),
             (.failToEncode(let l), .failToEncode(let r)),
             (.clientError(let l), .clientError(let r)),
             (.failToJSONSerialize(let l), .failToJSONSerialize(let r)):
            return l == r
        case (.serverError(let lCode), .serverError(let rCode)):
            return lCode == rCode
        case (.serverErrorWithMessage(let lRes), .serverErrorWithMessage(let rRes)):
            return lRes == rRes
        default:
            return false
        }
    }

    
    
    
    public var description: String {
        switch self {
        case .urlError:
            return L10n.NetworkError.urlError

        case .invalid:
            return L10n.NetworkError.invalid

        case .failToDecode(let desc):
            return L10n.NetworkError.failToDecode(desc)

        case .failToEncode(let desc):
            return L10n.NetworkError.failToEncode(desc)

        case .dataNil:
            return L10n.NetworkError.dataNil

        case .serverError(let statusCode):
            if statusCode == 401 {
                return L10n.NetworkError.unauthorized
            }
            return L10n.NetworkError.serverError(statusCode)

        case .serverErrorWithMessage(let errorResponse):
            return errorResponse.message

        case .clientError(let msg):
            return L10n.NetworkError.clientError(msg)

        case .failToJSONSerialize(let desc):
            return L10n.NetworkError.failToJSONSerialize(desc)
        }
    }

}


