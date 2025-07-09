//
//  TokenRefresherProtocol.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/26/25.
//

import Foundation

protocol TokenRefresherProtocol {
    func refresh() async -> Result<RefreshedData, NetworkError> // returns new accessToken
}
