//
//  MockWindowService.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
@testable import BibleAtlas

final class MockWindowService: WindowServiceProtocol {
    private(set) var attachedViewControllers: [UIViewController] = []

    func attach(_ rootViewController: UIViewController) {
        attachedViewControllers.append(rootViewController)
    }
}
