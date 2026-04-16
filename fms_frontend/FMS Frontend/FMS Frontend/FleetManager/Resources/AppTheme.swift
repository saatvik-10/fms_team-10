import SwiftUI

struct AppTheme {
    // MARK: - Colors
    static let primary = Color.black
    static let secondary = Color.gray
    static let background = Color(white: 0.98) // Very light gray background
    static let cardBackground = Color.white
    static let darkCardBackground = Color(white: 0.1) // Black for Maintenance card
    
    // Status Colors (from FleetOps image)
    static let activeGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let maintenanceOrange = Color.orange
    static let criticalRed = Color(red: 0.9, green: 0.1, blue: 0.1)
    static let alertRed = Color(red: 0.9, green: 0.3, blue: 0.3)
    static let statusBlue = Color(red: 0.3, green: 0.6, blue: 0.9)
    
    static let accentBlue = Color(red: 0.44, green: 0.66, blue: 0.86)
    
    // MARK: - Text Colors
    static let textPrimary = Color.black
    static let textSecondary = Color.gray
    static let textInverted = Color.white
    
    // MARK: - Layout Constants
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 20
    static let shadowRadius: CGFloat = 8
    static let shadowOffset = CGSize(width: 0, height: 2)
    static let shadowOpacity: Double = 0.05
    
    // MARK: - Shadows
    static func cardShadow() -> some ViewModifier {
        CardShadowModifier()
    }
}

struct CardShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(AppTheme.shadowOpacity), radius: AppTheme.shadowRadius, x: 0, y: 2)
    }
}

extension View {
    func fmsCardStyle() -> some View {
        self
            .padding(AppTheme.cardPadding)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .modifier(AppTheme.cardShadow())
    }
    
    func fmsDarkCardStyle() -> some View {
        self
            .padding(AppTheme.cardPadding)
            .background(AppTheme.darkCardBackground)
            .cornerRadius(AppTheme.cornerRadius)
    }
}
