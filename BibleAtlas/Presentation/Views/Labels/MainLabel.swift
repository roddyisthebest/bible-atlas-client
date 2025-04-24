//
//  CollectionLabel.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/23/25.
//

import UIKit

final class MainLabel: UILabel {

    init(text:String){
        super.init(frame: .zero)
       
        
        self.text = text
        self.textColor = .mainLabelText
        self.font = .boldSystemFont(ofSize: 14);

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
