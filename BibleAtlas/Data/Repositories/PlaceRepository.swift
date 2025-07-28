//
//  PlaceRepository.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/28/25.
//

import Foundation

public struct PlaceRepository:PlaceRepositoryProtocol{
    
    let placeApiService:PlaceApiServiceProtocol

    func getPlaces(limit: Int?, page: Int?, placeTypeId: Int?, name: String?, prefix: String?, sort:PlaceSort?) async -> Result<ListResponse<Place>, NetworkError> {
        return await placeApiService.getPlaces(limit: limit, page: page, placeTypeId: placeTypeId, name: name, prefix: prefix, sort: sort)
    }
    
    func getPlacesWithRepresentativePoint() async -> Result<ListResponse<Place>, NetworkError> {
        return await placeApiService.getPlacesWithRepresentativePoint()
    }
    
    func getPlaceTypes(limit: Int?, page: Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>, NetworkError> {
        return await placeApiService.getPlaceTypes(limit: limit, page: page)
    }
    
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>, NetworkError> {
        return await placeApiService.getPrefixs();
    }
    
    func getPlace(placeId: String) async -> Result<Place, NetworkError> {
        return await placeApiService.getPlace(placeId: placeId)
    }
    
    func getRelatedUserInfo(placeId: String) async -> Result<RelatedUserInfo, NetworkError> {
        return await placeApiService.getRelatedUserInfo(placeId: placeId)
    }
    
    func toggleSave(placeId: String) async -> Result<TogglePlaceSaveResponse, NetworkError> {
        return await placeApiService.toggleSave(placeId: placeId)
    }
    
    func toggleLike(placeId: String) async -> Result<TogglePlaceLikeResponse, NetworkError> {
        return await placeApiService.toggleLike(placeId: placeId)
    }
    
    func createOrUpdatePlaceMemo(placeId: String, text: String) async -> Result<PlaceMemoResponse, NetworkError> {
        return await placeApiService.createOrUpdatePlaceMemo(placeId: placeId, text: text)
    }
    
    func createPlaceProposal(placeId: String, comment: String) async -> Result<PlaceProposalResponse, NetworkError> {
        return await placeApiService.createPlaceProposal(placeId: placeId, comment: comment)
    }
    
    func deletePlaceMemo(placeId: String) async -> Result<PlaceMemoDeleteResponse, NetworkError> {
        return await placeApiService.deletePlaceMemo(placeId: placeId)
    }
    
    func getBibleVerse(version:BibleVersion, book:String, chapter:String, verse:String) async -> Result<BibleVerseResponse, NetworkError>{
        return await placeApiService.getBibleVerse(version: version, book: book, chapter: chapter, verse: verse)
    }
    
    func createPlaceReport(placeId: String, reportType: PlaceReportType, reason: String?) async -> Result<Int, NetworkError> {
        return await placeApiService.createPlaceReport(placeId: placeId, reportType: reportType, reason: reason)
    }
}
