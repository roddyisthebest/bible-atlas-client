//
//  UIViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/1/25.
//

import UIKit

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        } else {
            return self
        }
    }
}
