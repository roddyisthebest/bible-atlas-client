//
//  CloseButton.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/26/25.
//

import UIKit

class CircleButton: UIButton {

    init(iconSystemName: String) {
           super.init(frame: .zero)
           
           self.backgroundColor = .circleButtonBkg
           
           let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
           let xmarkImage = UIImage(systemName: iconSystemName, withConfiguration: config)
           self.setImage(xmarkImage, for: .normal)
           self.tintColor = .circleIcon
           
        
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
