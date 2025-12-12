//
//  MockAuthorizedApiClient.swift
//  BibleAtlasTests
//
//

import Foundation
import Alamofire
@testable import BibleAtlas

final class MockAuthorizedApiClient: AuthorizedApiClientProtocol {
    var lastRequestURL: String?
    var lastHeaders: HTTPHeaders?
    var lastBody: Data?
    var lastMethodCalled: HttpMethodCaptured!

    // 🔥 GET/POST/DELETE 각각에 쓸 수 있는 Any 결과
    var getResultAny: Any?
    var postResultAny: Any?
    var deleteResultAny: Any?

    var rawGetResult: Result<Data, NetworkError>?

    // 🔍 get 파라미터 추적
    var lastParameters: Parameters?

    init() {
        // 기존 Auth 테스트용 기본값 유지하고 싶다면 이렇게 놔둬도 되고,
        // Place 쪽에서는 테스트 내에서 항상 덮어쓸 거라 상관 없음
        postResultAny = Result<UserResponse, NetworkError>.failure(.invalid)
        deleteResultAny = Result<Int, NetworkError>.success(200)
    }

    // MARK: - POST

    func postData<T>(
        url: String,
        parameters: Parameters?,
        body: Data?,
        headers: HTTPHeaders?
    ) async -> Result<T, NetworkError> where T : Decodable {
        self.lastRequestURL = url
        self.lastBody = body
        self.lastHeaders = headers
        self.lastMethodCalled = .post

        if let typed = postResultAny as? Result<T, NetworkError> {
            return typed
        } else {
            return .failure(.invalid)
        }
    }

    // MARK: - GET

    func getData<T>(url: String, parameters: Parameters?) async -> Result<T, NetworkError> where T : Decodable {
        self.lastRequestURL = url
        self.lastParameters = parameters
        self.lastMethodCalled = .get

        if let typed = getResultAny as? Result<T, NetworkError> {
            return typed
        } else {
            return .failure(.invalid)
        }
    }

    // ✅ raw Data GET (GeoJSON 용)
     func getRawData(url: String, parameters: Parameters?) async -> Result<Data, NetworkError> {
         self.lastRequestURL = url
         self.lastParameters = parameters
         self.lastMethodCalled = .get  // 굳이 구분 필요 없으면 .get 재사용

         return rawGetResult ?? .failure(.invalid)
     }

    // MARK: - UPDATE

    func updateData<T>(
        url: String,
        method: HTTPMethod,
        parameters: Parameters?,
        body: Data?
    ) async -> Result<T, NetworkError> where T : Decodable {
        fatalError("updateData not used in PlaceApiService tests")
    }

    // MARK: - DELETE

    func deleteData<T>(url: String, parameters: Parameters?) async -> Result<T, NetworkError> where T : Decodable {
        lastRequestURL = url
        lastMethodCalled = .delete

        if let typed = deleteResultAny as? Result<T, NetworkError> {
            return typed
        } else {
            return .failure(.invalid)
        }
    }
}
