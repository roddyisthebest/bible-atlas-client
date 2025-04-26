//
//  CloseButton.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/26/25.
//

import UIKit

class CloseButton: UIButton {

    init() {
           super.init(frame: .zero)
           
           self.backgroundColor = .closeButtonBkg
           
           let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
           let xmarkImage = UIImage(systemName: "xmark", withConfiguration: config)
           self.setImage(xmarkImage, for: .normal)
           self.tintColor = .closeIcon
           
        
            self.snp.makeConstraints { make in
                make.width.height.equalTo(30);
            }
            self.layer.cornerRadius = 15;
            self.layer.masksToBounds = true;
        
           
        


    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
