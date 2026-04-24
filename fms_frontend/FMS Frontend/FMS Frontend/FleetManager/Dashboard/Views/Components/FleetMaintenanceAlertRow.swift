import SwiftUI

struct FleetMaintenanceAlertRow: View {
    let alert: FleetMaintenanceAlert
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(alertColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: alert.iconName)
                    .foregroundColor(alertColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primary)
                Text(alert.detail)
                    .font(AppFonts.footnote)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.gray.opacity(0.3))
        }
        .padding(.vertical, 8)
    }
    
    private var alertColor: Color {
        AppColors.statusCritical
    }
}
