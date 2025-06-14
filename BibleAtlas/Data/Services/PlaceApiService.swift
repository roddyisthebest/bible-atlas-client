//
//  PlaceApiService.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/28/25.
//

import Foundation
import Alamofire

protocol PlaceApiServiceProtocol {
    func getPlaces(limit:Int?, page:Int?, placeTypeId:Int?, name:String?, prefix:String?) async -> Result<ListResponse<Place>,NetworkError>
    func getPlaceTypes(limit:Int?, page:Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>,NetworkError>
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>,NetworkError>
    func getPlace(placeId:String) async -> Result<Place,NetworkError>
    func getRelatedUserInfo(placeId: String) async -> Result<RelatedUserInfo, NetworkError>
    func toggleSave(placeId:String) async -> Result<TogglePlaceSaveResponse, NetworkError>
    func toggleLike(placeId:String) async -> Result<TogglePlaceLikeResponse, NetworkError>

    func createPlaceProposal(placeId:String, comment:String) async -> Result<PlaceProposalResponse,NetworkError>
    func createOrUpdatePlaceMemo(placeId:String, text:String) async -> Result<PlaceMemoResponse, NetworkError>
    
    func deletePlaceMemo(placeId:String) async -> Result<PlaceMemoDeleteResponse, NetworkError>
    
    func getBibleVerse(version:BibleVersion, book:String, chapter:String, verse:String) async -> Result<BibleVerseResponse, NetworkError>

}


final public class PlaceApiService: PlaceApiServiceProtocol{

    
    
   
    private var apiClient:AuthorizedApiClientProtocol;
    private var url:String = "";
    
    
    init(apiClient: AuthorizedApiClientProtocol, url:String) {
        self.apiClient = apiClient
        self.url = url;
    }
    
    
    func getPlaces(limit: Int?, page: Int?, placeTypeId: Int?, name: String?, prefix: String?) async -> Result<ListResponse<Place>, NetworkError> {
        let page = page ?? 0;
        let limit = limit ?? 1;
        
        let rawParams: [String: Any?] = [
            "limit": limit,
            "page": page,
            "name": name,
            "placeTypeId": placeTypeId,
            "prefix": prefix
        ]

        let params: Parameters = rawParams.reduce(into: [:]) { result, pair in
            if let value = pair.value {
                result[pair.key] = value
            }
        }
        
        return await apiClient.getData(url:"\(url)/place",parameters: params)
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
    
}
