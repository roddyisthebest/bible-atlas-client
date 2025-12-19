//
//  MockPlaceUsecase.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/6/25.
//


import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas


final class MockPlaceusecase: PlaceUsecaseProtocol {
    func getBibleBookCounts() async -> Result<BibleAtlas.ListResponse<BibleAtlas.BibleBookCount>, BibleAtlas.NetworkError> {
        return bibleBookCountsResult ?? .failure(.clientError("not-implemented"))
    }
    

    var resultToReturn: Result<ListResponse<Place>, NetworkError>?

    
    var resultsQueue: [Result<ListResponse<Place>, NetworkError>] = []
    var delayBeforeReturn: TimeInterval = 0.0
    var delaysQueue: [TimeInterval] = []

    
    var bibleBookCountsResult: Result<ListResponse<BibleBookCount>, NetworkError>?

    
    // 호출/파라미터 추적
    var listApiCall = 0
    var lastGetPlacesParameters: PlaceParameters?
    var getPlacesParametersHistory: [PlaceParameters] = []

    // XCTest expectation & 콜백
    var invokedExp: XCTestExpectation?
    var completedExp: XCTestExpectation?
    var onGetPlacesCall: ((Int, PlaceParameters) -> Void)?            // (callIndex, params)
    var onGetPlacesReturn: ((Int, Result<ListResponse<Place>, NetworkError>) -> Void)?

    // 기타 플래그(기존)
    var isCalled = false

    // MARK: - getPlaces 구현
    func getPlaces(parameters: PlaceParameters) async -> Result<ListResponse<Place>, NetworkError> {
        isCalled = true
        let callIndex = listApiCall + 1

        // 파라미터 캡처
        lastGetPlacesParameters = parameters
        getPlacesParametersHistory.append(parameters)

        // 호출 시점 콜백 & exp
        onGetPlacesCall?(callIndex, parameters)
        invokedExp?.fulfill()

        // 지연(개별 지연 > 고정 지연)
        let delay = delaysQueue.isEmpty ? delayBeforeReturn : delaysQueue.removeFirst()
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        // 결과(큐 우선, 없으면 단일값, 그것도 없으면 기본 실패)
        let result = resultsQueue.isEmpty ? (resultToReturn ?? .failure(.clientError("test-error"))) : resultsQueue.removeFirst()

        // 반환 직전 콜백
        onGetPlacesReturn?(callIndex, result)

        // 완료 exp & 호출 카운트
        defer {
            completedExp?.fulfill()
            listApiCall += 1
        }
        return result
    }

    // MARK: - 대표 포인트 있는 장소
    var placesWithRepresentativePointResult: Result<ListResponse<Place>, NetworkError>?
    var placesWithRepresentativePointExp: XCTestExpectation?
    var placesWithRepresentativePointCallCount = 0

    func getPlacesWithRepresentativePoint() async -> Result<ListResponse<Place>, NetworkError> {
        defer {
            placesWithRepresentativePointCallCount += 1
            placesWithRepresentativePointExp?.fulfill()
        }
        return placesWithRepresentativePointResult ?? .failure(.clientError("not-implemented"))
    }

    // MARK: - 타입 목록
    var placeTypesResult: Result<ListResponse<PlaceTypeWithPlaceCount>, NetworkError>?
    var placeTypesExp: XCTestExpectation?
    var placeTypesCallCount = 0

