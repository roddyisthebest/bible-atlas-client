import UIKit

extension UIFont {
    /// SF Pro Rounded 폰트. iOS 시스템 rounded 디자인이 있으면 그걸 쓰고, 없으면 일반 system font fallback.
    static func rounded(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
