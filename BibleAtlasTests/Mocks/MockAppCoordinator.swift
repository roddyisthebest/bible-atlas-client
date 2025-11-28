//
//  MockAppCoordinator.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/18/25.
//

import XCTest
import RxSwift
import RxRelay
import RxTest
import RxBlocking

@testable import BibleAtlas

final class MockAppCoordinator: AppCoordinatorProtocol {
    func openSupportCenter() {
    }
    
    // Call counters
    private(set) var startCallCount = 0
    private(set) var logoutCallCount = 0

    // Quick flags
    var didStart: Bool { startCallCount > 0 }
    var didLogout: Bool { logoutCallCount > 0 }

    // Optional hooks for expectations
    var onStart: (() -> Void)?
    var onLogout: (() -> Void)?

    // Rx signals (원하면 테스트에서 구독해서 사용)
    let startCalled$ = PublishRelay<Void>()
    let logoutCalled$ = PublishRelay<Void>()

    func start() {
        startCallCount += 1
        onStart?()
        startCalled$.accept(())
    }

    func logout() {
        logoutCallCount += 1
        onLogout?()
        logoutCalled$.accept(())
    }

    func reset() {
        startCallCount = 0
        logoutCallCount = 0
    }
}
