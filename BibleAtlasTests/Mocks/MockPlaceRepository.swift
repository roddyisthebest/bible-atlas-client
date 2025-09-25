//
//  MockPlaceRepository.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import Foundation
import RxSwift
@testable import BibleAtlas

final class MockPlaceRepository: PlaceRepositoryProtocol {
    // 호출 기록용
    struct Call: Equatable { let name: String }
    private(set) var calls: [Call] = []

    // 매 요청에 대해 돌려줄 next Result 보관
    var next_getPlaces: Result<ListResponse<Place>, NetworkError>!
    var next_getPlacesWithRepresentativePoint: Result<ListResponse<Place>, NetworkError>!
    var next_getPlaceTypes: Result<ListResponse<PlaceTypeWithPlaceCount>, NetworkError>!
    var next_getPrefixs: Result<ListResponse<PlacePrefix>, NetworkError>!
    var next_getBibleBookCounts: Result<ListResponse<BibleBookCount>, NetworkError>!
    var next_getPlace: Result<Place, NetworkError>!
    var next_getRelatedUserInfo: Result<RelatedUserInfo, NetworkError>!
    var next_toggleSave: Result<TogglePlaceSaveResponse, NetworkError>!
    var next_toggleLike: Result<TogglePlaceLikeResponse, NetworkError>!
    var next_createOrUpdatePlaceMemo: Result<PlaceMemoResponse, NetworkError>!
    var next_createPlaceProposal: Result<PlaceProposalResponse, NetworkError>!
    var next_deletePlaceMemo: Result<PlaceMemoDeleteResponse, NetworkError>!
    var next_getBibleVerse: Result<BibleVerseResponse, NetworkError>!
    var next_createPlaceReport: Result<Int, NetworkError>!

    // 마지막으로 전달된 파라미터 기록 (검증용)
    private(set) var last_parameters_getPlaces: PlaceParameters?
    private(set) var last_placeId_getPlace: String?
    private(set) var last_placeId_toggleSave: String?
    private(set) var last_placeId_toggleLike: String?
    private(set) var last_placeId_memo: String?
    private(set) var last_memoText: String?
    private(set) var last_placeId_proposal: String?
    private(set) var last_proposalComment: String?
    private(set) var last_placeId_deleteMemo: String?
    private(set) var last_bibleArgs: (BibleVersion,String,String,String)?
    private(set) var last_placeReportArgs: (String, PlaceReportType, String?)?

    // MARK: - Conformance

    func getPlaces(parameters: PlaceParameters) async -> Result<ListResponse<Place>, NetworkError> {
        calls.append(.init(name: "getPlaces"))
        last_parameters_getPlaces = parameters
        return next_getPlaces!
    }

    func getPlacesWithRepresentativePoint() async -> Result<ListResponse<Place>, NetworkError> {
        calls.append(.init(name: "getPlacesWithRepresentativePoint"))
        return next_getPlacesWithRepresentativePoint!
    }

    func getPlaceTypes(limit: Int?, page: Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>, NetworkError> {
        calls.append(.init(name: "getPlaceTypes"))
        return next_getPlaceTypes!
    }

    func getPrefixs() async -> Result<ListResponse<PlacePrefix>, NetworkError> {
        calls.append(.init(name: "getPrefixs"))
        return next_getPrefixs!
    }

    func getBibleBookCounts() async -> Result<ListResponse<BibleBookCount>, NetworkError> {
        calls.append(.init(name: "getBibleBookCounts"))
        return next_getBibleBookCounts!
    }

    func getPlace(placeId: String) async -> Result<Place, NetworkError> {
        calls.append(.init(name: "getPlace"))
        last_placeId_getPlace = placeId
        return next_getPlace!
    }

    func getRelatedUserInfo(placeId: String) async -> Result<RelatedUserInfo, NetworkError> {
        calls.append(.init(name: "getRelatedUserInfo"))
        return next_getRelatedUserInfo!
    }

    func toggleSave(placeId: String) async -> Result<TogglePlaceSaveResponse, NetworkError> {
        calls.append(.init(name: "toggleSave"))
        last_placeId_toggleSave = placeId
        return next_toggleSave!
    }

    func toggleLike(placeId: String) async -> Result<TogglePlaceLikeResponse, NetworkError> {
        calls.append(.init(name: "toggleLike"))
        last_placeId_toggleLike = placeId
        return next_toggleLike!
    }

    func createOrUpdatePlaceMemo(placeId: String, text: String) async -> Result<PlaceMemoResponse, NetworkError> {
        calls.append(.init(name: "createOrUpdatePlaceMemo"))
        last_placeId_memo = placeId
        last_memoText = text
        return next_createOrUpdatePlaceMemo!
    }

    func createPlaceProposal(placeId: String, comment: String) async -> Result<PlaceProposalResponse, NetworkError> {
        calls.append(.init(name: "createPlaceProposal"))
        last_placeId_proposal = placeId
        last_proposalComment = comment
        return next_createPlaceProposal!
    }

    func deletePlaceMemo(placeId: String) async -> Result<PlaceMemoDeleteResponse, NetworkError> {
        calls.append(.init(name: "deletePlaceMemo"))
        last_placeId_deleteMemo = placeId
        return next_deletePlaceMemo!
    }

    func getBibleVerse(version: BibleVersion, book: String, chapter: String, verse: String) async -> Result<BibleVerseResponse, NetworkError> {
        calls.append(.init(name: "getBibleVerse"))
        last_bibleArgs = (version, book, chapter, verse)
        return next_getBibleVerse!
    }

    func createPlaceReport(placeId: String, reportType: PlaceReportType, reason: String?) async -> Result<Int, NetworkError> {
        calls.append(.init(name: "createPlaceReport"))
        last_placeReportArgs = (placeId, reportType, reason)
        return next_createPlaceReport!
    }
}
