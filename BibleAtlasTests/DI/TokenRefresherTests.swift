//
//  TokenRefresherTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 2025/12/08.
//

import XCTest
import Alamofire
@testable import BibleAtlas


final class TokenRefresherTests: XCTestCase {

    private var mockSession: MockSession!
    private var mockTokenProvider: MockTokenProvider!
    private var sut: TokenRefresher!

    override func setUp() {
        super.setUp()
        mockSession = MockSession()
        mockTokenProvider = MockTokenProvider()
        sut = TokenRefresher(
            session: mockSession,
            tokenProvider: mockTokenProvider,
            refreshURL: "https://example.com/auth/refresh"
        )

        MockURLProtocol.statusCode = 200
        MockURLProtocol.responseData = nil
        MockURLProtocol.error = nil
    }

    override func tearDown() {
        sut = nil
        mockSession = nil
        mockTokenProvider = nil
        super.tearDown()
    }

    /// 1) refreshToken 이 없으면 곧장 .serverError(401) 리턴
    func test_refresh_withoutRefreshToken_returns401Error() async {
        // given
        mockTokenProvider.refreshToken = nil

        // when
        let result = await sut.refresh()

        // then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .serverError(let code):
            XCTAssertEqual(code, 401)
        default:
            XCTFail("Expected .serverError(401), got \(error)")
        }
    }

    /// 2) URL 형식이 잘못되면 .urlError
    func test_refresh_withInvalidURL_returnsUrlError() async {
        // given
        mockTokenProvider.refreshToken = "refresh-token"
        sut = TokenRefresher(
            session: mockSession,
            tokenProvider: mockTokenProvider,
            refreshURL: ""   // ✅ 이건 URL(string: "") == nil
        )

        // when
        let result = await sut.refresh()

        // then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .urlError:
            break // OK
        default:
            XCTFail("Expected .urlError, got \(error)")
        }
    }
    
    
    func test_refresh_withWeirdURL_returnsDataNil() async {
        // given
        mockTokenProvider.refreshToken = "refresh-token"
        sut = TokenRefresher(
            session: mockSession,
            tokenProvider: mockTokenProvider,
            refreshURL: "💩"
        )

        // when
        let result = await sut.refresh()

        // then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .dataNil:
            break // OK
        default:
            XCTFail("Expected .dataNil, got \(error)")
        }
    }



    /// 3) statusCode != 201 이고, ErrorResponse 디코딩 가능하면 .serverErrorWithMessage
    func test_refresh_serverError_decodesErrorResponse() async {
        // given
        mockTokenProvider.refreshToken = "refresh-token"

        let errorResponse = ErrorResponse(
            message: "Invalid refresh token", error: "error-network", statusCode: 400
        )
        
        let data = try! JSONEncoder().encode(errorResponse)

        MockURLProtocol.statusCode = 400
        MockURLProtocol.responseData = data

        // when
        let result = await sut.refresh()

        // then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .serverErrorWithMessage(let serverError):
            XCTAssertEqual(serverError.statusCode, 400)
            XCTAssertEqual(serverError.message, "Invalid refresh token")
        default:
            XCTFail("Expected .serverErrorWithMessage, got \(error)")
        }
    }

    /// 4) statusCode == 201 + 유효한 RefreshedData → success + accessToken 저장
    func test_refresh_success_decodesRefreshedDataAndUpdatesTokenProvider() async {
        // given
        mockTokenProvider.refreshToken = "old-refresh-token"

        let refreshed = RefreshedData(accessToken: "new-access-token")
        let data = try! JSONEncoder().encode(refreshed)

        MockURLProtocol.statusCode = 201
        MockURLProtocol.responseData = data

        // when
        let result = await sut.refresh()

        // then
        guard case .success(let returned) = result else {
            return XCTFail("Expected success, got \(result)")
        }

        XCTAssertEqual(returned.accessToken, "new-access-token")
        XCTAssertEqual(mockTokenProvider.accessToken, "new-access-token")
    }

    /// 5) statusCode == 201 이지만 JSON 구조가 RefreshedData 와 맞지 않으면 .failToDecode
    func test_refresh_decodingFails_returnsFailToDecode() async {
        // given
        mockTokenProvider.refreshToken = "refresh-token"

        let invalidJSON = ["foo": "bar"]
        let data = try! JSONSerialization.data(withJSONObject: invalidJSON)

        MockURLProtocol.statusCode = 201
        MockURLProtocol.responseData = data

        // when
        let result = await sut.refresh()

        // then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .failToDecode:
            break // OK
        default:
            XCTFail("Expected .failToDecode, got \(error)")
        }
    }

    /// 6) data 가 nil이면 .dataNil (statusCode 상관없이)
    func test_refresh_noData_returnsDataNil() async {
        // given
        mockTokenProvider.refreshToken = "refresh-token"
        MockURLProtocol.statusCode = 201
        MockURLProtocol.responseData = nil

        // when
        let result = await sut.refresh()

        // then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .dataNil:
            break
        default:
            XCTFail("Expected .dataNil, got \(error)")
        }
    }
}
