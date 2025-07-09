//
//  MockingApi.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import Foundation
import OHHTTPStubs


func setupMockAPI() {
    // ✅ GET 요청: api.example.com/user
    stub(condition: isHost("api.example.com")) { _ in
        let stubData = """
        {
            "id": 1,
            "name": "John Doe",
            "imageURL": "https://example.com/avatar.png",
            "grade": "king"
        }
        """.data(using: .utf8)!

        return HTTPStubsResponse(
            data: stubData,
            statusCode: 200,
            headers: ["Content-Type": "application/json"]
        )
    }
    
    // ✅ POST 요청: api.bible-atlas.com/auth/login
    stub(condition: isHost("api.bible-atlas.com") && isPath("/auth/login") && isMethodPOST()) { request in
        // 요청 바디(JSON)를 읽어서 유효한지 검사
        guard let requestBody = request.ohhttpStubs_httpBody,
              let jsonObject = try? JSONSerialization.jsonObject(with: requestBody, options: []) as? [String: Any],
              let userId = jsonObject["userId"] as? String,
              let password = jsonObject["password"] as? String else {
            return HTTPStubsResponse(jsonObject: ["message": "Invalid request"], statusCode: 400, headers: nil)
        }
        
        // 예제: 특정 계정만 로그인 성공 처리
        if userId == "one" && password == "one" {
            let responseJSON = [
                "authData": [
                    "accessToken": "mock_access_token_123",
                    "refreshToken": "mock_refresh_token_456",
                ],
                "user": [
                    "id": 1,
                    "name": "John Doe",
                    "imageURL": "https://example.com/avatar.png",
                    "grade": "king"
                ]
            ]
            return HTTPStubsResponse(jsonObject: responseJSON, statusCode: 200, headers: ["Content-Type": "application/json"])
        } else {
            return HTTPStubsResponse(jsonObject: ["message": "Invalid credentials"], statusCode: 401, headers: nil)
        }
    }
}
