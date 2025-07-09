//
//  IconTextButton.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/10/25.
//

import UIKit

class IconTextButton: UIButton {

    private let icon = UIView()
    private let customImageView = UIImageView()
    private let label = UILabel()
    private let stackView = UIStackView()
    private var activityIndicator: UIActivityIndicatorView?

    init(iconSystemName: String, color: UIColor, labelText: String) {
        super.init(frame: .zero)

        // 아이콘 뷰
        icon.backgroundColor = .collectionCircle
        icon.layer.cornerRadius = 15
        icon.layer.masksToBounds = true

        customImageView.image = UIImage(systemName: iconSystemName)
        customImageView.tintColor = color
        customImageView.contentMode = .scaleAspectFit

        icon.addSubview(customImageView)
        icon.snp.makeConstraints { make in
            make.width.height.equalTo(30)
        }
        customImageView.snp.makeConstraints { make in
            make.width.height.equalTo(15)
            make.center.equalToSuperview()
        }

        // 라벨
        label.text = labelText
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = color

        // 스택뷰
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 10
        stackView.addArrangedSubview(icon)
        stackView.addArrangedSubview(label)

        stackView.isUserInteractionEnabled = false
        self.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(15)
        }
        
        

        self.backgroundColor = .mainItemBkg
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            stackView.isHidden = true
            isEnabled = false

            let spinner = UIActivityIndicatorView(style: .medium)
            self.addSubview(spinner)
            spinner.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }

            spinner.startAnimating()
            activityIndicator = spinner
        } else {
            activityIndicator?.stopAnimating()
            activityIndicator?.removeFromSuperview()
            activityIndicator = nil

            stackView.isHidden = false
            isEnabled = true
        }
    }
}
