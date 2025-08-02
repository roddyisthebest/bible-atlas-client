//
//  UserApiService.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/21/25.
//

import Foundation
import Alamofire

enum PlaceFilter:String {
    case like = "like"
    case save = "save"
    case memo = "memo"
}


protocol UserApiServiceProtocol {
    func getPlaces(limit:Int?, page:Int?, filter:PlaceFilter? ) async -> Result<ListResponse<Place>,NetworkError>
    func getMyCollectionPlaceIds() async -> Result<MyCollectionPlaceIds, NetworkError>
    func getProfile() async -> Result<User,NetworkError>

}


final public class UserApiService:UserApiServiceProtocol{
 
    
    
    private var apiClient: AuthorizedApiClientProtocol;
    private var url: String = "";
    
    init(apiClient: AuthorizedApiClientProtocol, url:String) {
        self.apiClient = apiClient
        self.url = url;
    }
    
    func getPlaces(limit: Int?, page: Int?, filter: PlaceFilter?) async -> Result<ListResponse<Place>,NetworkError> {
        let page = page ?? 0
        let limit = limit ?? 1
            
        let filter = filter ?? PlaceFilter.like
        
        let params: Parameters = [
            "limit": limit,
            "page": page,
            "filter": filter.rawValue
        ]
            
        return await apiClient.getData(url:"\(url)/me/places", parameters: params)
        
    }
    
    func getMyCollectionPlaceIds() async -> Result<MyCollectionPlaceIds, NetworkError>{
        return await apiClient.getData(url: "\(url)/me/collection-place-ids", parameters: nil)
    }
    
    
    func getProfile() async -> Result<User, NetworkError> {
        return await apiClient.getData(url: "\(url)/me", parameters: nil)
    }
}
