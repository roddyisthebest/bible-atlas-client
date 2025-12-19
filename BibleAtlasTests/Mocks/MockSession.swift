//
//  TokenRefresherTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 2025/12/08.
//

import XCTest
import Alamofire
@testable import BibleAtlas

// MARK: - SessionProtocol 구현용 MockSession

final class MockSession: SessionProtocol {
    private let session: Session

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        self.session = Session(configuration: config)
    }

    func request(
        _ convertible: URLConvertible,
        method: HTTPMethod,
        parameters: Parameters?,
        headers: HTTPHeaders?,
        body: Data?
    ) -> DataRequest {
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
