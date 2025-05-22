//
//  UserRepositoryProtocol.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/21/25.
//

import Foundation


protocol UserRepositoryProtocol {
    func getPlaces(limit:Int?, page:Int?, filter:PlaceFilter? ) async -> Result<ListResponse<Place>,NetworkError>
    func getProfile() async -> Result<User,NetworkError>
}
