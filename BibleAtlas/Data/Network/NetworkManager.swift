//
//  NetworkManager.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation
import Alamofire

protocol NetworkManagerProtocol{
    func getData<T: Decodable>(url:String, parameters:Parameters?) async -> Result<T,NetworkError>
    func postData<T: Decodable>(url:String, parameters:Parameters?, body:Data?) async -> Result<T,NetworkError>
    func updateData<T: Decodable>(url:String, method: HTTPMethod, parameters:Parameters?, body:Data?) async -> Result<T,NetworkError>
    func deleteData<T: Decodable>(url:String, parameters:Parameters?) async -> Result<T,NetworkError>
}


public final class NetworkManager:NetworkManagerProtocol{
    
    private let session:SessionProtocol
    private let authManager:AuthManagerProtocol
    
    init(session: SessionProtocol, authManager: AuthManagerProtocol) {
        self.session = session
        self.authManager = authManager;
    }
    
    // TODO: 후에 토큰 설정 로직 개선 필요
    // 계속 갱신할 필요 있을듯
    
    private lazy var tokenHeaders:HTTPHeaders = {
        
        guard let accessToken = authManager.accessToken else{
            return HTTPHeaders();
        }
        
        let header = HTTPHeader(name:"Authorization", value:"Bearer \(accessToken)");
        
        return HTTPHeaders([header]);
    }();
    
    
    /// ✅ API 요청을 수행하는 공통 메서드
    private func performRequest<T: Decodable>(
        url: String,
        method: HTTPMethod,
        parameters: Parameters?,
        body: Data?
    ) async -> Result<T, NetworkError> {
           
           guard let url = URL(string: url) else {
               return .failure(.urlError)
           }
           
           let result = await session.request(
               url,
               method: method,
               parameters: parameters,
               headers: tokenHeaders,
               body: body
           ).serializingData().response
           
           return handleResponse(result)
       }
       
       /// ✅ 응답 처리 및 디코딩
       private func handleResponse<T: Decodable>(_ result: AFDataResponse<Data>) -> Result<T, NetworkError> {
           if let error = result.error {
               return .failure(.clientError(error.localizedDescription))
           }
           
           guard let data = result.data else {
               return .failure(.dataNil)
           }
           
           guard let response = result.response else {
               return .failure(.invalid)
           }
           

           
           if (200..<400).contains(response.statusCode) {
               do {
                   let decodedData = try JSONDecoder().decode(T.self, from: data)
                   return .success(decodedData)
               } catch {
                   return .failure(.failToDecode(error.localizedDescription))
               }
           } else {
               return .failure(.serverError(response.statusCode))
           }
       }
    
    
       // MARK: - API 호출 메서드
       
       func getData<T: Decodable>(url: String, parameters: Parameters?) async -> Result<T, NetworkError> {
           return await performRequest(url: url, method: .get, parameters: parameters, body: nil)
       }
       
       func postData<T: Decodable>(url: String, parameters: Parameters?, body: Data?) async -> Result<T, NetworkError> {
           return await performRequest(url: url, method: .post, parameters: parameters, body: body)
       }
       
       func updateData<T: Decodable>(url: String, method: HTTPMethod, parameters: Parameters?, body: Data?) async -> Result<T, NetworkError> {
           return await performRequest(url: url, method: method, parameters: parameters, body: body)
       }
       
       func deleteData<T: Decodable>(url: String, parameters: Parameters?) async -> Result<T, NetworkError> {
           return await performRequest(url: url, method: .delete, parameters: parameters, body: nil)
       }
    
}
