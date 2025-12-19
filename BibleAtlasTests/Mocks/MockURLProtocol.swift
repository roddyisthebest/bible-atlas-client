//
//  TokenRefresherTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 2025/12/08.
//

import XCTest
import Alamofire
@testable import BibleAtlas

// MARK: - URLProtocol 스텁

final class MockURLProtocol: URLProtocol {

    /// 리턴할 HTTP status code
    static var statusCode: Int = 200

    /// 리턴할 Data
    static var responseData: Data? = nil

    /// 네트워크 에러 강제 발생용
    static var error: Error? = nil

    override class func canInit(with request: URLRequest) -> Bool {
        // 모든 요청 가로채기
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let error = MockURLProtocol.error {
            // 에러 응답
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: MockURLProtocol.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if let data = MockURLProtocol.responseData {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // no-op
    }
}
