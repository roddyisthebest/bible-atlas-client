//
//  MockPlaceApiService.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
@testable import BibleAtlas

final class MockPlaceApiService: PlaceApiServiceProtocol{
    
    var calledMethods: [String] = []

    
    func getPlaces(parameters: BibleAtlas.PlaceParameters) async -> Result<BibleAtlas.ListResponse<BibleAtlas.Place>, BibleAtlas.NetworkError> {
        calledMethods.append("getPlaces")
        return .failure(.clientError("test"))
    }
    
    func getPlacesWithRepresentativePoint() async -> Result<BibleAtlas.ListResponse<BibleAtlas.Place>, BibleAtlas.NetworkError> {
        calledMethods.append("getPlacesWithRepresentativePoint")
        return .failure(.clientError("test"))
    }
    
    func getPlaceTypes(limit: Int?, page: Int?) async -> Result<BibleAtlas.ListResponse<BibleAtlas.PlaceTypeWithPlaceCount>, BibleAtlas.NetworkError> {
        calledMethods.append("getPlaceTypes")
        return .failure(.clientError("test"))
    }
    
    func getPrefixs() async -> Result<BibleAtlas.ListResponse<BibleAtlas.PlacePrefix>, BibleAtlas.NetworkError> {
        calledMethods.append("getPrefixs")
        return .failure(.clientError("test"))

    }
    
    func getBibleBookCounts() async -> Result<BibleAtlas.ListResponse<BibleAtlas.BibleBookCount>, BibleAtlas.NetworkError> {
        calledMethods.append("getBibleBookCounts")
        return .failure(.clientError("test"))

    }
    
    func getPlace(placeId: String) async -> Result<BibleAtlas.Place, BibleAtlas.NetworkError> {
        calledMethods.append("getPlace")
        return .failure(.clientError("test"))
    }
    
    func getRelatedUserInfo(placeId: String) async -> Result<BibleAtlas.RelatedUserInfo, BibleAtlas.NetworkError> {
        calledMethods.append("getRelatedUserInfo")
        return .failure(.clientError("test"))
    }
    
    func toggleSave(placeId: String) async -> Result<BibleAtlas.TogglePlaceSaveResponse, BibleAtlas.NetworkError> {
        calledMethods.append("toggleSave")
        return .failure(.clientError("test"))
    }
    
    func toggleLike(placeId: String) async -> Result<BibleAtlas.TogglePlaceLikeResponse, BibleAtlas.NetworkError> {
        calledMethods.append("toggleLike")
        return .failure(.clientError("test"))
    }
    
    func createPlaceProposal(placeId: String, comment: String) async -> Result<BibleAtlas.PlaceProposalResponse, BibleAtlas.NetworkError> {
        calledMethods.append("createPlaceProposal")
        return .failure(.clientError("test"))
    }
    
    func createOrUpdatePlaceMemo(placeId: String, text: String) async -> Result<BibleAtlas.PlaceMemoResponse, BibleAtlas.NetworkError> {
        calledMethods.append("createOrUpdatePlaceMemo")
        return .failure(.clientError("test"))

    }
    
    func deletePlaceMemo(placeId: String) async -> Result<BibleAtlas.PlaceMemoDeleteResponse, BibleAtlas.NetworkError> {
        calledMethods.append("deletePlaceMemo")
        return .failure(.clientError("test"))

    }
    
    func getBibleVerse(version: BibleAtlas.BibleVersion, book: String, chapter: String, verse: String) async -> Result<BibleAtlas.BibleVerseResponse, BibleAtlas.NetworkError> {
        calledMethods.append("getBibleVerse")
        return .failure(.clientError("test"))

    }
    
    func createPlaceReport(placeId: String, reportType: BibleAtlas.PlaceReportType, reason: String?) async -> Result<Int, BibleAtlas.NetworkError> {
        calledMethods.append("createPlaceReport")
        return .failure(.clientError("test"))
    }
    
    
    
    
    
    
}

