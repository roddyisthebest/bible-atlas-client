//
//  MockErrorHandler.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/25/25.
//

import XCTest
@testable import BibleAtlas


final class MockErrorHandler: ErrorHandlerServiceProtocol {
    private(set) var didLogout = false
    func logoutDueToExpiredSession() async {
        didLogout = true
    }
}
