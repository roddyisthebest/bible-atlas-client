//
//  PlaceApiServiceTests.swift
//  BibleAtlasTests
//

import XCTest
import Alamofire
@testable import BibleAtlas

final class PlaceApiServiceTests: XCTestCase {

    private var mockClient: MockAuthorizedApiClient!
    private var sut: PlaceApiService!
    private let baseURL = "https://api.example.com"

    override func setUp() {
        super.setUp()
        mockClient = MockAuthorizedApiClient()
        sut = PlaceApiService(apiClient: mockClient, url: baseURL)
    }

    override func tearDown() {
        sut = nil
        mockClient = nil
        super.tearDown()
    }

    // MARK: - toggleSave

    func test_toggleSave_callsCorrectURLAndMethod() async {
        // given
        mockClient.postResultAny = Result<TogglePlaceSaveResponse, NetworkError>.failure(.invalid)

        // when
        _ = await sut.toggleSave(placeId: "P1")

        // then
        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place/P1/save")
        XCTAssertEqual(mockClient.lastMethodCalled, .post)
        XCTAssertNil(mockClient.lastBody)
        XCTAssertNil(mockClient.lastHeaders)   // 헤더 없음
    }

    // MARK: - toggleLike

    func test_toggleLike_callsCorrectURLAndMethod() async {
        // given
        mockClient.postResultAny = Result<TogglePlaceLikeResponse, NetworkError>.failure(.invalid)

        // when
        _ = await sut.toggleLike(placeId: "P2")

        // then
        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place/P2/like")
        XCTAssertEqual(mockClient.lastMethodCalled, .post)
        XCTAssertNil(mockClient.lastBody)
        XCTAssertNil(mockClient.lastHeaders)
    }

    // MARK: - createOrUpdatePlaceMemo

    func test_createOrUpdatePlaceMemo_buildsJSONBodyAndHeaders() async {
        // given
        mockClient.postResultAny = Result<PlaceMemoResponse, NetworkError>.failure(.invalid)

        // when
        _ = await sut.createOrUpdatePlaceMemo(placeId: "P100", text: "hello memo")

        // then
        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place/P100/memo")
        XCTAssertEqual(mockClient.lastMethodCalled, .post)

        // 헤더 확인
        XCTAssertEqual(mockClient.lastHeaders?["Content-Type"], "application/json")

        // body JSON 확인
        guard
            let body = mockClient.lastBody,
            let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        else {
            XCTFail("Body must be valid JSON")
            return
        }

        XCTAssertEqual(json["text"] as? String, "hello memo")
    }

    // MARK: - createPlaceProposal

    func test_createPlaceProposal_buildsCorrectBodyAndHeaders() async {
        // given
        mockClient.postResultAny = Result<PlaceProposalResponse, NetworkError>.failure(.invalid)

        // when
        _ = await sut.createPlaceProposal(placeId: "P200", comment: "수정 제안입니다")

        // then
        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/proposal")
        XCTAssertEqual(mockClient.lastMethodCalled, .post)
        XCTAssertEqual(mockClient.lastHeaders?["Content-Type"], "application/json")

        guard
            let body = mockClient.lastBody,
            let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        else {
            XCTFail("Body must be valid JSON")
            return
        }

        XCTAssertEqual(json["placeId"] as? String, "P200")
        XCTAssertEqual(json["comment"] as? String, "수정 제안입니다")
        XCTAssertEqual(json["type"] as? String, "2")
    }

    // MARK: - deletePlaceMemo

    func test_deletePlaceMemo_callsCorrectURLAndMethod() async {
        // given
        mockClient.deleteResultAny = Result<PlaceMemoDeleteResponse, NetworkError>.failure(.invalid)

        // when
        _ = await sut.deletePlaceMemo(placeId: "PX")

        // then
        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place/PX/memo")
        XCTAssertEqual(mockClient.lastMethodCalled, .delete)
    }

    // MARK: - createPlaceReport

    func test_createPlaceReport_buildsCorrectJSON() async {
        // given
        mockClient.postResultAny = Result<Int, NetworkError>.success(201)

        // when
        _ = await sut.createPlaceReport(
            placeId: "PR1",
            reportType: .etc,      // 네 enum에 맞춰서 수정
            reason: "중복 데이터로 보여요"
        )

        // then
        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place-report")
        XCTAssertEqual(mockClient.lastMethodCalled, .post)
        XCTAssertEqual(mockClient.lastHeaders?["Content-Type"], "application/json")

        guard
            let body = mockClient.lastBody,
            let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        else {
            XCTFail("Body must be valid JSON")
            return
        }

        XCTAssertEqual(json["placeId"] as? String, "PR1")
        XCTAssertEqual(json["reason"] as? String, "중복 데이터로 보여요")
        XCTAssertEqual(json["type"] as? String, String(PlaceReportType.etc.rawValue))
    }
    
    
    func test_getPlaces_buildsCorrectURLAndParameters() async {
        // given
        let params = PlaceParameters(
            limit: 10,
            page: 2,
            placeTypeName: .river,          // 실제 enum 이름에 맞게 수정
            name: "Jordan",
            prefix: "J",
            sort: .asc,                 // 실제 enum에 맞게 수정
            bible: .Acts                 // 실제 BibleBook 케이스로 수정
        )

        let dummyList = ListResponse(
            total: 1,
            page: 2,
            limit: 10,
            data: [Place.mock(id: "1", name: "Jordan River")]
        )
        mockClient.getResultAny = Result<ListResponse<Place>, NetworkError>.success(dummyList)

        // when
        _ = await sut.getPlaces(parameters: params)

        // then
        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place")
        XCTAssertEqual(mockClient.lastMethodCalled, .get)

        guard let sent = mockClient.lastParameters else {
            return XCTFail("Parameters should not be nil")
        }

        XCTAssertEqual(sent["limit"] as? Int, 10)
        XCTAssertEqual(sent["page"] as? Int, 2)
        XCTAssertEqual(sent["name"] as? String, "Jordan")
        XCTAssertEqual(sent["prefix"] as? String, "J")
        XCTAssertEqual(sent["placeTypes"] as? String, PlaceTypeName.river.rawValue)
        XCTAssertEqual(sent["sort"] as? String, PlaceSort.asc.rawValue)
        XCTAssertEqual(sent["bibleBook"] as? String, BibleBook.Acts.rawValue)
    }

