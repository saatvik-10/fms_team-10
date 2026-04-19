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
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(14)
        }
    }
}
