//
//  IconTextButton.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/10/25.
//

import UIKit

class IconTextButton: UIButton {
    
    init(iconSystemName:String, color:UIColor, labelText:String){
        super.init(frame: .zero)
        
        let icon = UIView()
        icon.backgroundColor = .collectionCircle
        icon.layer.cornerRadius = 15
        icon.layer.masksToBounds = true

        let imageView = UIImageView()
        
        imageView.image = UIImage(systemName: iconSystemName)
        imageView.tintColor = color
        imageView.contentMode = .scaleAspectFit
        
        
        icon.addSubview(imageView);

        icon.snp.makeConstraints { make in
            make.width.height.equalTo(30) // 아이콘 사이즈
        }
        
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(15)
            make.center.equalToSuperview()
        }
        
        
        let label = UILabel();
        label.text = labelText
        label.font = .systemFont(ofSize: 15, weight: .semibold);
        label.textColor = color;

        
        let stackView = UIStackView(arrangedSubviews: [icon, label]);
        stackView.axis = .horizontal
        stackView.distribution = .fill;
        stackView.alignment = .center;
        stackView.spacing = 10;
        
        self.addSubview(stackView);

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15);
            make.leading.equalToSuperview().offset(20);
            make.trailing.equalToSuperview().inset(20);
            make.bottom.equalToSuperview().inset(15);
        }


        
        self.backgroundColor = .mainItemBkg
        self.layer.cornerRadius = 8;
        self.layer.masksToBounds = true;
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
