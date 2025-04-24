//
//  GuideButton.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/24/25.
//

import UIKit

final class GuideButton: UIButton {
    init(titleText:String){

        super.init(frame: .zero);
        
        self.backgroundColor = .mainButtonBkg;
        self.snp.makeConstraints { make in
            make.height.equalTo(64)
        }
        self.setTitle(titleText, for: .normal)
        self.setTitleColor(.primaryBlue, for: .normal)
        
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = true;
        self.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)

    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
