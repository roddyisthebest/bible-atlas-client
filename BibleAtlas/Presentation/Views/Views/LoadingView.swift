//
//  LoadingView.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/31/25.
//

import UIKit

final class LoadingView: UIActivityIndicatorView {

    init(style: UIActivityIndicatorView.Style = .large, color: UIColor? = nil) {
        super.init(style: style)
        self.hidesWhenStopped = true
        if let color = color {
            self.color = color
        }
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.hidesWhenStopped = true
    }

    func start() {
        self.startAnimating()
        self.isHidden = false
    }

    func stop() {
        self.stopAnimating()
        self.isHidden = true
    }
}

