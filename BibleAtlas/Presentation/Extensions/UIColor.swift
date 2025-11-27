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
    
    static let circleButtonBkg = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#37393C") : UIColor(hex: "#E7E7E7")
    }
    
    static let primaryViolet = UIColor(hex: "#8144FC")
    
    // 100%
    static let badge100 = UIColor(hex: "#8144FC")
    // 90–70%
    static let badge90to70 = UIColor(hex: "#44C2FC") // 시안블루
    // 60–40%
    static let badge60to40 = UIColor(hex: "#FFC857") // 앰버(밝음)
    // 30–0%
    static let badge30to0 = UIColor(hex: "#FF3B30")  // 레드

    
    static let ancientBadgeBkg = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#78716C") // 더 밝은 웜그레이(다크 배경에서 또렷)
            : UIColor(hex: "#FFE7CC")
        }

        static let ancientBadgeText = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#FFFFFF")  // 밝은 배경 아니므로 화이트 유지
            : UIColor(hex: "#FF9F0A")
        }

        static let modernBadgeBkg = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#6B7280") // 밝은 쿨그레이(ancient와 톤 분리)
            : UIColor(hex: "#DAF5E6")
        }

        static let modernBadgeText = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#FFFFFF")
            : UIColor(hex: "#34C759")
        }
    
    static let collectionCircle = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#49494B") : UIColor(hex: "#EBEBEB")
    }
    
    
    static let searchCircle = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#969696") : UIColor(hex: "#B7B7B5")
    }
    
    static let placeCircle = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#49494B") : UIColor(hex: "#EBEBEB")
    }
    
    static let primaryBlue = UIColor(hex: "#007BFE")
    
    static let primaryRed = UIColor(hex:"#FF382B")
    
    static let mainLabelText = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#9A9DA0") : UIColor(hex: "#868782")
    }
    
    static let mainLabelLine = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#37393C") : UIColor(hex: "#E9E9E9")
    }
    
    static let mainText = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#FFFFFF") : UIColor(hex: "#000000")
    }
    
    static let invertedMainText = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "#000000")
            : UIColor(hex: "#FFFFFF")
    }
    
    static let collectionSubText = UIColor(hex: "#868782")
    
    static let placeDescriptionText = UIColor(hex: "#868782")
    
    static let detailLabelText = UIColor(hex:"#999999")
    
    static let circleIcon = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#9B9C9E") : UIColor(hex: "#6C6C6C")
    }
    
   
    static let dividerBkg = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#5F5F5F") : UIColor(hex: "#D7D7D7")
    }
    
    
    
}
