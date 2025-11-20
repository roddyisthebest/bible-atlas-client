//
//  ChevronButton.swift
//  BibleAtlas
//
//  Created by 배성연 on 11/15/25.
//

import UIKit

final class ChevronButton: UIButton {
    
    private let textSize = 13.0
    private let iconSize = 9.0
    
    init(titleText: String) {
        super.init(frame: .zero)
        
        setupStyle(titleText: titleText)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTitleText(_ text: String) {
        if #available(iOS 15.0, *) {
            var config = self.configuration ?? UIButton.Configuration.plain()
            var attr = AttributeContainer()
            attr.font = .systemFont(ofSize: textSize, weight: .regular)
            config.attributedTitle = AttributedString(text, attributes: attr)
            self.configuration = config
        } else {
            setTitle(text, for: .normal)
            titleLabel?.font = .systemFont(ofSize: textSize, weight: .regular)
        }
    }

    private func setupStyle(titleText: String) {
        // 배경색 디버그용이면 빼도 됨
        // self.backgroundColor = .black
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            
            // 🔻 패딩 완전 제거
            config.contentInsets = .zero
            
            // 제목
            var titleAttr = AttributeContainer()
            titleAttr.font = .systemFont(ofSize: textSize, weight: .regular)
            config.attributedTitle = AttributedString(titleText, attributes: titleAttr)
            
            // 아이콘 (chevron) 크기
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .regular)
            config.image = UIImage(systemName: "chevron.right")?.withConfiguration(symbolConfig)
            config.preferredSymbolConfigurationForImage = symbolConfig
            
            config.imagePlacement = .trailing
            config.imagePadding = 4   // 텍스트-아이콘 간격만 유지
            
            config.baseForegroundColor = .mainText
            
            self.configuration = config
        } else {
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .regular)
            
            setTitle(titleText, for: .normal)
            setTitleColor(.mainText, for: .normal)
            titleLabel?.font = .systemFont(ofSize: textSize, weight: .regular)
            
            let image = UIImage(systemName: "chevron.right")?.withConfiguration(symbolConfig)
            setImage(image, for: .normal)
            tintColor = .mainText
            
            semanticContentAttribute = .forceRightToLeft
            contentHorizontalAlignment = .left
            
            // 텍스트-아이콘 간격만 살짝
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            
            // 🔻 iOS 15 미만도 패딩 제거
            contentEdgeInsets = .zero
        }
        
        contentHorizontalAlignment = .left
    }
}
