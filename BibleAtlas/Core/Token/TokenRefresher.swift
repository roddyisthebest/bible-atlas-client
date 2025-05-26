//
//  TokenRefresher.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/26/25.
//

import Foundation
import Alamofire

final class TokenRefresher:TokenRefresherProtocol {
    private let session: SessionProtocol
    private let tokenProvider: TokenProviderProtocol
    private let refreshURL: String
    
    
    init(
        session: SessionProtocol,
        tokenProvider: TokenProviderProtocol,
        refreshURL: String
    ) {
        self.session = session
        self.tokenProvider = tokenProvider
        self.refreshURL = refreshURL
    }
    
    
    func refresh() async -> Result<RefreshedData, NetworkError> {
        guard let refreshToken = tokenProvider.refreshToken else {
            return .failure(.serverError(401))
        }
        
        
        guard let url = URL(string: refreshURL) else {
                  return .failure(.urlError)
        }
        
        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        
        let bodyDict: [String: String] = ["refreshToken": refreshToken]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict) else {
            return .failure(.clientError("Invalid JSON body"))
        }
        
        
        let response = await session.request(
                 url,
                 method: .post,
                 parameters: nil,
                 headers: headers,
                 body:bodyData
                ).serializingData().response
        
        guard let data = response.data else {
            return .failure(.dataNil)
        }
        
        guard response.response?.statusCode == 201 else {
            guard let statusCode = response.response?.statusCode else {
                return .failure(.dataNil)
            }
            
                
            if let serverError = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                 return .failure(.serverErrorWithMessage(serverError))
              }
            else {
                if let jsonString = String(data: data, encoding: .utf8) {
                     print("📦 서버 에러 원본 데이터:\n\(jsonString)")
                }
                return .failure(.serverError(statusCode))
             }
            
         }
        
        do {
               let decoded = try JSONDecoder().decode(RefreshedData.self, from: data)
                tokenProvider.setAccessToken(accessToken: decoded.accessToken)
    
                return .success(decoded)
           } catch {
               return .failure(.failToDecode(error.localizedDescription))
           }
        
    }
    
}
