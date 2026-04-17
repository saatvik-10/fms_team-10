import SwiftUI
import Charts

// MARK: - FleetOps Metric Item (Active, Maintenance, etc.)
struct FleetOpsMetricItem: View {
    let title: String
    let value: Int
    let trend: String?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%02d", value))
                    .font(.system(size: 32, weight: .bold))
                
                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.activeGreen)
                }
            }
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(color)
                    .frame(width: 40, height: 4) // Fixed width progress line like in image
            }
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
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(assessment.routeFrom) →")
                            .font(.system(size: 11, weight: .medium))
                        Text(assessment.routeTo)
                            .font(.system(size: 11, weight: .medium))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ETA")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                        Text(assessment.etaTime)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(assessment.etaTime == "Delayed" ? AppTheme.criticalRed : AppTheme.textPrimary)
                        Text(assessment.etaDay)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
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
        .modifier(AppTheme.cardShadow())
        .frame(width: 260)
    }
    
    var statusColor: Color {
        switch assessment.status {
        case .inTransit: return AppTheme.activeGreen
        case .alertReceived: return AppTheme.alertRed
        case .restStop: return AppTheme.statusBlue
        case .scheduled: return AppTheme.statusBlue
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
    let alerts: [MaintenanceAlert]
    
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
                                .fill(alert.status == "Urgent" ? AppTheme.criticalRed : Color.white.opacity(0.2))
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
                        .stroke(AppTheme.criticalRed, style: StrokeStyle(lineWidth: 12, lineCap: .round))
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
                        Circle().fill(AppTheme.criticalRed).frame(width: 6, height: 6)
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
        .background(AppTheme.darkCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - CO2 Emissions Chart
import Charts

struct FleetOpsEmissionsChart: View {
    let data: [EmissionData]
    var showNavigation: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showNavigation {
                HStack {
                    Spacer()
                    NavigationLink(destination: FleetAnalyticsView()) {
                        HStack {
                            Text("Current Week")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 12))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                        .foregroundColor(AppTheme.primary)
                    }
                }
            }
            
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Emissions", item.value)
                    )
                    .foregroundStyle(item.isCurrent ? AppTheme.primary : AppTheme.secondary.opacity(0.2))
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        if item.isCurrent {
                            Text(String(format: "%.1f", item.value))
                                .font(.system(size: 10, weight: .bold))
                                .padding(.bottom, 2)
                        }
                    }
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
        .modifier(AppTheme.cardShadow())
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
            .foregroundColor(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(12)
            .modifier(AppTheme.cardShadow())
        }
    }
}
