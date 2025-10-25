import SwiftUI

extension Font {
    static func appFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .thin:
            return .custom("Sora-Thin", size: size)
        case .ultraLight:
            return .custom("Sora-ExtraLight", size: size)
        case .light:
            return .custom("Sora-Light", size: size)
        case .regular:
            return .custom("Sora-Regular", size: size)
        case .medium:
            return .custom("Sora-Medium", size: size)
        case .semibold:
            return .custom("Sora-SemiBold", size: size)
        case .bold:
            return .custom("Sora-Bold", size: size)
        case .heavy, .black:
            return .custom("Sora-ExtraBold", size: size)
        default:
            return .custom("Sora-Regular", size: size)
        }
    }
}
