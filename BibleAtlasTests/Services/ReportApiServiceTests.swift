//
//  ReportApiServiceTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/9/25.
//

import XCTest
import Alamofire
@testable import BibleAtlas

final class ReportApiServiceTests: XCTestCase {

    private var mockApiClient: MockAuthorizedApiClient!
    private var sut: ReportApiService!

    private let baseURL = "https://api.example.com"

    override func setUp() {
        super.setUp()
        mockApiClient = MockAuthorizedApiClient()
        sut = ReportApiService(apiClient: mockApiClient, url: baseURL)
    }

    override func tearDown() {
        sut = nil
        mockApiClient = nil
        super.tearDown()
    }

    /// createReport 가:
    /// - 올바른 URL로 POST 요청을 보내고
    /// - JSON body 에 comment / type 이 잘 들어가며
    /// - Content-Type 헤더를 포함하고
    /// - ApiClient 의 결과를 그대로 전달하는지 검증
    func test_createReport_sendsCorrectRequest_andForwardsFailure() async throws {
        // given
        let comment = "이 앱 정말 좋아요"
        let type: ReportType = .other

        // ApiClient가 실패를 리턴하도록 세팅
        mockApiClient.postResultAny = Result<Report, NetworkError>.failure(.clientError("test-error"))

        // when
        let result = await sut.createReport(comment: comment, type: type)

        // then: URL / 메서드
        XCTAssertEqual(mockApiClient.lastRequestURL, "\(baseURL)/report")
        XCTAssertEqual(mockApiClient.lastMethodCalled, .post)

        // then: 헤더
        XCTAssertEqual(mockApiClient.lastHeaders?["Content-Type"], "application/json")

        // then: body JSON 확인
        guard let bodyData = mockApiClient.lastBody else {
            return XCTFail("Body should not be nil")
        }

        let jsonObject = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: String]
        XCTAssertEqual(jsonObject?["comment"], comment)
        XCTAssertEqual(jsonObject?["type"], type.rawValue)

        // then: 결과가 그대로 포워딩되는지 (여기선 실패 케이스 확인)
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .clientError(let message):
            XCTAssertEqual(message, "test-error")
        default:
            XCTFail("Expected .clientError, got \(error)")
        }
    }
}