    func getPlaceTypes(limit: Int?, page: Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>, NetworkError> {
        defer {
            placeTypesCallCount += 1
            placeTypesExp?.fulfill()
        }
        return placeTypesResult ?? .failure(.clientError("not-implemented"))
    }

    // MARK: - Prefix
    var prefixExp: XCTestExpectation?
    var prefixResult: Result<ListResponse<PlacePrefix>, NetworkError>?

    func getPrefixs() async -> Result<ListResponse<PlacePrefix>, NetworkError> {
        defer { prefixExp?.fulfill() }
        return prefixResult ?? .failure(.clientError("not-implemented"))
    }

    // MARK: - 상세
    var detailResultToReturn: Result<Place, NetworkError>?
    var completedDetailExp: XCTestExpectation?
    var getPlaceCallCount = 0
    var lastGetPlaceId: String?

    func getPlace(placeId: String) async -> Result<Place, NetworkError> {
        lastGetPlaceId = placeId
        defer {
            getPlaceCallCount += 1
            completedDetailExp?.fulfill()
        }
        return detailResultToReturn ?? .failure(.clientError("not-implemented"))
    }

    // 관계 사용자
    func getRelatedUserInfo(placeId: String) async -> Result<RelatedUserInfo, NetworkError> {
        return .failure(.clientError("not-implemented"))
    }

    var parsedBible:[Bible]?
    // 파서
    func parseBible(verseString: String?) -> [Bible] { return parsedBible ?? [] }

    // MARK: - 토글 저장/좋아요
    var saveResultToReturn: Result<TogglePlaceSaveResponse, NetworkError>?
    var saveExp: XCTestExpectation?
    var toggleSaveCallCount = 0
    var lastSavePlaceId: String?

    func toggleSave(placeId: String) async -> Result<TogglePlaceSaveResponse, NetworkError> {
        lastSavePlaceId = placeId
        defer {
            toggleSaveCallCount += 1
            saveExp?.fulfill()
        }
        return saveResultToReturn ?? .failure(.clientError("not-implemented"))
    }

    var likeResultToReturn: Result<TogglePlaceLikeResponse, NetworkError>?
    var likeExp: XCTestExpectation?
    var toggleLikeCallCount = 0
    var lastLikePlaceId: String?

    func toggleLike(placeId: String) async -> Result<TogglePlaceLikeResponse, NetworkError> {
        lastLikePlaceId = placeId
        defer {
            toggleLikeCallCount += 1
            likeExp?.fulfill()
        }
        return likeResultToReturn ?? .failure(.clientError("not-implemented"))
    }

    // MARK: - 메모
    var createMemoResult: Result<PlaceMemoResponse, NetworkError>?
    var memoExp: XCTestExpectation?
    var createMemoCallCount = 0
    var lastMemoPlaceId: String?
    var lastMemoText: String?

    func createOrUpdatePlaceMemo(placeId: String, text: String) async -> Result<PlaceMemoResponse, NetworkError> {
        lastMemoPlaceId = placeId
        lastMemoText = text
        defer {
            createMemoCallCount += 1
            memoExp?.fulfill()
        }
        return createMemoResult ?? .failure(.clientError("not-implemented"))
    }

    // MARK: - 제안
    var proposalResultToReturn: Result<PlaceProposalResponse, NetworkError>?
    var proposalExp: XCTestExpectation?
    var createProposalCallCount = 0
    var lastProposalPlaceId: String?
    var lastProposalComment: String?

    func createPlaceProposal(placeId: String, comment: String) async -> Result<PlaceProposalResponse, NetworkError> {
        createProposalCallCount += 1
        lastProposalPlaceId = placeId
        lastProposalComment = comment
        defer { proposalExp?.fulfill() }
        return proposalResultToReturn ?? .failure(.clientError("not-implemented"))
    }

    // MARK: - 메모 삭제
    var deletePlaceMemoResult: Result<PlaceMemoDeleteResponse, NetworkError>?
    var deletePlaceMemoExp: XCTestExpectation?
    var deletePlaceMemoCallCount = 0
    var lastDeleteMemoPlaceId: String?

    func deletePlaceMemo(placeId: String) async -> Result<PlaceMemoDeleteResponse, NetworkError> {
        lastDeleteMemoPlaceId = placeId
        defer {
            deletePlaceMemoCallCount += 1
            deletePlaceMemoExp?.fulfill()
        }
        return deletePlaceMemoResult ?? .failure(.clientError("not-implemented"))
    }

    // MARK: - 성경 구절
    var bibleVerseExp: XCTestExpectation?
    var bibleVerseResult: Result<BibleVerseResponse, NetworkError>?
    var calledVerseProps: CalledVerseProps?
    var verseDelayBeforeReturn: TimeInterval = 0.0
    var onGetBibleVerseCall: ((CalledVerseProps) -> Void)?

    func getBibleVerse(version: BibleVersion, book: String, chapter: String, verse: String) async -> Result<BibleVerseResponse, NetworkError> {
        let props = CalledVerseProps(version: version, book: book, chapter: chapter, verse: verse)
        calledVerseProps = props
        onGetBibleVerseCall?(props)

        if verseDelayBeforeReturn > 0 {
            try? await Task.sleep(nanoseconds: UInt64(verseDelayBeforeReturn * 1_000_000_000))
        }

        defer { bibleVerseExp?.fulfill() }
        return bibleVerseResult ?? .failure(.clientError("not-implemented"))
    }

    // MARK: - 신고
    var createReportResultToReturn: Result<Int, NetworkError>?
    var createReportExp: XCTestExpectation?
    var reportType: PlaceReportType?
    var createReportCallCount = 0
    var lastReportPlaceId: String?
    var lastReportReason: String?

    func createPlaceReport(placeId: String, reportType: PlaceReportType, reason: String?) async -> Result<Int, NetworkError> {
        self.reportType = reportType
        lastReportPlaceId = placeId
        lastReportReason = reason
        defer {
            createReportCallCount += 1
            createReportExp?.fulfill()
        }
        return createReportResultToReturn ?? .failure(.clientError("not-implemented"))
    }

    // MARK: - 편의: 리셋
    func reset() {
        resultToReturn = nil
        resultsQueue.removeAll()
        delayBeforeReturn = 0
        delaysQueue.removeAll()

        listApiCall = 0
        lastGetPlacesParameters = nil
        getPlacesParametersHistory.removeAll()

        invokedExp = nil
        completedExp = nil
        onGetPlacesCall = nil
        onGetPlacesReturn = nil

        isCalled = false
    }
}

struct CalledVerseProps {
    var version: BibleVersion
    var book: String
    var chapter: String
    var verse: String
}
