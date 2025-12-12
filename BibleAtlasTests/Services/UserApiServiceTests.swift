//
//  UserApiServiceTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/9/25.
//

import XCTest
import Alamofire
@testable import BibleAtlas

final class UserApiServiceTests: XCTestCase {

    private var mockApiClient: MockAuthorizedApiClient!
    private var sut: UserApiService!   // System Under Test
    private let baseURL = "https://api.example.com"

    override func setUp() {
        super.setUp()
        mockApiClient = MockAuthorizedApiClient()
        sut = UserApiService(apiClient: mockApiClient, url: baseURL)
    }

    override func tearDown() {
        sut = nil
        mockApiClient = nil
        super.tearDown()
    }

    // MARK: - getPlaces

    /// limit / page / filter 를 모두 넣어줬을 때
    /// URL과 파라미터가 기대대로 들어가는지
    func test_getPlaces_buildsCorrectURLAndParameters_whenAllArgumentsProvided() async {
        // given
        let dummyPlaces = [
            Place.mock(id: "1", name: "A"),
            Place.mock(id: "2", name: "B")
        ]

        let response = ListResponse(
            total: dummyPlaces.count,
            page: 3,
            limit: 20,
            data: dummyPlaces
        )

        // getData<T> 가 이 결과를 반환하도록 설정
        mockApiClient.getResultAny = Result<ListResponse<Place>, NetworkError>.success(response)

        // when
        let result = await sut.getPlaces(limit: 20, page: 3, filter: .memo)

        // then
        // 1) URL
        XCTAssertEqual(mockApiClient.lastRequestURL, "\(baseURL)/me/places")

        // 2) Parameters
        guard let params = mockApiClient.lastParameters else {
            return XCTFail("Parameters should not be nil")
        }

        XCTAssertEqual(params["limit"] as? Int, 20)
        XCTAssertEqual(params["page"] as? Int, 3)
        XCTAssertEqual(params["filter"] as? String, PlaceFilter.memo.rawValue)

        // 3) Result 전달 여부
        guard case .success(let list) = result else {
            return XCTFail("Expected success, got \(result)")
        }
        XCTAssertEqual(list.total, 2)
        XCTAssertEqual(list.data.map { $0.id }, ["1", "2"])
    }

    /// limit / page / filter 가 nil 이면
    /// limit=1, page=0, filter=.like 으로 디폴트가 적용되는지
    func test_getPlaces_usesDefaultValues_whenArgumentsNil() async {
        // given
        let dummyPlaces = [
            Place.mock(id: "10", name: "X")
        ]

        let response = ListResponse(
            total: dummyPlaces.count,
            page: 0,
            limit: 1,
            data: dummyPlaces
        )

        mockApiClient.getResultAny = Result<ListResponse<Place>, NetworkError>.success(response)

        // when
        let result = await sut.getPlaces(limit: nil, page: nil, filter: nil)

        // then
        guard let params = mockApiClient.lastParameters else {
            return XCTFail("Parameters should not be nil")
        }

        // 기본값 확인
        XCTAssertEqual(params["limit"] as? Int, 1)
        XCTAssertEqual(params["page"] as? Int, 0)
        XCTAssertEqual(params["filter"] as? String, PlaceFilter.like.rawValue)

        guard case .success(let list) = result else {
            return XCTFail("Expected success, got \(result)")
        }
        XCTAssertEqual(list.total, 1)
        XCTAssertEqual(list.data.first?.id, "10")
    }

    /// getPlaces 가 실패할 경우, NetworkError 가 그대로 전달되는지
    func test_getPlaces_propagatesFailureFromApiClient() async {
        // given
        mockApiClient.getResultAny =
            Result<ListResponse<Place>, NetworkError>.failure(.clientError("test-error"))

        // when
        let result = await sut.getPlaces(limit: 5, page: 1, filter: .save)

        // then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .clientError(let message):
            XCTAssertEqual(message, "test-error")
        default:
            XCTFail("Expected clientError, got \(error)")
        }
    }

    // MARK: - getMyCollectionPlaceIds

    func test_getMyCollectionPlaceIds_callsCorrectURLAndReturnsResult() async {
        // given
        // ⚠️ MyCollectionPlaceIds 구조에 맞게 채워줘야 함
        // 예시: MyCollectionPlaceIds(likePlaceIds: ["1"], savePlaceIds: ["2"], memoPlaceIds: ["3"])
        let dummy = MyCollectionPlaceIds(
            liked: ["1"],
            bookmarked: ["2"],
            memoed: ["3"]
        )

        mockApiClient.getResultAny = Result<MyCollectionPlaceIds, NetworkError>.success(dummy)

        // when
        let result = await sut.getMyCollectionPlaceIds()

        // then
        XCTAssertEqual(mockApiClient.lastRequestURL, "\(baseURL)/me/collection-place-ids")

        guard case .success(let value) = result else {
            return XCTFail("Expected success, got \(result)")
        }

        XCTAssertEqual(value.liked, ["1"])
        XCTAssertEqual(value.bookmarked, ["2"])
        XCTAssertEqual(value.memoed, ["3"])
    }

    func test_getMyCollectionPlaceIds_propagatesFailure() async {
        // given
        mockApiClient.getResultAny =
            Result<MyCollectionPlaceIds, NetworkError>.failure(.serverError(500))

        // when
        let result = await sut.getMyCollectionPlaceIds()

        // then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .serverError(let code):
            XCTAssertEqual(code, 500)
        default:
            XCTFail("Expected serverError(500), got \(error)")
        }
    }

    // MARK: - getProfile

    func test_getProfile_callsCorrectURLAndReturnsResult() async {
        // given
        // ⚠️ User 구조에 맞게 더미 데이터 채워줘야 함
        // 예시: User(id: "u1", name: "tester", email: "a@b.com", ...)
        let dummyUser = User(id: 1, role: .EXPERT, avatar: "avatar1")

        mockApiClient.getResultAny = Result<User, NetworkError>.success(dummyUser)

        // when
        let result = await sut.getProfile()

        // then
        XCTAssertEqual(mockApiClient.lastRequestURL, "\(baseURL)/me")

        guard case .success(let user) = result else {
            return XCTFail("Expected success, got \(result)")
        }

        XCTAssertEqual(user.id, dummyUser.id)
    }

    func test_getProfile_propagatesFailure() async {
        // given
        mockApiClient.getResultAny =
            Result<User, NetworkError>.failure(.invalid)

        // when
        let result = await sut.getProfile()

        // then
        guard case .failure(let error) = result else {
            return XCTFail("Expected failure, got \(result)")
        }

        switch error {
        case .invalid:
            break // OK
        default:
            XCTFail("Expected .invalid, got \(error)")
        }
    }
}
