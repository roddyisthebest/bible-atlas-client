//
//  CloseButton.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/26/25.
//

import UIKit

class CircleButton: UIButton {
    
    private let loadingView = LoadingView(style: .medium)
    private var originalImage: UIImage?

    init(iconSystemName: String) {
        super.init(frame: .zero)

        self.backgroundColor = .circleButtonBkg

        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        let icon = UIImage(systemName: iconSystemName, withConfiguration: config)
        self.originalImage = icon
        self.setImage(icon, for: .normal)
        self.tintColor = .circleIcon

        self.snp.makeConstraints { make in
            make.width.height.equalTo(30)
        }

        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true

        setupLoadingView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLoadingView() {
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        loadingView.isHidden = true
    }
    
    public func startLoading() {
        self.isEnabled = false
        self.setImage(nil, for: .normal)
        loadingView.start()
    }

    public func stopLoading() {
        self.isEnabled = true
        self.setImage(originalImage, for: .normal)
        loadingView.stop()
    }
}


