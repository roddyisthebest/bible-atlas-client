//
//  PlaceRepository.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/28/25.
//

import Foundation

public struct PlaceRepository:PlaceRepositoryProtocol{
    let placeApiService:PlaceApiServiceProtocol

    func getPlaces(limit: Int?, page: Int?, placeTypeId: Int?, name: String?, prefix: String?) async -> Result<ListResponse<Place>, NetworkError> {
        return await placeApiService.getPlaces(limit: limit, page: page, placeTypeId: placeTypeId, name: name, prefix: prefix)
    }
    
    func getPlaceTypes(limit: Int?, page: Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>, NetworkError> {
        return await placeApiService.getPlaceTypes(limit: limit, page: page)
    }
    
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>, NetworkError> {
        return await placeApiService.getPrefixs();
    }
    
}
