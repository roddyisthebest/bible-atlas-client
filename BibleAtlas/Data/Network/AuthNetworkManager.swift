//
//  AuthNetworkManager.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation



protocol AuthNetworkManagerProtocol{
    func loginUser(body:AuthPayload) async -> Result<UserResponse,NetworkError>
    func logout() async -> Result<Bool,NetworkError>
}

final public class AuthNetworkManager:AuthNetworkManagerProtocol {

    private let manager: NetworkManagerProtocol;
    private let url: String;
    
    init(manager: NetworkManagerProtocol, url:String) {
        self.manager = manager
        self.url = url;
    }
    
    func loginUser(body:AuthPayload) async -> Result<UserResponse, NetworkError> {
        do{

            let jsonBody = try JSONEncoder().encode(body);
            return await manager.postData(url: "\(url)/login", parameters: nil, body: jsonBody)
            
        }
        catch{
            return .failure(.failToEncode(error.localizedDescription))
        }
    }
    
    func logout() async -> Result<Bool, NetworkError> {
        return await manager.postData(url: "\(url)/logout", parameters: nil, body: nil)
    }
    
}
