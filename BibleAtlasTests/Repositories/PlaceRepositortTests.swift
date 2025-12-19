//
//  PlaceRepositoryTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
@testable import BibleAtlas

final class PlaceRepositoryTests: XCTestCase {
    
    private var sut: PlaceRepository!
    private var mockApiService: MockPlaceApiService!
    
    override func setUp() {
        super.setUp()
        mockApiService = MockPlaceApiService()
        sut = PlaceRepository(placeApiService: mockApiService)
    }
    
    override func tearDown() {
        sut = nil
        mockApiService = nil
        super.tearDown()
    }
    
    // MARK: - getPlacesWithRepresentativePoint
    
    func test_getPlacesWithRepresentativePoint_delegatesToApiService() async {
        // when
        let result = await sut.getPlacesWithRepresentativePoint()
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["getPlacesWithRepresentativePoint"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    // MARK: - getPlaceTypes
    
    func test_getPlaceTypes_delegatesToApiService() async {
        // given
        let limit = 10
        let page = 2
        
        // when
        let result = await sut.getPlaceTypes(limit: limit, page: page)
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["getPlaceTypes"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    // MARK: - getPrefixs
    
    func test_getPrefixs_delegatesToApiService() async {
        // when
        let result = await sut.getPrefixs()
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["getPrefixs"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    // MARK: - getBibleBookCounts
    
    func test_getBibleBookCounts_delegatesToApiService() async {
        // when
        let result = await sut.getBibleBookCounts()
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["getBibleBookCounts"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    // MARK: - getPlace
    
    func test_getPlace_delegatesToApiService() async {
        // given
        let placeId = "test-place-id"
        
        // when
        let result = await sut.getPlace(placeId: placeId)
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["getPlace"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    // MARK: - getRelatedUserInfo
    
    func test_getRelatedUserInfo_delegatesToApiService() async {
        // given
        let placeId = "test-place-id"
        
        // when
        let result = await sut.getRelatedUserInfo(placeId: placeId)
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["getRelatedUserInfo"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    // MARK: - toggleSave
    
    func test_toggleSave_delegatesToApiService() async {
        // given
        let placeId = "test-place-id"
        
        // when
        let result = await sut.toggleSave(placeId: placeId)
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["toggleSave"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    // MARK: - toggleLike
    
    func test_toggleLike_delegatesToApiService() async {
        // given
        let placeId = "test-place-id"
        
        // when
        let result = await sut.toggleLike(placeId: placeId)
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["toggleLike"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    // MARK: - createOrUpdatePlaceMemo
    
    func test_createOrUpdatePlaceMemo_delegatesToApiService() async {
        // given
        let placeId = "test-place-id"
        let text = "memo-text"
        
        // when
        let result = await sut.createOrUpdatePlaceMemo(placeId: placeId, text: text)
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["createOrUpdatePlaceMemo"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    // MARK: - deletePlaceMemo
    
    func test_deletePlaceMemo_delegatesToApiService() async {
        // given
        let placeId = "test-place-id"
        
        // when
        let result = await sut.deletePlaceMemo(placeId: placeId)
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["deletePlaceMemo"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    // MARK: - createPlaceProposal
    
    func test_createPlaceProposal_delegatesToApiService() async {
        // given
        let placeId = "test-place-id"
        let comment = "proposal-comment"
        
        // when
        let result = await sut.createPlaceProposal(placeId: placeId, comment: comment)
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["createPlaceProposal"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    // MARK: - createPlaceReport
    
    func test_createPlaceReport_delegatesToApiService() async {
        // given
        let placeId = "test-place-id"
        // 아무 enum 하나 사용 (실제 PlaceReportType 케이스에 맞게 수정해도 됨)
        let reportType: PlaceReportType = .falseInfomation
        let reason = "wrong data"
        
        // when
        let result = await sut.createPlaceReport(placeId: placeId,
                                                 reportType: reportType,
                                                 reason: reason)
        
        // then
        XCTAssertEqual(mockApiService.calledMethods, ["createPlaceReport"])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    
    // MARK: - getBibleVerse
    
    func test_getBibleVerse_delegatesToApiService() async {
        let result = await sut.getBibleVerse(
            version: .kor, // 실제 enum 케이스
            book: "Gen",
            chapter: "1",
            verse: "1"
        )

        XCTAssertEqual(mockApiService.calledMethods, ["getBibleVerse"])

        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }
    
    
    // MARK: - getPlaces

    func test_getPlaces_delegatesToApiService() async {
        // given
        let params = PlaceParameters()

        // when
        let result = await sut.getPlaces(parameters: params)

        // then
        XCTAssertEqual(mockApiService.calledMethods, ["getPlaces"])

        if case .failure(let error) = result {
            XCTAssertEqual(error, .clientError("test"))
        } else {
            XCTFail("Expected failure, but got success")
        }
    }

}
