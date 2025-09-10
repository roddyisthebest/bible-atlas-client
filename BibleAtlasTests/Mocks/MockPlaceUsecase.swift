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


final class MockPlaceusecase: PlaceUsecaseProtocol{
    
    var resultToReturn: Result<ListResponse<Place>, NetworkError>?
    var isCalled = false;
    var invokedExp: XCTestExpectation?
    var completedExp: XCTestExpectation?

    var detailResultToReturn: Result<Place, NetworkError>?
    var completedDetailExp: XCTestExpectation?

    
    func getPlaces(parameters: BibleAtlas.PlaceParameters) async -> Result<BibleAtlas.ListResponse<BibleAtlas.Place>, BibleAtlas.NetworkError> {
        self.isCalled = true;
        invokedExp?.fulfill()
        defer { completedExp?.fulfill() }
        return resultToReturn ?? .failure(.clientError("test-error"))
    }
    
    var placesWithRepresentativePointResult: Result<BibleAtlas.ListResponse<BibleAtlas.Place>, BibleAtlas.NetworkError>?
    
    var placesWithRepresentativePointExp: XCTestExpectation?
    
    func getPlacesWithRepresentativePoint() async -> Result<BibleAtlas.ListResponse<BibleAtlas.Place>, BibleAtlas.NetworkError> {
        defer{
            placesWithRepresentativePointExp?.fulfill()
        }
        return  placesWithRepresentativePointResult ?? .failure(.clientError("not-implemented"))
    }
    
    
    var placeTypesResult: Result<BibleAtlas.ListResponse<BibleAtlas.PlaceTypeWithPlaceCount>, BibleAtlas.NetworkError>?
    
    var placeTypesExp: XCTestExpectation?
    var placeTypesCallCount = 0
    func getPlaceTypes(limit: Int?, page: Int?) async -> Result<BibleAtlas.ListResponse<BibleAtlas.PlaceTypeWithPlaceCount>, BibleAtlas.NetworkError> {
        defer{
            placeTypesExp?.fulfill()
            placeTypesCallCount += 1
        }
        return  placeTypesResult ?? .failure(.clientError("not-implemented"))
    }
    
    
    var prefixExp: XCTestExpectation?
    var prefixResult: Result<BibleAtlas.ListResponse<BibleAtlas.PlacePrefix>, BibleAtlas.NetworkError>?
    
    func getPrefixs() async -> Result<BibleAtlas.ListResponse<BibleAtlas.PlacePrefix>, BibleAtlas.NetworkError> {
        defer{
            prefixExp?.fulfill()
        }
        return  prefixResult ?? .failure(.clientError("not-implemented"))
    }
    
    func getPlace(placeId: String) async -> Result<BibleAtlas.Place, BibleAtlas.NetworkError> {
        defer{
            completedDetailExp?.fulfill()
        }
        return detailResultToReturn ?? .failure(.clientError("not-implemented"))
    }
    
    func getRelatedUserInfo(placeId: String) async -> Result<BibleAtlas.RelatedUserInfo, BibleAtlas.NetworkError> {
        return .failure(.clientError("not-implemented"))
    }
    
    func parseBible(verseString: String?) -> [BibleAtlas.Bible] {
        return []
    }
    
    
    var saveResultToReturn: Result<TogglePlaceSaveResponse, NetworkError>?

    var saveExp: XCTestExpectation?
    
    func toggleSave(placeId: String) async -> Result<BibleAtlas.TogglePlaceSaveResponse, BibleAtlas.NetworkError> {
        defer{
            saveExp?.fulfill()
        }
        return saveResultToReturn ?? .failure(.clientError("not-implemented"))
    }
    
    
    var likeResultToReturn: Result<TogglePlaceLikeResponse, NetworkError>?

    var likeExp: XCTestExpectation?
    
    func toggleLike(placeId: String) async -> Result<BibleAtlas.TogglePlaceLikeResponse, BibleAtlas.NetworkError> {
        defer{
            likeExp?.fulfill()
        }
        return likeResultToReturn ?? .failure(.clientError("not-implemented"))
    }
    
    
    var createMemoResult:Result<BibleAtlas.PlaceMemoResponse, BibleAtlas.NetworkError>?
    var memoExp: XCTestExpectation?
    
    func createOrUpdatePlaceMemo(placeId: String, text: String) async -> Result<BibleAtlas.PlaceMemoResponse, BibleAtlas.NetworkError> {
        defer{
            memoExp?.fulfill()
        }
        return  createMemoResult ?? .failure(.clientError("not-implemented"))
    }
    
    
    var proposalResultToReturn: Result<PlaceProposalResponse, NetworkError>?

    var proposalExp: XCTestExpectation?
    
    var createProposalCallCount = 0
    var lastProposalPlaceId: String?
    var lastProposalComment: String?
    
    func createPlaceProposal(placeId: String, comment: String) async -> Result<BibleAtlas.PlaceProposalResponse, BibleAtlas.NetworkError> {
        
        createProposalCallCount+=1;
        lastProposalPlaceId = placeId
        lastProposalComment = comment
        
        defer{
            proposalExp?.fulfill()
        }
        return proposalResultToReturn ?? .failure(.clientError("not-implemented"))
    }
    
    
    var deletePlaceMemoResult: Result<BibleAtlas.PlaceMemoDeleteResponse, BibleAtlas.NetworkError>?
    var deletePlaceMemoExp: XCTestExpectation?
    
    func deletePlaceMemo(placeId: String) async -> Result<BibleAtlas.PlaceMemoDeleteResponse, BibleAtlas.NetworkError> {
        defer{
            deletePlaceMemoExp?.fulfill()
        }
        return  deletePlaceMemoResult ?? .failure(.clientError("not-implemented"))
    }
    
    func getBibleVerse(version: BibleAtlas.BibleVersion, book: String, chapter: String, verse: String) async -> Result<BibleAtlas.BibleVerseResponse, BibleAtlas.NetworkError> {
        return .failure(.clientError("not-implemented"))
    }
    
    var createReportResultToReturn: Result<Int, NetworkError>?
    var createReportExp: XCTestExpectation?
    var reportType:PlaceReportType?
    func createPlaceReport(placeId: String, reportType: BibleAtlas.PlaceReportType, reason: String?) async -> Result<Int, BibleAtlas.NetworkError> {
        
        defer{
            createReportExp?.fulfill()
        }
        self.reportType = reportType
        return createReportResultToReturn ?? .failure(.clientError("not-implemented"))
    }
    
}
