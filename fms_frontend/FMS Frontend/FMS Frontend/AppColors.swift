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
    static let primary = Color(hex: "0F1C24")        // Deep navy
    
    // Backgrounds
    static let secondaryBackground = Color(hex: "C9CFD6")
    static let screenBackground = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color.white
    
    // Text
    static let primaryText = Color.black
    static let secondaryText = Color.gray
    
    // Status
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // UI Elements
    static let divider = Color.gray.opacity(0.2)
    static let shadow = Color.black.opacity(0.05)
}
