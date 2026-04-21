import SwiftUI

struct FleetStatusRingView: View {
    let active: Int
    let maintenance: Int
    let idle: Int
    let critical: Int
    
    private var total: Int {
        active + maintenance + idle + critical
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                // Background Ring
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 14)
                
                // Segments
                if total > 0 {
                    RingSegment(start: 0, end: Double(active) / Double(total), color: AppColors.statusInTransit)
                    RingSegment(start: Double(active) / Double(total), end: Double(active + idle) / Double(total), color: AppColors.statusIdle)
                    RingSegment(start: Double(active + idle) / Double(total), end: Double(active + idle + maintenance) / Double(total), color: AppColors.statusMaintenance)
                    RingSegment(start: Double(active + idle + maintenance) / Double(total), end: 1.0, color: AppColors.statusCritical)
                }
                
                VStack(spacing: -1) {
                    Text("\(total)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(AppColors.primary)
                    Text("VEHICLES")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 120, height: 120)
            
            Spacer()
            
            // Legend (Vertical on the right)
            VStack(alignment: .leading, spacing: 10) {
                LegendItem(color: AppColors.statusInTransit, label: "Active", count: active)
                LegendItem(color: AppColors.statusIdle, label: "Idle", count: idle)
                LegendItem(color: AppColors.statusMaintenance, label: "Maintenance", count: maintenance)
                LegendItem(color: AppColors.statusCritical, label: "Critical", count: critical)
            }
            .frame(width: 140) 
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.primary)
        }
    }
}

struct RingSegment: View {
    let start: Double
    let end: Double
    let color: Color
    
    var body: some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .animation(.easeInOut(duration: 1.0), value: end)
    }
}

#Preview {
    FleetStatusRingView(active: 12, maintenance: 4, idle: 3, critical: 1)
        .padding()
}
