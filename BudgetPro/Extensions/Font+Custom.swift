import SwiftUI

extension Font {    
    static func appFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .thin, .ultraLight, .light:
            return .custom("Manrope-Regular", size: size + 1)
        case .regular:
            return .custom("Manrope-Medium", size: size + 1)
        case .medium:
            return .custom("Manrope-SemiBold", size: size + 1)
        case .semibold, .bold, .heavy, .black:
            return .custom("Manrope-Bold", size: size + 1)
        default:
            return .custom("Manrope-Regular", size: size + 1)
        }
    }
}
