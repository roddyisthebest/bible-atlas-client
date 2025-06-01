//
//  PlaceApiService.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/28/25.
//

import Foundation
import Alamofire

protocol PlaceApiServiceProtocol {
    func getPlaces(limit:Int?, page:Int?, placeTypeId:Int?, name:String?) async -> Result<ListResponse<Place>,NetworkError>
    
    func getPlaceTypes(limit:Int?, page:Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>,NetworkError>
    
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>,NetworkError>
    
}


final public class PlaceApiService: PlaceApiServiceProtocol{
    
    private var apiClient:AuthorizedApiClientProtocol;
    private var url:String = "";
    
    
    init(apiClient: AuthorizedApiClientProtocol, url:String) {
        self.apiClient = apiClient
        self.url = url;
    }
    
    
    func getPlaces(limit: Int?, page: Int?, placeTypeId: Int?, name: String?) async -> Result<ListResponse<Place>, NetworkError> {
        let page = page ?? 0;
        let limit = limit ?? 1;
        
        let params: Parameters = [
               "limit": limit,
               "page": page,
               "name": name,
               "placeTypeId": placeTypeId
           ].compactMapValues { $0 }
        
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
}
