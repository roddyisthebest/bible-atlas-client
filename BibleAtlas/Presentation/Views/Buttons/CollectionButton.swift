//
//  CollectionButton.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/23/25.
//

import UIKit

final class CollectionButton: UIButton {

    init(iconSystemName: String, mainText: String, subText: String) {
            super.init(frame: .zero)

            let icon = UIImageView(image: UIImage(systemName: iconSystemName))
            icon.tintColor = .primaryBlue
            icon.contentMode = .scaleAspectFit
            icon.snp.makeConstraints { $0.size.equalTo(28) }

            let circle = UIView()
            circle.backgroundColor = .collectionCircle
            circle.layer.cornerRadius = 30
            circle.layer.masksToBounds = true
            circle.addSubview(icon)
            icon.snp.makeConstraints { $0.center.equalToSuperview() }
            circle.snp.makeConstraints { $0.size.equalTo(60) }

            let titleLabel = UILabel()
            titleLabel.text = mainText
            titleLabel.font = .systemFont(ofSize: 14, weight: .bold)
            titleLabel.textColor = .mainText

            let subtitleLabel = UILabel()
            subtitleLabel.text = subText
            subtitleLabel.font = .systemFont(ofSize: 12)
            subtitleLabel.textColor = .mainLabelText

            let stack = UIStackView(arrangedSubviews: [circle, titleLabel, subtitleLabel])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 8

            addSubview(stack)
            
            stack.snp.makeConstraints { $0.edges.equalToSuperview() }
            stack.isUserInteractionEnabled = false 

        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

}