    func test_getPlaces_omitsNilParameters() async {
        // given
        let params = PlaceParameters(
            limit: nil,
            page: nil,
            placeTypeName: nil,
            name: nil,
            prefix: nil,
            sort: nil,
            bible: nil
        )

        mockClient.getResultAny = Result<ListResponse<Place>, NetworkError>.failure(.invalid)

        // when
        _ = await sut.getPlaces(parameters: params)

        // then
        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place")
        XCTAssertEqual(mockClient.lastMethodCalled, .get)

        // limit/page/name/... 전부 nil이면 파라미터 딕셔너리는 비어있어야 함
        XCTAssertTrue((mockClient.lastParameters ?? [:]).isEmpty)
    }

    // MARK: - getPlacesWithRepresentativePoint

    func test_getPlacesWithRepresentativePoint_callsCorrectURL() async {
        mockClient.getResultAny = Result<ListResponse<Place>, NetworkError>.failure(.invalid)

        _ = await sut.getPlacesWithRepresentativePoint()

        XCTAssertEqual(
            mockClient.lastRequestURL,
            "\(baseURL)/place/with-representative-point"
        )
        XCTAssertEqual(mockClient.lastMethodCalled, .get)
        XCTAssertNil(mockClient.lastParameters)
    }

    // MARK: - getPlaceTypes

    func test_getPlaceTypes_usesGivenLimitAndPage() async {
        mockClient.getResultAny = Result<ListResponse<PlaceTypeWithPlaceCount>, NetworkError>
            .failure(.invalid)

        _ = await sut.getPlaceTypes(limit: 30, page: 3)

        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place-type")
        XCTAssertEqual(mockClient.lastMethodCalled, .get)

        guard let sent = mockClient.lastParameters else {
            return XCTFail("parameters nil")
        }

        XCTAssertEqual(sent["limit"] as? Int, 30)
        XCTAssertEqual(sent["page"] as? Int, 3)
    }

    func test_getPlaceTypes_usesDefaultWhenNil() async {
        mockClient.getResultAny = Result<ListResponse<PlaceTypeWithPlaceCount>, NetworkError>
            .failure(.invalid)

        _ = await sut.getPlaceTypes(limit: nil, page: nil)

        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place-type")
        XCTAssertEqual(mockClient.lastMethodCalled, .get)

        guard let sent = mockClient.lastParameters else {
            return XCTFail("parameters nil")
        }

        // 코드상 page ?? 0, limit ?? 1 이므로
        XCTAssertEqual(sent["limit"] as? Int, 1)
        XCTAssertEqual(sent["page"] as? Int, 0)
    }

    // MARK: - getPrefixs

    func test_getPrefixs_callsCorrectURL() async {
        mockClient.getResultAny = Result<ListResponse<PlacePrefix>, NetworkError>
            .failure(.invalid)

        _ = await sut.getPrefixs()

        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place/prefix-count")
        XCTAssertEqual(mockClient.lastMethodCalled, .get)
        XCTAssertNil(mockClient.lastParameters)
    }

    // MARK: - getBibleBookCounts

    func test_getBibleBookCounts_callsCorrectURL() async {
        mockClient.getResultAny = Result<ListResponse<BibleBookCount>, NetworkError>
            .failure(.invalid)

        _ = await sut.getBibleBookCounts()

        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place/bible-book-count")
        XCTAssertEqual(mockClient.lastMethodCalled, .get)
    }

    // MARK: - getPlace / getRelatedUserInfo

    func test_getPlace_callsCorrectURL() async {
        mockClient.getResultAny = Result<Place, NetworkError>.failure(.invalid)

        _ = await sut.getPlace(placeId: "P-123")

        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place/P-123")
        XCTAssertEqual(mockClient.lastMethodCalled, .get)
    }

    func test_getRelatedUserInfo_callsCorrectURL() async {
        mockClient.getResultAny = Result<RelatedUserInfo, NetworkError>.failure(.invalid)

        _ = await sut.getRelatedUserInfo(placeId: "P-777")

        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place/P-777/user")
        XCTAssertEqual(mockClient.lastMethodCalled, .get)
    }

    // MARK: - getBibleVerse

    func test_getBibleVerse_buildsCorrectParameters() async {
        mockClient.getResultAny = Result<BibleVerseResponse, NetworkError>.failure(.invalid)

        _ = await sut.getBibleVerse(
            version: .kor,
            book: "Gen",
            chapter: "1",
            verse: "1"
        )

        XCTAssertEqual(mockClient.lastRequestURL, "\(baseURL)/place/bible-verse")
        XCTAssertEqual(mockClient.lastMethodCalled, .get)

        guard let sent = mockClient.lastParameters else {
            return XCTFail("parameters nil")
        }

        XCTAssertEqual(sent["version"] as? String, BibleVersion.kor.rawValue)
        XCTAssertEqual(sent["book"] as? String, "Gen")
        XCTAssertEqual(sent["chapter"] as? String, "1")
        XCTAssertEqual(sent["verse"] as? String, "1")
    }
}
