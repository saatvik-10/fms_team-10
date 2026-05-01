//
//  CommonComponents.swift
//  Created by Saatvik Madan
//

import SwiftUI

// MARK: - PrimaryButton
// Unified PrimaryButton component to avoid build conflicts
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var backgroundColor: Color = AppColors.primary
    var textColor: Color = .white
    let action: () -> Void
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .accessibilityLabel("Loading")
                } else if let icon = icon {
                    Image(systemName: icon)
                        .accessibilityHidden(true) // decorative; label covers it
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44) // Minimum touch target
            .padding(.vertical, 16)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(12)
        }
        .accessibilityLabel(title)
    }
}

// MARK: - AppProfileInfoRow
struct AppProfileInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
        .frame(minHeight: 44) // Minimum touch target height
        // VoiceOver: combine label + value into one readable element
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
