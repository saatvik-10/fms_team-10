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
    
    // Backgrounds
    static let secondaryBackground = Color(hex: "F2F5F8")
    static let screenBackground = Color(white: 0.98)
    static let cardBackground = Color.white
    
    // Text
    static let primaryText = Color(red: 0.04, green: 0.19, blue: 0.23)
    static let secondaryText = Color.gray
    
    // Status
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warning = Color.orange
    static let error = Color(red: 0.98, green: 0.45, blue: 0.38)
    
    // Priorities
    static let priorityCritical = Color(red: 0.9, green: 0.3, blue: 0.3)
    static let priorityHigh = Color(red: 0.98, green: 0.45, blue: 0.38)
    static let priorityMedium = Color(red: 0.3, green: 0.6, blue: 0.9)
    static let priorityLow = Color.gray
    
    // UI Elements
    static let divider = Color.gray.opacity(0.1)
    static let shadow = Color.black.opacity(0.05)
    
    static let cornerRadius: CGFloat = 12
}
