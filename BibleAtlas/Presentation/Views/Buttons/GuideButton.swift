//
//  GuideButton.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/24/25.
//

import UIKit

final class GuideButton: UIButton {
    private var originalTitle: String?
    private var activityIndicator: UIActivityIndicatorView?

    init(titleText: String) {
        super.init(frame: .zero)
        self.originalTitle = titleText;
        self.backgroundColor = .mainButtonBkg
        self.snp.makeConstraints { make in
            make.height.equalTo(64)
        }
        self.setTitle(titleText, for: .normal)
        self.setTitleColor(.primaryBlue, for: .normal)
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        self.isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            originalTitle = title(for: .normal)
            setTitle(nil, for: .normal)
            isEnabled = false

            let spinner = UIActivityIndicatorView(style: .medium)
            addSubview(spinner)
            spinner.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }

            spinner.startAnimating()
            activityIndicator = spinner
        } else {
            setTitle(originalTitle, for: .normal)
            isEnabled = true
            activityIndicator?.stopAnimating()
            activityIndicator?.removeFromSuperview()
            activityIndicator = nil
        }
    }

}
