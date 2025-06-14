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
    let page:Int?
    let limit:Int?
    let data:[T]
}



protocol AuthorizedApiClientProtocol{
    func getData<T: Decodable>(url:String, parameters:Parameters?) async -> Result<T,NetworkError>
    func getRawData(url: String, parameters: Parameters?) async -> Result<Data, NetworkError>
    func postData<T: Decodable>(url:String, parameters:Parameters?, body:Data?, headers:HTTPHeaders?) async -> Result<T,NetworkError>
    func updateData<T: Decodable>(url:String, method: HTTPMethod, parameters:Parameters?, body:Data?) async -> Result<T,NetworkError>
    func deleteData<T: Decodable>(url:String, parameters:Parameters?) async -> Result<T,NetworkError>
}


public final class AuthorizedApiClient:AuthorizedApiClientProtocol{
    private let session:SessionProtocol
    private let tokenProvider:TokenProviderProtocol
    private let tokenRefresher: TokenRefresherProtocol
    private let errorHandlerService: ErrorHandlerServiceProtocol

    init(session: SessionProtocol, tokenProvider: TokenProviderProtocol, tokenRefresher:TokenRefresherProtocol, errorHandlerService: ErrorHandlerServiceProtocol) {
        self.session = session
        self.tokenProvider = tokenProvider;
        self.tokenRefresher = tokenRefresher;
        self.errorHandlerService = errorHandlerService
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
           headers: HTTPHeaders? = nil,
           retrying: Bool = false
       ) async -> Result<T, NetworkError> {
           guard let url = URL(string: url) else {
               return .failure(.urlError)
           }
           
           

           var finalHeaders = tokenHeaders
           if let headers = headers {
               headers.forEach { finalHeaders.update($0) }
           }

           let response = await session.request(
               url,
               method: method,
               parameters: parameters,
               headers: finalHeaders,
               body: body
           ).serializingData().response

           if response.response?.statusCode == 401, !retrying {
               let refreshResult = await tokenRefresher.refresh()
               
               switch refreshResult {
               case .success(let result):
                   print("refresh!")
                   tokenProvider.setAccessToken(accessToken: result.accessToken)

                   return await performRequest(
                       url: url.absoluteString,
                       method: method,
                       parameters: parameters,
                       body: body,
                       headers: headers ?? tokenHeaders,
                       retrying: true
                   )

               case .failure:
                   await errorHandlerService.logoutDueToExpiredSession()
                   return .failure(.serverError(401))
               }
           }

           return handleResponse(response)
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
               }
               catch let decodingError as DecodingError {
                      print(String(describing: decodingError))
                       return .failure(.failToDecode(String(describing: decodingError)))
            }
               catch {
                   
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
    
    
    /// ✅ 응답 처리 및 디코딩
    private func handleRawResponse(_ result: AFDataResponse<Data>) -> Result<Data, NetworkError> {
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
            return .success(data)
        } else {
            if let jsonString = String(data: data, encoding: .utf8) {
                 print("📦 서버 에러 원본 데이터:\n\(jsonString)")
            }
             return .failure(.serverError(response.statusCode))
        }
    }
 
    
    
       // MARK: - API 호출 메서드
    
    
       func getData<T: Decodable>(url: String, parameters: Parameters?) async -> Result<T, NetworkError> {
           return await performRequest(url: url, method: .get, parameters: parameters, body: nil)
       }
       
       func postData<T: Decodable>(url: String, parameters: Parameters?, body: Data?, headers:HTTPHeaders?) async -> Result<T, NetworkError> {
            return await performRequest(url: url, method: .post, parameters: parameters, body: body, headers:headers)
       }
    
       
       func updateData<T: Decodable>(url: String, method: HTTPMethod, parameters: Parameters?, body: Data?) async -> Result<T, NetworkError> {
           return await performRequest(url: url, method: method, parameters: parameters, body: body)
       }
       
       func deleteData<T: Decodable>(url: String, parameters: Parameters?) async -> Result<T, NetworkError> {
           return await performRequest(url: url, method: .delete, parameters: parameters, body: nil)
       }
    
    
       func getRawData(url: String, parameters: Parameters?) async -> Result<Data, NetworkError> {
           guard let url = URL(string: url) else {
               return .failure(.urlError)
           }
           
           let response = await session.request(url, method: .get, parameters: nil, headers: nil, body: nil).serializingData().response
            
           
           return handleRawResponse(response)
           
           
       }
    
}
