//
//  MockingApiTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
import OHHTTPStubs
@testable import BibleAtlas

final class MockingApiTests: XCTestCase {

    override func setUp() {
        super.setUp()
        HTTPStubs.removeAllStubs()
        // 여기서 우리가 만든 스텁 등록
        setupMockAPI()
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    // MARK: - GET api.example.com (user)

    func test_getUser_fromExampleDotCom_returnsStubbedJSON() {
        // given
        let url = URL(string: "https://api.example.com/user")!
        let request = URLRequest(url: url)
        let exp = expectation(description: "GET /user stubbed response")

        // when
        var receivedData: Data?
        var receivedStatusCode: Int?

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            receivedData = data
            receivedStatusCode = (response as? HTTPURLResponse)?.statusCode
            exp.fulfill()
        }
        task.resume()

        // then
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedStatusCode, 200)

        XCTAssertNotNil(receivedData)
        if let data = receivedData,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertEqual(json["id"] as? Int, 1)
            XCTAssertEqual(json["name"] as? String, "John Doe")
            XCTAssertEqual(json["imageURL"] as? String, "https://example.com/avatar.png")
            XCTAssertEqual(json["grade"] as? String, "king")
        } else {
            XCTFail("Failed to decode JSON from stubbed /user response")
        }
    }

    // MARK: - POST api.bible-atlas.com/auth/login (성공 케이스)

    func test_login_success_returnsTokensAndUser() {
        // given
        let url = URL(string: "https://api.bible-atlas.com/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": "one",
            "password": "one"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let exp = expectation(description: "POST /auth/login success stub")

        // when
        var receivedData: Data?
        var receivedStatusCode: Int?

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            receivedData = data
            receivedStatusCode = (response as? HTTPURLResponse)?.statusCode
            exp.fulfill()
        }
        task.resume()

        // then
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedStatusCode, 200)

        XCTAssertNotNil(receivedData)
        if let data = receivedData,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            let authData = json["authData"] as? [String: Any]
            let user = json["user"] as? [String: Any]

            XCTAssertEqual(authData?["accessToken"] as? String, "mock_access_token_123")
            XCTAssertEqual(authData?["refreshToken"] as? String, "mock_refresh_token_456")

            XCTAssertEqual(user?["id"] as? Int, 1)
            XCTAssertEqual(user?["name"] as? String, "John Doe")
            XCTAssertEqual(user?["imageURL"] as? String, "https://example.com/avatar.png")
            XCTAssertEqual(user?["grade"] as? String, "king")
        } else {
            XCTFail("Failed to decode JSON from stubbed /auth/login success response")
        }
    }

    // MARK: - POST api.bible-atlas.com/auth/login (실패 케이스)

    func test_login_invalidCredentials_returns401() {
        // given
        let url = URL(string: "https://api.bible-atlas.com/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 실패하는 계정
        let body: [String: Any] = [
            "userId": "wrong",
            "password": "wrong"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let exp = expectation(description: "POST /auth/login failure stub")

        // when
        var receivedData: Data?
        var receivedStatusCode: Int?

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            receivedData = data
            receivedStatusCode = (response as? HTTPURLResponse)?.statusCode
            exp.fulfill()
        }
        task.resume()

        // then
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedStatusCode, 401)

        XCTAssertNotNil(receivedData)
        if let data = receivedData,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertEqual(json["message"] as? String, "Invalid credentials")
        } else {
            XCTFail("Failed to decode JSON from stubbed /auth/login failure response")
        }
    }
}
