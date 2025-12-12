//
//  UserUsecaseTests.swift
//  BibleAtlasTests
//

import XCTest
@testable import BibleAtlas

final class UserUsecaseTests: XCTestCase {

    private var mockRepository: MockUserRepository!
    private var sut: UserUsecase!

    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        sut = UserUsecase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func test_getPlaces_callsRepositoryWithCorrectParams() async {
        // given
        let places = [
            Place.mock(id: "1", name: "A"),
            Place.mock(id: "2", name: "B")
        ]

        mockRepository.getPlacesResult = .success(
            ListResponse(total: 2, page: 0, limit: 10, data: places)
        )

        // when
        let result = await sut.getPlaces(limit: 10, page: 0, filter: .save)

        // then
        XCTAssertTrue(mockRepository.isGetPlacesCalled)
        XCTAssertEqual(mockRepository.capturedLimit, 10)
        XCTAssertEqual(mockRepository.capturedPage, 0)
        XCTAssertEqual(mockRepository.capturedFilter, .save)

        guard case .success(let response) = result else {
            return XCTFail("Expected success, got \(result)")
        }

        XCTAssertEqual(response.total, 2)
    }

    func test_getProfile_callsRepository() async {
        // given
        let dummyUser = User(id: 1, role: .EXPERT, avatar: "avatar1")
        mockRepository.getProfileResult = .success(dummyUser)

        // when
        let result = await sut.getProfile()

        // then
        XCTAssertTrue(mockRepository.isGetProfileCalled)

        guard case .success(let user) = result else {
            return XCTFail("Expected success, got \(result)")
        }
        XCTAssertEqual(user.id, dummyUser.id)
    }

    func test_getMyCollectionPlaceIds_callsRepository() async {
        // given
        let dummyIds = MyCollectionPlaceIds(
            liked: ["1"],
            bookmarked: ["2"],
            memoed: ["3"]
        )

        mockRepository.getMyCollectionPlaceIdsResult = .success(dummyIds)

        // when
        let result = await sut.getMyCollectionPlaceIds()

        // then
        XCTAssertTrue(mockRepository.isGetMyCollectionPlaceIdsCalled)

        guard case .success(let ids) = result else {
            return XCTFail("Expected success, got \(result)")
        }

        XCTAssertEqual(ids.liked, ["1"])
    }
}
