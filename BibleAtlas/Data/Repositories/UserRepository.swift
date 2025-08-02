//
//  UserRepository.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/21/25.
//

import Foundation

public struct UserRepository:UserRepositoryProtocol{
    
    let userApiService:UserApiServiceProtocol;
    
    func getPlaces(limit: Int?, page: Int?, filter: PlaceFilter?) async -> Result<ListResponse<Place>, NetworkError> {
        return await userApiService.getPlaces(limit: limit, page: page, filter: filter)
    }
    
    func getMyCollectionPlaceIds() async -> Result<MyCollectionPlaceIds, NetworkError>{
        return await userApiService.getMyCollectionPlaceIds()
    }

    func getProfile() async -> Result<User, NetworkError> {
        return await userApiService.getProfile()
    }
}
