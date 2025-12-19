//
//  UserRepositoryTests.swift
//  BibleAtlasTests
//

import XCTest
@testable import BibleAtlas

final class UserRepositoryTests: XCTestCase {
    
    private var mockService: MockUserApiService!
    private var sut: UserRepository!   // System Under Test
    
    override func setUp() {
        super.setUp()
        mockService = MockUserApiService()
        sut = UserRepository(userApiService: mockService)
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    private func makeDummyPlace(id: String = "1") -> Place {

        return Place(
            id: id,
            name: "Place \(id)",
            koreanName: "장소 \(id)",
            isModern: true,
            description: "desc \(id)",
            koreanDescription: "한글 desc \(id)",
            stereo: .child,
            likeCount: 0,
            types: []
        )
    }
    
    // MARK: - getPlaces
    
    func test_getPlaces_forwardsParametersAndReturnsSuccess() async {
        // given
        let place = makeDummyPlace(id: "10")
        let response = ListResponse(
            total: 30,
            page: 1,
            limit: 10,
            data: [place]
        )
        
        mockService.getPlacesResult = .success(response)
        
        // when
        let result = await sut.getPlaces(limit: 10, page: 1, filter: .save)
        
        // then
        XCTAssertTrue(mockService.getPlacesCalled)
        XCTAssertEqual(mockService.lastGetPlacesLimit, 10)
        XCTAssertEqual(mockService.lastGetPlacesPage, 1)
        XCTAssertEqual(mockService.lastGetPlacesFilter, .save)
        
        switch result {
        case .success(let res):
            XCTAssertEqual(res.total, 30)
            XCTAssertEqual(res.page, 1)
            XCTAssertEqual(res.limit, 10)
            XCTAssertEqual(res.data.first?.id, "10")
        case .failure(let error):
            XCTFail("Expected success, got failure: \(error)")
        }
    }
    
    func test_getPlaces_propagatesFailureFromService() async {
        // given
        mockService.getPlacesResult = .failure(.clientError("stub error"))
        
        // when
        let result = await sut.getPlaces(limit: nil, page: nil, filter: nil)
        
        // then
        XCTAssertTrue(mockService.getPlacesCalled)
        
        switch result {
        case .success:
            XCTFail("Expected failure, got success")
        case .failure(let error):
            if case .clientError(let message) = error {
                XCTAssertEqual(message, "stub error")
            } else {
                XCTFail("Expected .clientError, got \(error)")
            }
        }
    }
    
    // MARK: - getMyCollectionPlaceIds
    
    func test_getMyCollectionPlaceIds_returnsServiceResult_success() async {
        // given
        // MyCollectionPlaceIds 구조에 맞게 수정해서 써줘
        let dummy = MyCollectionPlaceIds(
            liked: ["1", "2"],
            bookmarked: ["3"],
            memoed: []
        )
        mockService.getMyCollectionResult = .success(dummy)
        
        // when
        let result = await sut.getMyCollectionPlaceIds()
        
        // then
        XCTAssertTrue(mockService.getMyCollectionCalled)
        
        switch result {
        case .success(let value):
            XCTAssertEqual(value.liked.count,2 )
            XCTAssertEqual(value.bookmarked.count, 1)
        case .failure(let error):
            XCTFail("Expected success, got failure: \(error)")
        }
    }
    
    func test_getMyCollectionPlaceIds_propagatesFailureFromService() async {
        // given
        mockService.getMyCollectionResult = .failure(.clientError("collection error"))
        
        // when
        let result = await sut.getMyCollectionPlaceIds()
        
        // then
        XCTAssertTrue(mockService.getMyCollectionCalled)
        
        switch result {
        case .success:
            XCTFail("Expected failure, got success")
        case .failure(let error):
            if case .clientError(let message) = error {
                XCTAssertEqual(message, "collection error")
            } else {
                XCTFail("Expected .clientError, got \(error)")
            }
        }
    }
    
    // MARK: - getProfile
    
    func test_getProfile_returnsServiceResult_success() async {
        // given
        let user = User(id: 1, role: .EXPERT, avatar: "userAvatar")
        mockService.getProfileResult = .success(user)
        
        // when
        let result = await sut.getProfile()
        
        // then
        XCTAssertTrue(mockService.getProfileCalled)
        
        switch result {
        case .success(let user):
            XCTAssertEqual(user.id, 1)
            XCTAssertEqual(user.role, .EXPERT)
            
        case .failure(let error):
            XCTFail("Expected success, got failure: \(error)")
        }
    }
    
    func test_getProfile_propagatesFailureFromService() async {
        // given
        mockService.getProfileResult = .failure(.clientError("profile error"))
        
        // when
        let result = await sut.getProfile()
        
        // then
        XCTAssertTrue(mockService.getProfileCalled)
        
        switch result {
        case .success:
            XCTFail("Expected failure, got success")
        case .failure(let error):
            if case .clientError(let msg) = error {
                XCTAssertEqual(msg, "profile error")
            } else {
                XCTFail("Expected .clientError, got \(error)")
            }
        }
    }
}
