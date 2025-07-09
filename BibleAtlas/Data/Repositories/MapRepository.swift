//
//  GeoJsonRepository.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/9/25.
//

import Foundation
import MapKit

public struct MapRepository:MapRepositoryProtocol{

    let mapApiService:MapApiServiceProtocol
    
    func getGeoJson(placeId: String) async -> Result<[MKGeoJSONFeature], NetworkError> {
        await mapApiService.getGeoJson(placeId: placeId)
    }
    
}
