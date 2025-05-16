//
//  TransparentPanModalPresentationController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/5/25.
//

import PanModal
import UIKit
final class TransparentPanModalPresentationController: PanModalPresentationController {
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView?.backgroundColor = .clear
        dimmingView?.alpha = 0
    }
}
