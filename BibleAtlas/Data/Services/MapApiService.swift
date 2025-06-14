//
//  GeoJsonApiService.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/9/25.
//

import Foundation
import MapKit
protocol MapApiServiceProtocol {
    func getGeoJson(placeId:String) async -> Result<[MKGeoJSONFeature], NetworkError>
}


final class MapApiService:MapApiServiceProtocol {
    
    private let apiClient: AuthorizedApiClientProtocol
    private let baseURL: String
    
    init(apiClient: AuthorizedApiClientProtocol, baseURL: String) {
        self.apiClient = apiClient
        self.baseURL = baseURL
    }
    
    func getGeoJson(placeId: String) async -> Result<[MKGeoJSONFeature], NetworkError> {
        let url = "\(baseURL)/\(placeId).geojson"
                
        let result = await apiClient.getRawData(url: url, parameters: nil);
        
            
        switch(result){
        case.success(let data):
            do{
                let features = try MKGeoJSONDecoder().decode(data)
                              .compactMap { $0 as? MKGeoJSONFeature }
                return .success(features)

            }
            catch {
                return .failure(.failToDecode(error.localizedDescription))

            }
        case .failure(let error):
            return .failure(error)
        }
        
        
    }
    
    
    
}
