import SwiftUI

extension Color {
    // MARK: - Theme Colors
    static let primary = Color(light: Color(red: 0.9, green: 0.25, blue: 0.65),
                                 dark: Color(red: 0.85, green: 0.3, blue: 0.7)) // #E640A6
    static let secondary = Color(light: Color(red: 0.13, green: 0.43, blue: 0.95),
                               dark: Color(red: 0.18, green: 0.48, blue: 1.0)) // #216DF3
    
    static let adaptiveGreen = Color(light: Color(red: 0.259, green: 0.561, blue: 0.490), dark: Color(red: 0.3, green: 0.7, blue: 0.6)) // #428F7D
    static let adaptiveRed = Color(light: Color(red: 1.0, green: 0.420, blue: 0.420), dark: Color(red: 1.0, green: 0.4, blue: 0.4)) // #FF6B6B
    
    // MARK: - Adaptive Theme Colors
    
    // Background Colors
    static let appBackground = Color(UIColor.systemBackground)
    static let cardBackground = Color(light: .white, dark: Color(UIColor.secondarySystemGroupedBackground))
    static let groupedBackground = Color(light: Color.gray.opacity(0.1), dark: Color(UIColor.tertiarySystemGroupedBackground))
    static let secondaryGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
    
    // Overlay Colors
    static let overlayBackground = Color(light: Color.black.opacity(0.4), dark: Color.gray.opacity(0.4))
    
    // Text Colors
    static let primaryText = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let tertiaryText = Color(UIColor.tertiaryLabel)
    static let quaternaryText = Color(UIColor.quaternaryLabel)
    
    // Separator Colors
    static let separator = Color(UIColor.separator)
    static let opaqueSeparator = Color(UIColor.opaqueSeparator)
    
    // Fill Colors
    static let systemFill = Color(UIColor.systemFill)
    static let secondarySystemFill = Color(UIColor.secondarySystemFill)
    static let tertiarySystemFill = Color(UIColor.tertiarySystemFill)
    static let quaternarySystemFill = Color(UIColor.quaternarySystemFill)
    
    // Input Field Colors
    static let inputBackground = Color(UIColor.tertiarySystemBackground)
    static let inputBorder = Color(UIColor.systemGray4)
    static let focusedInputBorder = primary
    
    // Status Colors (these work well in both light and dark)
    static let successColor = Color.green
    static let errorColor = Color.red
    static let warningColor = Color.orange
    static let infoColor = Color.blue
    
    // Custom semantic colors for specific use cases
    
    static var budgetProgressColor: Color {
        Color(light: primary, dark: Color(red: 0.3, green: 0.7, blue: 0.6))
    }
    
    static var overBudgetColor: Color {
        Color(light: .red, dark: Color(red: 1.0, green: 0.4, blue: 0.4))
    }
}

// MARK: - Color Initializer for Light/Dark Mode
extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}
