//
//  ReportRepositoryTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/7/25.
//

import XCTest
@testable import BibleAtlas

final class ReportRepositoryTests: XCTestCase {

    private var sut: ReportRepository!
    private var mockApiService: MockReportApiService!

    override func setUp() {
        super.setUp()
        mockApiService = MockReportApiService()
        // 멤버와이즈 init 사용
        sut = ReportRepository(reportApiService: mockApiService)
    }

    override func tearDown() {
        sut = nil
        mockApiService = nil
        super.tearDown()
    }

    /// createReport가 내부적으로 ReportApiService에 위임하는지 + 결과를 그대로 리턴하는지 검증
    func test_createReport_delegatesToApiService_andReturnsResult() async {
        // given
        let expectedComment = "버그가 있어요"
        let expectedType: ReportType = .bugReport   // enum에 맞추어 변경

        // 여기서는 에러 케이스로 세팅 (Report 구조 모를 때도 안전)
        let expectedError: NetworkError = .failToJSONSerialize("dummy error")
        mockApiService.resultToReturn = .failure(expectedError)

        // when
        let result = await sut.createReport(comment: expectedComment, type: expectedType)

        // then: ApiService가 정확히 한 번 호출되고, 인자도 맞는지
        XCTAssertEqual(mockApiService.callCount, 1)
        XCTAssertEqual(mockApiService.receivedComment, expectedComment)
        XCTAssertEqual(mockApiService.receivedType, expectedType)

        // 그리고 Repository가 결과를 그대로 되돌려주는지 확인
        switch result {
        case .failure(let error):
            // NetworkError가 Equatable이 아닐 수 있어서, 케이스 기준으로만 비교
            switch (error, expectedError) {
            case (.failToJSONSerialize(let lhsMsg), .failToJSONSerialize(let rhsMsg)):
                XCTAssertEqual(lhsMsg, rhsMsg)
            default:
                XCTFail("Expected failToJSONSerialize error, got \(error)")
            }
        case .success:
            XCTFail("Expected failure, but got success")
        }
    }
}
