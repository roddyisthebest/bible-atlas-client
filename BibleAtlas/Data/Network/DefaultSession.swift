//
//  DefaultSession.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation
import Alamofire




protocol SessionProtocol{
    func request(_ convertible: URLConvertible, method:HTTPMethod, parameters:Parameters?, headers:HTTPHeaders?, body:Data?) -> DataRequest
}

class DefaultSession: SessionProtocol {
    private var session:Session
    
    init(){
        let config = URLSessionConfiguration.default;
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = Session(configuration: config);
    }
    
    
    func request(_ convertible: URLConvertible,method:HTTPMethod = .get, parameters:Parameters? = nil, headers:HTTPHeaders? = nil, body:Data? = nil) -> DataRequest{
        var urlRequest = try! URLRequest(url: convertible, method: method, headers: headers)

        if let parameters = parameters {
            if method == .get {
                urlRequest = try! URLEncoding.default.encode(urlRequest, with: parameters)
            } else {
                  urlRequest = try! JSONEncoding.default.encode(urlRequest, with: parameters)
            }
        }
        
        if let body = body {
           urlRequest.httpBody = body
        }
              
        
        return session.request(urlRequest)
    }
}


