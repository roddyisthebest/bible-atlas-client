//
//  PlaceRepositoryProtocol.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/28/25.
//

import Foundation


protocol PlaceRepositoryProtocol {
    func getPlaces(limit:Int?, page:Int?, placeTypeId:Int?, name:String?, prefix:String?, sort:PlaceSort?) async -> Result<ListResponse<Place>,NetworkError>
    
    func getPlacesWithRepresentativePoint() async -> Result<ListResponse<Place>, NetworkError>

    func getPlaceTypes(limit:Int?, page:Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>,NetworkError>
    
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>,NetworkError>
    
    func getPlace(placeId: String) async -> Result<Place, NetworkError>
    
    func getRelatedUserInfo(placeId: String) async -> Result<RelatedUserInfo, NetworkError>

    func toggleSave(placeId:String) async -> Result<TogglePlaceSaveResponse, NetworkError>
    
    func toggleLike(placeId:String) async -> Result<TogglePlaceLikeResponse, NetworkError>
    
    func createOrUpdatePlaceMemo(placeId:String, text:String) async -> Result<PlaceMemoResponse, NetworkError>

    func createPlaceProposal(placeId:String, comment:String) async -> Result<PlaceProposalResponse,NetworkError>

    func deletePlaceMemo(placeId:String) async -> Result<PlaceMemoDeleteResponse, NetworkError>
    
    func getBibleVerse(version:BibleVersion, book:String, chapter:String, verse:String) async -> Result<BibleVerseResponse, NetworkError>
    
    func createPlaceReport(placeId:String, reportType:PlaceReportType, reason:String?) async -> Result<Int, NetworkError>
    
}



