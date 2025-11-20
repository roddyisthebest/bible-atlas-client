//
//  EmptyLabel.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/1/25.
//

import UIKit

class EmptyLabel: UILabel {
    
    init(text:String? = L10n.Common.empty){
        super.init(frame: .zero);
        self.text = text;
        textColor = .mainLabelText;
        font = .systemFont(ofSize: 16);
        textAlignment = .center;
    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
