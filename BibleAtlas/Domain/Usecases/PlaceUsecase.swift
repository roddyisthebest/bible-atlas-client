//
//  PlaceUsecase.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/28/25.
//

import Foundation

protocol PlaceUsecaseProtocol {
    func getPlaces(limit:Int?, page:Int?, placeTypeId:Int?, name:String?) async -> Result<ListResponse<Place>,NetworkError>
    
    func getPlaceTypes(limit:Int?, page:Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>,NetworkError>
    
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>,NetworkError>
}


public struct PlaceUsecase:PlaceUsecaseProtocol{
    private let repository:PlaceRepositoryProtocol
    
    init(repository: PlaceRepositoryProtocol) {
        self.repository = repository
    }
    
    
    func getPlaces(limit: Int?, page: Int?, placeTypeId: Int?, name: String?) async -> Result<ListResponse<Place>, NetworkError> {
        return await repository.getPlaces(limit: limit, page: page, placeTypeId: placeTypeId, name: name)
    }
    
    func getPlaceTypes(limit: Int?, page: Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>, NetworkError> {
        return await repository.getPlaceTypes(limit: limit, page: page)
    }
    
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>, NetworkError> {
        return await repository.getPrefixs();
    }
    
}
