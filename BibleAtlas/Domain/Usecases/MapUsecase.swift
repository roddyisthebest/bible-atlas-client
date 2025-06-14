//
//  MapUsecase.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/9/25.
//

import Foundation
import MapKit

protocol MapUsecaseProtocol{
    func getGeoJson(placeId:String) async -> Result<[MKGeoJSONFeature], NetworkError>
}

public struct MapUsecase:MapUsecaseProtocol{
  
    private let repository:MapRepositoryProtocol
    
    init(repository:MapRepositoryProtocol){
        self.repository = repository
    }
    
  
    func getGeoJson(placeId: String) async -> Result<[MKGeoJSONFeature], NetworkError> {
        await repository.getGeoJson(placeId: placeId)
    }
    
}
