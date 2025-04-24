//
//  UIColor.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

import UIKit

extension UIColor {
    /// Hex 코드로 UIColor 생성 (예: UIColor(hex: "#FF5733"))
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}



extension UIColor {
    static let mainBkg = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#232527") : UIColor(hex: "#F7F7F6")
    }
    
    static let searchBarBkg = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#37393C") : UIColor(hex: "#E9E9E9")
    }
    
    static let userAvatarBkg = UIColor(hex:"#A1A7B4")
    
    static let mainItemBkg = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#2C2C2E") : UIColor(hex: "#FFFFFF")
    }

    static let focusedMainItemBkg = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#3F3F3F") : UIColor(hex: "#D6D6D6")
    }
    
    static let mainButtonBkg = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#313437") : UIColor(hex: "#EBEBEB")
    }

    static let collectionCircle = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#49494B") : UIColor(hex: "#EBEBEB")
    }
    
    
    static let searchCircle = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#969696") : UIColor(hex: "#B7B7B5")
    }
    
    
    static let primaryBlue = UIColor(hex: "#007BFE")
    
    static let mainLabelText = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#9A9DA0") : UIColor(hex: "#868782")
    }
    
    static let mainText = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#FFFFFF") : UIColor(hex: "#000000")
    }
    
    static let collectionSubText = UIColor(hex: "#868782")
    
}
