//
//  AppColors.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI

// MARK: - Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        switch hex.count {
        case 3:
            (a, r, g, b) = (255,
                           (int >> 8) * 17,
                           (int >> 4 & 0xF) * 17,
                           (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255,
                           int >> 16,
                           int >> 8 & 0xFF,
                           int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24,
                           int >> 16 & 0xFF,
                           int >> 8 & 0xFF,
                           int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - App Color System
struct AppColors {
    
    // Primary
    static let primary = Color(red: 0.04, green: 0.19, blue: 0.23) // #0a303a
    static let accent = Color(red: 0.04, green: 0.19, blue: 0.23)
    
    // Backgrounds
    static let secondaryBackground = Color(hex: "F2F5F8")
    static let screenBackground = Color(white: 0.98)
    static let cardBackground = Color.white
    
    // Text
    static let primaryText = Color(red: 0.04, green: 0.19, blue: 0.23)
    static let secondaryText = Color.gray
    
    // Status
    static let statusInTransit = Color.blue
    static let statusIdle = Color.gray
    static let statusMaintenance = Color.orange
    static let statusCritical = Color.red
    
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // Priority Colors
    static let priorityCritical = Color.red
    static let priorityHigh = Color.orange
    static let priorityMedium = Color.blue
    static let priorityLow = Color.gray
    
    // UI Constants
    static let defaultCornerRadius: CGFloat = 12
    static let shadow = Color.black.opacity(0.05)
    static let divider = Color.gray.opacity(0.2)
    
    // Legacy Aliases (for backward compatibility with AppTheme)
    static let activeGreen = success
    static let criticalRed = statusCritical
    static let maintenanceOrange = statusMaintenance
    static let alertRed = Color.red
    static let statusBlue = Color.blue
    static let accentBlue = Color(red: 0.44, green: 0.66, blue: 0.86)
    static let background = screenBackground
    static let secondary = secondaryText
    static let textPrimary = primaryText
    static let textSecondary = secondaryText
    static let textInverted = Color.white
    static let darkCardBackground = primary
    
    static func cardShadow() -> some ViewModifier {
        CardShadowModifier()
    }
}

struct CardShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
    }
}
