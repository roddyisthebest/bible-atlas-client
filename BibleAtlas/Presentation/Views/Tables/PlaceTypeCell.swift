//
//  PlaceTypeCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/11/25.
//

import UIKit

class PlaceTypeCell: UICollectionViewCell {
    static let identifier = "placeTypeCell"
    
    private var nameText: String? {
        didSet{
            nameLabel.text = nameText
        }
    }
    
    private lazy var containerStackView = {
        let sv = UIStackView(arrangedSubviews: [iconWrapper, nameLabel,  numberLabel]);
        sv.axis = .vertical;
        sv.distribution = .fill;
        sv.alignment = .center;
        sv.spacing = 5;
        contentView.addSubview(sv)
        return sv;
    }()
    
    private lazy var iconWrapper = {
        let v = UIView();
        v.backgroundColor = .placeCircle;
        v.layer.cornerRadius = 25;
        v.layer.masksToBounds = true;
        v.addSubview(placeIcon)
        return v;
    }()
    
    private let placeIcon:UIImageView = {
        let icon = UIImageView(image: UIImage(named: "ground"));
        return icon;
    }()
    
    private let nameLabel = {
        let label = UILabel();
        label.text = "Water of Body"
        label.textColor = .mainText
        label.numberOfLines = 1;
        label.font = .boldSystemFont(ofSize: 16)
        label.lineBreakMode = .byTruncatingTail
        return label;
    }()
    
    
    private let numberLabel = {
        let label = UILabel();
        label.textColor = .placeDescriptionText;
        label.numberOfLines = 1;
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.text = "12 places"
        return label;
    }()
    
    func configure(text: String) {
        nameText = text;
    }
    
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }
    
    private func setupConstraints(){
        
        containerStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10);
            make.trailing.equalToSuperview().inset(10);
            
            make.top.equalToSuperview().offset(20);
            make.bottom.equalToSuperview().inset(0);

        }
        
        
        iconWrapper.snp.makeConstraints { make in
            make.height.width.equalTo(50)
        }
        
        placeIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(30)
        }
    }
    
    
}
