//
//  AlamofireSessionAdapter.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import Alamofire
@testable import BibleAtlas

/// 네가 정의한 SessionProtocol에 실제 Alamofire.Session을 감싼 어댑터
final class AlamofireSessionAdapter: SessionProtocol {
    private let session: Alamofire.Session

    init(session: Alamofire.Session) {
        self.session = session
    }

    func request(
        _ convertible: URLConvertible,
        method: HTTPMethod,
        parameters: Parameters?,
        headers: HTTPHeaders?,
        body: Data?
    ) -> DataRequest {
        // URLRequest를 직접 구성해서 body/headers까지 주입
        var url = try! convertible.asURL()
        var req = URLRequest(url: url)
        req.method = method
        if let headers { req.headers = headers }
        if let body { req.httpBody = body }

        // parameters는 body/쿼리 어디에 실을지 정책에 따라 선택
        // 여기선 GET이면 쿼리스트링, 그 외엔 body가 이미 있으니 생략
        if let parameters, method == .get {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            let items = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            comps.queryItems = (comps.queryItems ?? []) + items
            url = comps.url!
            req.url = url
        }

        return session.request(req)
    }
}
