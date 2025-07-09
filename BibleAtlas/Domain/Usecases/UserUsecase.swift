//
//  UserUsecase.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/21/25.
//

import Foundation

protocol UserUsecaseProtocol{
    func getPlaces(limit:Int?, page:Int?, filter:PlaceFilter? ) async -> Result<ListResponse<Place>,NetworkError>
    func getProfile() async -> Result<User,NetworkError>
    
}


public struct UserUsecase:UserUsecaseProtocol{
    private let repository:UserRepositoryProtocol
    
    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    func getPlaces(limit: Int?, page: Int?, filter: PlaceFilter?) async -> Result<ListResponse<Place>, NetworkError> {
        let result = await repository.getPlaces(limit: limit, page: page, filter: filter)
        return result;
    }
    
    func getProfile() async -> Result<User, NetworkError> {
        let result = await repository.getProfile();
        return result;
    }

}

