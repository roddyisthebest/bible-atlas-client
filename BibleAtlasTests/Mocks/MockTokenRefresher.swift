//
//  MockTokenRefresher.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import XCTest
@testable import BibleAtlas

final class MockTokenRefresher: TokenRefresherProtocol {
    enum Outcome { case success(String), failure }
    var outcome: Outcome = .success("new-token")
    func refresh() async -> Result<RefreshedData, NetworkError> {
        switch outcome {
        case .success(let newToken):
            return .success(.init(accessToken: newToken))
        case .failure:
            return .failure(.serverError(401))
        }
    }
}
