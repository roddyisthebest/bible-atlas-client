//
//  PlaceUsecase.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/28/25.
//

import Foundation

protocol PlaceUsecaseProtocol {
    func getPlaces(parameters:PlaceParameters) async -> Result<ListResponse<Place>,NetworkError>
    
    func getPlacesWithRepresentativePoint() async -> Result<ListResponse<Place>, NetworkError>

    func getPlaceTypes(limit:Int?, page:Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>,NetworkError>
    
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>,NetworkError>
    
    func getBibleBookCounts() async ->  Result<ListResponse<BibleBookCount>,NetworkError>
    
    func getPlace(placeId:String) async -> Result<Place,NetworkError>
    
    func getRelatedUserInfo(placeId: String) async -> Result<RelatedUserInfo, NetworkError>

    func parseBible(verseString:String?) -> [Bible]
    
    func toggleSave(placeId:String) async -> Result<TogglePlaceSaveResponse, NetworkError>

    func toggleLike(placeId:String) async -> Result<TogglePlaceLikeResponse, NetworkError>
    
    func createOrUpdatePlaceMemo(placeId:String, text:String) async -> Result<PlaceMemoResponse, NetworkError>

    func createPlaceProposal(placeId:String, comment:String) async -> Result<PlaceProposalResponse,NetworkError>

    
    func deletePlaceMemo(placeId:String) async -> Result<PlaceMemoDeleteResponse, NetworkError>
    
    func getBibleVerse(version:BibleVersion, book:String, chapter:String, verse:String) async -> Result<BibleVerseResponse, NetworkError>

    func createPlaceReport(placeId:String, reportType:PlaceReportType, reason:String?) async -> Result<Int, NetworkError>
    
}


public struct PlaceUsecase:PlaceUsecaseProtocol{

    private let repository:PlaceRepositoryProtocol
    
    init(repository: PlaceRepositoryProtocol) {
        self.repository = repository
    }
    
    
    func getPlaces(parameters:PlaceParameters) async -> Result<ListResponse<Place>, NetworkError> {
        return await repository.getPlaces(parameters: parameters)
    }
    
    func getPlacesWithRepresentativePoint() async -> Result<ListResponse<Place>, NetworkError> {
        return await repository.getPlacesWithRepresentativePoint();
    }
    
    func getPlaceTypes(limit: Int?, page: Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>, NetworkError> {
        return await repository.getPlaceTypes(limit: limit, page: page)
    }
    
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>, NetworkError> {
        return await repository.getPrefixs();
    }
    
    func getBibleBookCounts() async ->  Result<ListResponse<BibleBookCount>,NetworkError>{
        return await repository.getBibleBookCounts()
    }
    
    func getPlace(placeId: String) async -> Result<Place, NetworkError> {
        return await repository.getPlace(placeId: placeId)
    }
    
    func getRelatedUserInfo(placeId: String) async -> Result<RelatedUserInfo, NetworkError> {
        return await repository.getRelatedUserInfo(placeId: placeId)
    }
    
    func parseBible(verseString: String?) -> [Bible] {
        guard let verseString, !verseString.isEmpty, !verseString.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        
        let verses = verseString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        let grouped = Dictionary(grouping: verses) { verse in
                  verse.split(separator: ".").first.map(String.init) ?? "Unknown"
              }
        
        return grouped.map { book, fullVerses in
            let bodyVerses = fullVerses.map {
                $0.split(separator: ".").dropFirst().joined(separator: ".")
            }
            return Bible(bookName: BibleBook(parsing: book) ?? .Etc, verses: bodyVerses)
        }

    }
    
    func toggleSave(placeId: String) async -> Result<TogglePlaceSaveResponse, NetworkError> {
        return await repository.toggleSave(placeId: placeId)
    }
    
    func toggleLike(placeId: String) async -> Result<TogglePlaceLikeResponse, NetworkError> {
        return await repository.toggleLike(placeId: placeId)
    }
    
    func createOrUpdatePlaceMemo(placeId: String, text: String) async -> Result<PlaceMemoResponse, NetworkError> {
        return await repository.createOrUpdatePlaceMemo(placeId: placeId, text: text)
    }
    
    func createPlaceProposal(placeId: String, comment: String) async -> Result<PlaceProposalResponse, NetworkError> {
        return await repository.createPlaceProposal(placeId: placeId, comment: comment)
    }
    
    func deletePlaceMemo(placeId: String) async -> Result<PlaceMemoDeleteResponse, NetworkError> {
        return await repository.deletePlaceMemo(placeId: placeId)
    }
    
    func getBibleVerse(version: BibleVersion, book: String, chapter: String, verse: String) async -> Result<BibleVerseResponse, NetworkError> {
        return await repository.getBibleVerse(version: version, book: book, chapter: chapter, verse: verse)
    }
    
    func createPlaceReport(placeId:String, reportType:PlaceReportType, reason:String?) async -> Result<Int, NetworkError>{
        return await repository.createPlaceReport(placeId: placeId, reportType: reportType, reason: reason)
    }
    
}
