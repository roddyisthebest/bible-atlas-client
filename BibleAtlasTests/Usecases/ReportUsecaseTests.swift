//
//  ReportUsecaseTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/7/25.
//

import XCTest
@testable import BibleAtlas

final class ReportUsecaseTests: XCTestCase {

    private var sut: ReportUsecase!
    private var mockRepository: MockReportRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockReportRepository()
        sut = ReportUsecase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func test_createReport_delegatesToRepository_andReturnsResult() async {
        // given
        let expectedComment = "앱에서 발견한 버그 제보"
        let expectedType: ReportType = .bugReport  

        // 여기서는 실패 케이스로 세팅 (Report 구조 몰라도 됨)
        let expectedError: NetworkError = .failToJSONSerialize("test error")
        mockRepository.resultToReturn = .failure(expectedError)

        // when
        let result = await sut.createReport(comment: expectedComment, type: expectedType)

        // then: 레포지토리가 정확히 한 번 호출되고, 인자도 제대로 전달됐는지 확인
        XCTAssertEqual(mockRepository.callCount, 1)
        XCTAssertEqual(mockRepository.receivedComment, expectedComment)
        XCTAssertEqual(mockRepository.receivedType, expectedType)

        // 결과도 그대로 흘러가는지만 확인 (케이스만 체크해도 충분)
        switch result {
        case .failure:
            // expectedError와 동일한 케이스라는 것까지만 보면 충분
            break
        case .success:
            XCTFail("Expected failure, but got success")
        }
    }
}
