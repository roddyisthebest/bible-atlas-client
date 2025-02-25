//
//  CollectionViewCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/10/25.
//

import UIKit

class ActivitySmallCell: UICollectionViewCell {
    
    static let identifier = "ActivitySmallCell"

    private let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = UIColor.darkGray
        contentView.layer.cornerRadius = 10
        contentView.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    func configure(text: String) {
        label.text = text
    }
}
