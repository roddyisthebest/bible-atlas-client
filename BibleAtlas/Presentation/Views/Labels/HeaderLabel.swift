//
//  HeaderLabel.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/26/25.
//

import UIKit

final class HeaderLabel: UILabel {
    init(text:String){
        super.init(frame: .zero)
        self.text = text
        self.textColor = .mainText
        self.font = .boldSystemFont(ofSize: 24);

    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
