import SwiftUI
import Charts

// MARK: - Fleet Status Metrics Grid (Full Width)
struct FleetStatusMetricsGrid: View {
    let active: Int
    let idle: Int
    let maintenance: Int
    let scheduled: Int
    
    var body: some View {
        HStack(spacing: 20) {
            FleetOpsMetricItem(title: "In Transit", value: active, color: AppColors.statusInTransit)
            FleetOpsMetricItem(title: "Scheduled", value: scheduled, color: AppColors.statusInTransit.opacity(0.5))
            FleetOpsMetricItem(title: "Idle", value: idle, color: AppColors.statusIdle)
            FleetOpsMetricItem(title: "Maintenance", value: maintenance, color: AppColors.statusMaintenance)
        }
        .padding(24)
        .background(AppColors.cardBackground)
        .cornerRadius(AppColors.defaultCornerRadius)
        .modifier(AppColors.cardShadow())
    }
}

// MARK: - FleetOps Metric Item (Active, Maintenance, etc.)
struct FleetOpsMetricItem: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
            
            Text(String(format: "%02d", value))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Smart Fleet Assessment Card
struct FleetOpsAssessmentCard: View {
    let assessment: SmartFleetAssessment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image with Overlay
            ZStack(alignment: .bottomLeading) {
                // Background Image Placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 180)
                    .cornerRadius(12)
                
                // Overlay Gradient
                LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(assessment.truckName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(assessment.truckID)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(12)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ROUTE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(assessment.routeFrom) →")
                            .font(.system(size: 11, weight: .medium))
                        Text(assessment.routeTo)
                            .font(.system(size: 11, weight: .medium))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ETA")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.textSecondary)
                        Text(assessment.etaTime)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(assessment.etaTime == "Delayed" ? AppColors.criticalRed : AppColors.textPrimary)
                        Text(assessment.etaDay)
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                // Status Pill
                HStack {
                    Text(statusText.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(statusColor)
                    Spacer()
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(statusColor.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
        .frame(width: 260)
    }
    
    var statusColor: Color {
        switch assessment.status {
        case .inTransit: return AppColors.activeGreen
        case .alertReceived: return AppColors.alertRed
        case .restStop: return AppColors.statusBlue
        case .scheduled: return AppColors.statusBlue
        }
    }
    
    var statusText: String {
        switch assessment.status {
        case .inTransit: return "In Transit"
        case .alertReceived: return "Critical: Engine Overheat" // Example specific alert
        case .restStop: return "Rest Stop"
        case .scheduled: return "Scheduled"
        }
    }
}

// MARK: - Maintenance & Priority Dark Card
struct MaintenancePriorityDarkCard: View {
    let summary: String
    let criticalMass: Double
    let alerts: [FleetMaintenanceAlert]
    
    var body: some View {
        HStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 10) {
                Text(summary)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                
                VStack(spacing: 12) {
                    ForEach(alerts) { alert in
                        HStack(spacing: 15) {
                            Rectangle()
                                .fill(alert.status == "Urgent" ? AppColors.criticalRed : Color.white.opacity(0.2))
                                .frame(width: 3, height: 40)
                            
                            Image(systemName: alert.iconName)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(alert.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Text(alert.detail)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 10)
            }
            
            Spacer()
            
            // Circular Gauge
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: criticalMass)
                        .stroke(AppColors.criticalRed, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(criticalMass * 100))%")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Text("CRITICAL MASS")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(width: 140, height: 140)
                
                HStack(spacing: 30) {
                    Label {
                        Text("04 URGENT").font(.system(size: 10, weight: .bold))
                    } icon: {
                        Circle().fill(AppColors.criticalRed).frame(width: 6, height: 6)
                    }
                    Label {
                        Text("14 SCHEDULED").font(.system(size: 10, weight: .bold))
                    } icon: {
                        Circle().fill(Color.white.opacity(0.4)).frame(width: 6, height: 6)
                    }
                }
                .foregroundColor(.white)
            }
            .padding(.trailing, 20)
        }
        .padding(30)
        .background(AppColors.darkCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - CO2 Emissions Chart
import Charts

struct FleetOpsEmissionsChart: View {
    let data: [EmissionData]
    var showNavigation: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Emissions", item.value)
                    )
                    .foregroundStyle(item.isCurrent ? AppColors.primary : AppColors.secondary.opacity(0.2))
                    .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.gray)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 150)
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
    }
}

struct FleetCategoryStatItem: View {
    let icon: String
    let title: String
    let value: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(white: 0.2))
                Spacer()
                Text(value)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.black)
            }
            
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.gray)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.05))
                        .frame(height: 3)
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Action Button
struct FleetOpsActionButton: View {
    let title: String
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(12)
            .modifier(AppColors.cardShadow())
        }
    }
}
