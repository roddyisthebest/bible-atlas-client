//
//  PlaceApiService.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/28/25.
//

import Foundation
import Alamofire
    

struct PlaceParameters {
    var limit:Int? = 10
    var page:Int? = 0
    var placeTypeName:PlaceTypeName?
    var name:String?
    var prefix:String?
    var sort:PlaceSort?
    var bible:BibleBook?
}

protocol PlaceApiServiceProtocol {
    func getPlaces(parameters:PlaceParameters) async -> Result<ListResponse<Place>,NetworkError>
    
    func getPlacesWithRepresentativePoint() async -> Result<ListResponse<Place>, NetworkError>
    func getPlaceTypes(limit:Int?, page:Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>,NetworkError>
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>,NetworkError>
    func getBibleBookCounts() async -> Result<ListResponse<BibleBookCount>,NetworkError>

    func getPlace(placeId:String) async -> Result<Place,NetworkError>
    func getRelatedUserInfo(placeId: String) async -> Result<RelatedUserInfo, NetworkError>
    func toggleSave(placeId:String) async -> Result<TogglePlaceSaveResponse, NetworkError>
    func toggleLike(placeId:String) async -> Result<TogglePlaceLikeResponse, NetworkError>

    func createPlaceProposal(placeId:String, comment:String) async -> Result<PlaceProposalResponse,NetworkError>
    func createOrUpdatePlaceMemo(placeId:String, text:String) async -> Result<PlaceMemoResponse, NetworkError>
    
    func deletePlaceMemo(placeId:String) async -> Result<PlaceMemoDeleteResponse, NetworkError>
    
    func getBibleVerse(version:BibleVersion, book:String, chapter:String, verse:String) async -> Result<BibleVerseResponse, NetworkError>
    
    func createPlaceReport(placeId:String, reportType:PlaceReportType, reason:String?) async -> Result<Int, NetworkError>

}


final public class PlaceApiService: PlaceApiServiceProtocol{

    
    
   
    private var apiClient:AuthorizedApiClientProtocol;
    private var url:String = "";
    
    
    init(apiClient: AuthorizedApiClientProtocol, url:String) {
        self.apiClient = apiClient
        self.url = url;
    }
    
    
    func getPlaces(parameters:PlaceParameters) async -> Result<ListResponse<Place>, NetworkError> {
    
        
        let rawParams: [String: Any?] = [
            "limit": parameters.limit,
            "page": parameters.page,
            "name": parameters.name,
            "prefix": parameters.prefix,
            "placeTypes": parameters.placeTypeName?.rawValue,
            "sort": parameters.sort?.rawValue,
            "bibleBook":parameters.bible?.rawValue
        ]

        let params: Parameters = rawParams.reduce(into: [:]) { result, pair in
            if let value = pair.value {
                result[pair.key] = value
            }
        }
        
        
        return await apiClient.getData(url:"\(url)/place",parameters: params)
    }
    
    
    func getPlacesWithRepresentativePoint() async -> Result<ListResponse<Place>, NetworkError> {
        return await apiClient.getData(url: "\(url)/place/with-representative-point", parameters: nil)
    }
    
    func getPlaceTypes(limit: Int?, page: Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>, NetworkError> {
        let page = page ?? 0;
        let limit = limit ?? 1;
        
        let params: Parameters = [
            "limit": limit,
            "page": page,
        ]
        
        return await apiClient.getData(url: "\(url)/place-type", parameters: params)
        
    }
    
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>, NetworkError> {
        return await apiClient.getData(url: "\(url)/place/prefix-count", parameters: nil);
    }
    
    func getBibleBookCounts() async ->  Result<ListResponse<BibleBookCount>,NetworkError> {
        return await apiClient.getData(url:"\(url)/place/bible-book-count", parameters: nil)
    }
    
    
    func getPlace(placeId: String) async -> Result<Place, NetworkError> {
        return await apiClient.getData(url: "\(url)/place/\(placeId)", parameters: nil)
    }
    
    func getRelatedUserInfo(placeId: String) async -> Result<RelatedUserInfo, NetworkError>{
        return await apiClient.getData(url: "\(url)/place/\(placeId)/user", parameters: nil)
    }
    
    func toggleSave(placeId: String) async -> Result<TogglePlaceSaveResponse, NetworkError> {
        return await apiClient.postData(url: "\(url)/place/\(placeId)/save", parameters: nil, body: nil, headers: nil)
    }
    
    func toggleLike(placeId: String) async -> Result<TogglePlaceLikeResponse, NetworkError> {
        return await apiClient.postData(url: "\(url)/place/\(placeId)/like", parameters: nil, body: nil, headers: nil)
    }
    
    
    func getBibleVerse(version:BibleVersion, book:String, chapter:String, verse:String) async -> Result<BibleVerseResponse, NetworkError> {
            
        print(chapter,"chapter")
        print(verse,"verse")

        let params: Parameters = [
            "version": version.rawValue,
            "book": book,
            "chapter": chapter,
            "verse": verse
        ]
        
        return await apiClient.getData(url: "\(url)/place/bible-verse", parameters: params)
    }
    
    func createOrUpdatePlaceMemo(placeId: String, text: String) async -> Result<PlaceMemoResponse, NetworkError> {
        
        let json: [String: String] = ["text": text]
         
         guard let body = try? JSONSerialization.data(withJSONObject: json, options: []) else {
             return .failure(.failToJSONSerialize("json 직렬화 에러"))
         }
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        return await apiClient.postData(url: "\(url)/place/\(placeId)/memo", parameters: nil, body: body, headers: headers)
    
    }
    
    
    func createPlaceProposal(placeId:String, comment:String) async -> Result<PlaceProposalResponse,NetworkError>{
        let json:[String: String] = [
            "placeId": placeId,
            "comment": comment,
            "type": "2"
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.failToJSONSerialize("json 직렬화 에러"))
        }
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        return await apiClient.postData(url: "\(url)/proposal", parameters: nil, body: body, headers: headers)

    }

    func deletePlaceMemo(placeId: String) async -> Result<PlaceMemoDeleteResponse, NetworkError> {
        return await apiClient.deleteData(url: "\(url)/place/\(placeId)/memo", parameters: nil)
    }
    
    
    
    func createPlaceReport(placeId:String, reportType:PlaceReportType, reason:String?) async -> Result<Int, NetworkError> {
        
        let json: [String: String?] = ["reason": reason, "type": String(reportType.rawValue), "placeId": placeId]
         
        guard let body = try? JSONSerialization.data(withJSONObject: json, options: []) else {
             return .failure(.failToJSONSerialize("json 직렬화 에러"))
        }
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        return await apiClient.postData(url: "\(url)/place-report", parameters: nil, body: body, headers: headers)
    
    }
    
}
