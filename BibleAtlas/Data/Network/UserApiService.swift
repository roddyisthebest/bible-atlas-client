//
//  UserApiService.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/19/25.
//

import Foundation
import Alamofire

protocol UserApiServiceProtocol{
    func getProfile() async -> Result<User,NetworkError>
}


final public class UserApiService:UserApiServiceProtocol {
    private let apiClient:AuthorizedApiClientProtocol;
    private let url:String
}
