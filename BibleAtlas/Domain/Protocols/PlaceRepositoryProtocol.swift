//
//  PlaceRepositoryProtocol.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/28/25.
//

import Foundation


protocol PlaceRepositoryProtocol {
    func getPlaces(limit:Int?, page:Int?, placeTypeId:Int?, name:String?, prefix:String?) async -> Result<ListResponse<Place>,NetworkError>
    
    func getPlaceTypes(limit:Int?, page:Int?) async -> Result<ListResponse<PlaceTypeWithPlaceCount>,NetworkError>
    
    func getPrefixs() async -> Result<ListResponse<PlacePrefix>,NetworkError>
}



