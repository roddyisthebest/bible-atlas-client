//
//  NetworkManager.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation
import Alamofire


struct ListResponse<T:Decodable>:Decodable{
    let total:Int
    let page:Int
    let limit:Int
    let data:[T]
}



protocol AuthorizedApiClientProtocol{
    func getData<T: Decodable>(url:String, parameters:Parameters?) async -> Result<T,NetworkError>
    func postData<T: Decodable>(url:String, parameters:Parameters?, body:Data?, headers:HTTPHeaders?) async -> Result<T,NetworkError>
    func updateData<T: Decodable>(url:String, method: HTTPMethod, parameters:Parameters?, body:Data?) async -> Result<T,NetworkError>
    func deleteData<T: Decodable>(url:String, parameters:Parameters?) async -> Result<T,NetworkError>
}


public final class AuthorizedApiClient:AuthorizedApiClientProtocol{
    
    private let session:SessionProtocol
    private let tokenProvider:TokenProviderProtocol
    
    init(session: SessionProtocol, tokenProvider: TokenProviderProtocol) {
        self.session = session
        self.tokenProvider = tokenProvider;
    }
    
    
    private var tokenHeaders: HTTPHeaders {
        guard let accessToken = tokenProvider.accessToken else {
            return HTTPHeaders()
        }
        
        return HTTPHeaders([.authorization(bearerToken: accessToken)])
    }
    
    
    
    /// ✅ API 요청을 수행하는 공통 메서드
    private func performRequest<T: Decodable>(
        url: String,
        method: HTTPMethod,
        parameters: Parameters?,
        body: Data?,
        headers: HTTPHeaders? = nil
    ) async -> Result<T, NetworkError> {
           
           guard let url = URL(string: url) else {
               return .failure(.urlError)
           }
           
           let result = await session.request(
               url,
               method: method,
               parameters: parameters,
               headers: headers ?? tokenHeaders,
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
               // 💥 서버 에러 응답 디코딩 시도
               if let serverError = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    return .failure(.serverErrorWithMessage(serverError))
                 }
               else {
                   if let jsonString = String(data: data, encoding: .utf8) {
                        print("📦 서버 에러 원본 데이터:\n\(jsonString)")
                   }
                    return .failure(.serverError(response.statusCode))
                }
           }
       }
    
    
       // MARK: - API 호출 메서드
    
    
       func getData<T: Decodable>(url: String, parameters: Parameters?) async -> Result<T, NetworkError> {
           return await performRequest(url: url, method: .get, parameters: parameters, body: nil)
       }
       
       func postData<T: Decodable>(url: String, parameters: Parameters?, body: Data?, headers:HTTPHeaders?) async -> Result<T, NetworkError> {
            return await performRequest(url: url, method: .post, parameters: parameters, body: body, headers:headers)
       }
    
//        func postWithBasicAuth<T: Decodable>(
//            url: String,
//            parameters: Parameters?,
//            username: String,
//            password: String
//        ) async -> Result<T, NetworkError> {
//            let credential = "\(username):\(password)"
//            guard let base64 = credential.data(using: .utf8)?.base64EncodedString() else {
//                return .failure(.clientError("Invalid credentials"))
//            }
//
//            let headers: HTTPHeaders = [
//                "Authorization": "Basic \(base64)"
//            ]
//
//            return await performRequest(
//                url: url,
//                method: .post,
//                parameters: parameters,
//                body: nil,
//                headers: headers
//            )
//    }
       
       func updateData<T: Decodable>(url: String, method: HTTPMethod, parameters: Parameters?, body: Data?) async -> Result<T, NetworkError> {
           return await performRequest(url: url, method: method, parameters: parameters, body: body)
       }
       
       func deleteData<T: Decodable>(url: String, parameters: Parameters?) async -> Result<T, NetworkError> {
           return await performRequest(url: url, method: .delete, parameters: parameters, body: nil)
       }
    
}
