//
//  WindowHandlerService.swift
//  BibleAtlas
//
//  Created by 배성연 on 7/20/25.
//

import UIKit

protocol WindowServiceProtocol {
    func attach(_ viewController: UIViewController)
}

final class RealWindowService: WindowServiceProtocol {
    private let window: UIWindow?
    
    init(window: UIWindow?) {
        self.window = window
    }

    func attach(_ viewController: UIViewController) {
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }
}

final class FakeWindowService: WindowServiceProtocol {
    private(set) var attachedViewController: UIViewController?

    func attach(_ viewController: UIViewController) {
        self.attachedViewController = viewController
    }
}
