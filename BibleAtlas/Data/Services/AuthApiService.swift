//
//  AuthNetworkManager.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation
import Alamofire



protocol AuthApiServiceProtocol{
    func loginUser(body:AuthPayload) async -> Result<UserResponse,NetworkError>
    
    func loginGoogleUser(idToken: String) async -> Result<UserResponse,NetworkError>

}

final public class AuthApiService:AuthApiServiceProtocol {


    private let apiClient: AuthorizedApiClientProtocol;
    private let url: String;
    
    init(apiClient: AuthorizedApiClientProtocol, url:String) {
        self.apiClient = apiClient
        self.url = url;
    }
    
    func loginUser(body:AuthPayload) async -> Result<UserResponse, NetworkError> {
            
            let credential = "\(body.userId):\(body.password)";
            
            guard let base64 = credential.data(using: .utf8)?.base64EncodedString() else {
                return .failure(.failToEncode("Invalid credentials"))
            }
            
            let headers: HTTPHeaders = [
                "Authorization": "Basic \(base64)"
            ]
            
            return await apiClient.postData(url: "\(url)/login", parameters: nil, body: nil, headers: headers)
    
    }
    
    func loginGoogleUser(idToken: String) async -> Result<UserResponse, NetworkError> {
            let body: [String: String] = [
                "idToken": idToken
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
                return .failure(.failToEncode("Invalid JSON"))
            }
            
            return await apiClient.postData(
                url: "\(url)/google-login",
                parameters: nil,
                body: jsonData,
                headers: ["Content-Type": "application/json"]
            )
    }
    

    
    

 
    
    
}
