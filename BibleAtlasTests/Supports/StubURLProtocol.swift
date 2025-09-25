//
//  StubURLProtocol.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import Foundation

final class StubURLProtocol: URLProtocol {
    struct Stub {
        let statusCode: Int
        let headers: [String: String]?
        let data: Data?
        let error: Error?
    }

    // URL별로 여러 응답을 큐처럼 쌓아두고 순서대로 소진
    static var queue: [URL: [Stub]] = [:]

    static func enqueue(url: URL, stub: Stub) {
        var arr = queue[url] ?? []
        arr.append(stub)
        queue[url] = arr
    }

    static func reset() {
        queue.removeAll()
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }

        var arr = StubURLProtocol.queue[url] ?? []
        let stub = arr.isEmpty ? Stub(statusCode: 200, headers: nil, data: Data(), error: nil) : arr.removeFirst()
        StubURLProtocol.queue[url] = arr

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: stub.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: stub.headers
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
