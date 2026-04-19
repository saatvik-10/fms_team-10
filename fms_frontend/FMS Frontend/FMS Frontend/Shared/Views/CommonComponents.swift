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
            .cornerRadius(12)
        }
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
    }
}
