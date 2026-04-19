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
    static let primary = Color(hex: "0a303a")        // Brand teal-navy
    
    // Backgrounds
    static let secondaryBackground = Color(hex: "C9CFD6")
    static let screenBackground = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color.white
    
    // Text
    static let primaryText = Color(hex: "0a303a")
    static let secondaryText = Color.gray
    
    // Status
    static let success = Color(hex: "27AE60")
    static let warning = Color(hex: "F2994A")
    static let error = Color(hex: "EB5757")
    
    // Priorities
    static let priorityCritical = Color(hex: "8B0000") // Deep Red
    static let priorityHigh = Color(hex: "C0392B")     // Bright Red
    static let priorityMedium = Color(hex: "0a303a ")   // Blue
    static let priorityLow = Color(hex: "7F8C8D")      // Grey
    
    // UI Elements
    static let divider = Color.gray.opacity(0.1)
    static let shadow = Color.black.opacity(0.06)
}
