import SwiftUI
import Charts

// MARK: - Fleet Status Metrics Grid (Full Width)
struct FleetStatusMetricsGrid: View {
    let active: Int
    let idle: Int
    let maintenance: Int
    let scheduled: Int
    
    var body: some View {
        HStack(spacing: 0) {
            FleetOpsMetricItem(title: "In Transit", value: active, color: AppTheme.statusInTransit)
            Divider().frame(height: 40).padding(.horizontal, 15)
            FleetOpsMetricItem(title: "Scheduled", value: scheduled, color: AppTheme.statusInTransit.opacity(0.5))
            Divider().frame(height: 40).padding(.horizontal, 15)
            FleetOpsMetricItem(title: "Idle", value: idle, color: AppTheme.statusIdle)
            Divider().frame(height: 40).padding(.horizontal, 15)
            FleetOpsMetricItem(title: "Maintenance", value: maintenance, color: AppTheme.statusMaintenance)
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.defaultCornerRadius)
        .modifier(AppTheme.cardShadow())
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
                .font(AppFonts.caption2)
                .foregroundColor(AppTheme.textSecondary)
            
            Text(String(format: "%02d", value))
                .font(AppFonts.title1)
                .foregroundColor(AppTheme.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // VoiceOver: read as combined unit e.g. "In Transit: 05"
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
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
                    .frame(height: 100)
                    .cornerRadius(12)
                
                // Overlay Gradient
                LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(assessment.truckName)
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                    Text(assessment.truckID)
                        .font(AppFonts.caption1)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(12)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ROUTE")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(assessment.routeFrom) →")
                            .font(AppFonts.footnote)
                        Text(assessment.routeTo)
                            .font(AppFonts.footnote)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ETA")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                        Text(assessment.etaTime)
                            .font(AppFonts.footnote)
                            .foregroundColor(assessment.etaTime == "Delayed" ? AppTheme.criticalRed : AppTheme.textPrimary)
                        Text(assessment.etaDay)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                // Status Pill
                HStack {
                    Text(statusText.uppercased())
                        .font(AppFonts.caption2)
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
    let alerts: [FleetMaintenanceAlert]
    
    var body: some View {
        HStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 10) {
                Text(summary)
                    .font(AppFonts.body)
                    .foregroundColor(.white.opacity(0.6))
                
                VStack(spacing: 12) {
                    ForEach(alerts) { alert in
                        HStack(spacing: 15) {
                            Rectangle()
                                .fill(alert.status == "Urgent" ? AppTheme.criticalRed : Color.white.opacity(0.2))
                                .frame(width: 3, height: 40)
                                .accessibilityHidden(true)
                            
                            Image(systemName: alert.iconName)
                                .foregroundColor(.white)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(alert.title)
                                    .font(AppFonts.headline)
                                    .foregroundColor(.white)
                                Text(alert.detail)
                                    .font(AppFonts.caption1)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        // VoiceOver: combine alert row as one element
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(alert.status == "Urgent" ? "Urgent alert" : "Scheduled alert"): \(alert.title). \(alert.detail)")
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
                            .font(AppFonts.title1)
                            .foregroundColor(.white)
                        Text("CRITICAL MASS")
                            .font(AppFonts.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(width: 140, height: 140)
                // VoiceOver: describe gauge as a value
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Maintenance critical mass gauge")
                .accessibilityValue("\(Int(criticalMass * 100)) percent")
                
                HStack(spacing: 30) {
                    Label {
                        Text("04 URGENT").font(AppFonts.caption2)
                    } icon: {
                        Circle().fill(AppTheme.criticalRed).frame(width: 6, height: 6)
                            .accessibilityHidden(true)
                    }
                    .accessibilityLabel("4 urgent maintenance items")
                    Label {
                        Text("14 SCHEDULED").font(AppFonts.caption2)
                    } icon: {
                        Circle().fill(Color.white.opacity(0.4)).frame(width: 6, height: 6)
                            .accessibilityHidden(true)
                    }
                    .accessibilityLabel("14 scheduled maintenance items")
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
struct FleetOpsEmissionsChart: View {
    let data: [EmissionData]
    @State private var selectedTimeframe = "Weekly"
    let timeframes = ["Weekly", "Monthly", "Yearly"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("CO2 Emissions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                
                Spacer()
                
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(timeframes, id: \.self) { timeframe in
                        Text(timeframe).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Emissions", item.value)
                    )
                    .foregroundStyle(item.isCurrent ? AppTheme.primary : AppTheme.primary.opacity(0.1))
                    .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(AppFonts.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 150)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
    }
}

// MARK: - Fleet Mileage Chart (Horizontal)
struct FleetMileageChart: View {
    let data: [MileageData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Fleet Mileage (last week)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.primary)
            
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Mileage", item.value),
                        y: .value("Day", item.day)
                    )
                    .foregroundStyle(AppTheme.primary)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text("\(Int(item.value))")
                            .font(AppFonts.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let mileage = value.as(Double.self) {
                            Text("\(Int(mileage))")
                                .font(AppFonts.caption1)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(AppFonts.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
    }
}

// MARK: - Fuel Trend Chart (Vertical + Line)
struct FuelTrendChart: View {
    let data: [FuelTrendData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Last 3 Months Fuel Trend")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.primary)
            
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Fuel Burned", item.value)
                    )
                    .foregroundStyle(AppTheme.primary)
                    .cornerRadius(4)
                }
                
                // Trend Line
                ForEach(data) { item in
                    LineMark(
                        x: .value("Month", item.month),
                        y: .value("Fuel Burned", item.value - 100) // Simulated trend slightly below bars
                    )
                    .foregroundStyle(AppTheme.primary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .interpolationMethod(.linear)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let month = value.as(String.self) {
                            Text(month)
                                .font(AppFonts.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let burn = value.as(Double.self) {
                            Text("\(Int(burn))")
                                .font(AppFonts.caption1)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
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
                    .font(AppFonts.title2)
                    .foregroundColor(.black)
            }
            
            Text(title)
                .font(AppFonts.caption2)
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

// MARK: - Visual Metric Card (Premium)
enum MetricChartType: Equatable {
    case distribution // SectorMark / donut for proportional data
    case sparkline    // Area+Line for continuous 7-day trends
    case bars         // Bar chart for discrete daily values
}

struct VisualMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let subtitle: String
    let trend: String
    let icon: String
    let color: Color
    let chartType: MetricChartType
    let chartData: [HistoricalPoint]

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header row ──────────────────────────────────────────
            HStack(alignment: .center) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title.uppercased())
                        .font(AppFonts.caption2)
                        .foregroundColor(.gray)
                        .tracking(1.2)
                    Text(subtitle)
                        .font(AppFonts.caption1)
                        .foregroundColor(.gray.opacity(0.7))
                }
                Spacer()
                TrendBadge(trend: trend)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            // ── Hero value ──────────────────────────────────────────
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(AppFonts.title1)
                    .foregroundColor(AppTheme.primary)
                Text(unit)
                    .font(AppFonts.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 14)

            // ── Chart ────────────────────────────────────────────────
            Group {
                switch chartType {
                case .distribution:
                    distributionChart
                case .sparkline:
                    sparklineChart
                case .bars:
                    barsChart
                }
            }
            .frame(height: 90)
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
        }
        .background(Color.white)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
        .modifier(AppTheme.cardShadow())
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
    }

    // Donut chart — proportional breakdown
    private var distributionChart: some View {
        HStack(spacing: 12) {
            Chart(chartData) { point in
                SectorMark(
                    angle: .value("Value", appeared ? point.value : 0),
                    innerRadius: .ratio(0.62),
                    angularInset: 2
                )
                .foregroundStyle(AppTheme.primary.opacity(Double(point.value) / 100.0 + 0.2))
                .cornerRadius(4)
            }
            .chartXAxis(.hidden)

            // Legend
            VStack(alignment: .leading, spacing: 6) {
                ForEach(chartData) { point in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.primary.opacity(Double(point.value) / 100.0 + 0.2))
                            .frame(width: 7, height: 7)
                        Text(point.label)
                            .font(AppFonts.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(point.value))%")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .frame(width: 90)
        }
        .padding(.horizontal, 6)
    }

    // Area + Line sparkline — continuous 7-day trend
    private var sparklineChart: some View {
        Chart(chartData) { point in
            AreaMark(
                x: .value("Day", point.label),
                y: .value("Val", appeared ? point.value : chartData.map(\.value).min() ?? 0)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [AppTheme.primary.opacity(0.25), AppTheme.primary.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Day", point.label),
                y: .value("Val", appeared ? point.value : chartData.map(\.value).min() ?? 0)
            )
            .foregroundStyle(AppTheme.primary)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Day", point.label),
                y: .value("Val", appeared ? point.value : chartData.map(\.value).min() ?? 0)
            )
            .foregroundStyle(AppTheme.primary)
            .symbolSize(16)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(AppFonts.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
    }

    // Bar chart — discrete daily bars
    private var barsChart: some View {
        Chart(chartData) { point in
            BarMark(
                x: .value("Day", point.label),
                y: .value("Val", appeared ? point.value : 0)
            )
            .foregroundStyle(AppTheme.primary.gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(AppFonts.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .animation(.easeOut(duration: 0.5), value: appeared)
    }
}

// MARK: - Trend Badge (upgraded)
struct TrendBadge: View {
    let trend: String
    private var isPositive: Bool { trend.hasPrefix("+") }
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9, weight: .black))
            Text(trend)
                .font(AppFonts.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isPositive ? AppTheme.activeGreen.opacity(0.12) : Color.gray.opacity(0.1))
        .foregroundColor(isPositive ? AppTheme.activeGreen : .gray)
        .cornerRadius(20)
    }
}


// MARK: - Insight Anomaly Card
struct InsightAnomalyCard: View {
    let insight: FleetDataManager.FleetInsight
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(bgColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(bgColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(AppFonts.headline)
                    .foregroundColor(AppTheme.primary)
                Text(insight.description)
                    .font(AppFonts.caption1)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(AppTheme.primary.opacity(0.2))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .modifier(AppTheme.cardShadow())
    }
    
    private var bgColor: Color {
        switch insight.type {
        case .utilization: return .orange
        case .efficiency: return AppTheme.primary
        case .maintenance: return AppTheme.primary
        }
    }
    
    private var iconName: String {
        switch insight.type {
        case .utilization: return "chart.pie.fill"
        case .efficiency: return "bolt.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        }
    }
}

// MARK: - CO2 Emissions Bar Graph
struct FleetCO2EmissionsBarGraph: View {
    let data: [EmissionData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) { 
                Text("CO2 Emissions Trends")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                Spacer()
                Text("KG CO2")
                    .font(AppFonts.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.primary.opacity(0.1))
                    .cornerRadius(20)
            }
            
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Emissions", item.value)
                    )
                    .foregroundStyle(item.isCurrent ? AppTheme.primary.gradient : AppTheme.primary.opacity(0.15).gradient)
                    .cornerRadius(4)
                }
                
                RuleMark(y: .value("Average", 12))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(AppTheme.primary.opacity(0.3))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Target: 12kg")
                            .font(AppFonts.caption2)
                            .foregroundColor(.gray)
                    }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(AppFonts.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text("\(Int(val))")
                                .font(AppFonts.caption1)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(24)
        .frame(height: 300)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
    }
}

// MARK: - Driver Behavior Ranked List
struct DriverBehaviorRankedList: View {
    let rankings: [FleetDataManager.DriverPerformanceData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Top 3 Driver Efficiency")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.primary)
            
            Chart(rankings.prefix(3)) { driver in
                BarMark(
                    x: .value("Score", driver.efficiencyScore),
                    y: .value("Driver", driver.name)
                )
                .foregroundStyle(AppTheme.primary.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(Int(driver.efficiencyScore))%")
                        .font(AppFonts.caption1)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primary)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let name = value.as(String.self) {
                            Text(name)
                                .font(AppFonts.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height: 100)
            
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(height: 300)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
    }
}

// MARK: - Unified Maintenance Cost Card
struct UnifiedMaintenanceCostCard: View {
    let perVehicleCost: [HistoricalPoint]
    
    var totalMonthlyCost: Double {
        perVehicleCost.reduce(0) { $0 + $1.value }
    }
    
    var topVehicles: [HistoricalPoint] {
        Array(perVehicleCost.sorted(by: { $0.value > $1.value }).prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Maintenance Expenditure")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("₹\(Int(totalMonthlyCost).formatted())")
                        .font(AppFonts.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primary)
                    Text("TOTAL FLEET COST")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.gray.opacity(0.8))
                        .tracking(1)
                }
            }
            
            if topVehicles.isEmpty {
                // Empty state for when no data is available
                VStack(spacing: 12) {
                    Chart {
                        // Empty BarMarks to keep the axis visible
                        BarMark(x: .value("Vehicle", "V1"), y: .value("Cost", 0))
                        BarMark(x: .value("Vehicle", "V2"), y: .value("Cost", 0))
                        BarMark(x: .value("Vehicle", "V3"), y: .value("Cost", 0))
                        BarMark(x: .value("Vehicle", "V4"), y: .value("Cost", 0))
                        BarMark(x: .value("Vehicle", "V5"), y: .value("Cost", 0))
                    }
                    .chartYAxis {
                        AxisMarks(values: [0, 5000, 10000, 15000]) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("₹\(Int(v/1000))k").font(AppFonts.caption2).foregroundColor(.gray.opacity(0.5))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel {
                                Text("-").font(AppFonts.caption2).foregroundColor(.gray.opacity(0.3))
                            }
                        }
                    }
                    .frame(height: 150)
                    .opacity(0.3)
                    .overlay(
                        Text("No billing data available for this month")
                            .font(AppFonts.caption1)
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(8)
                    )
                }
            } else {
                Chart(topVehicles) { item in
                    BarMark(
                        x: .value("Vehicle", item.label),
                        y: .value("Cost (₹)", item.value)
                    )
                    .foregroundStyle(AppTheme.primary.gradient)
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text("₹\(Int(item.value / 1000))k")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(AppFonts.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("₹\(Int(v / 1000))k")
                                    .font(AppFonts.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .frame(height: 150)
            }
            
            // HStack {
            //     Label("Monthly aggregated", systemImage: "calendar")
            //     Spacer()
            //     Text("Values in Indian Rupees (₹)")
            // }
            // .font(.system(size: 10))
            // .foregroundColor(.gray)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
    }
}

// MARK: - Maintenance Alert Card
struct MaintenanceAlertCard: View {
    let alerts: [FleetMaintenanceAlert]
    let onSelect: (FleetMaintenanceAlert) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Maintenance Approvals")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.primary)
            
            if alerts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 30))
                        .foregroundColor(AppTheme.lightSeaGreen.opacity(0.3))
                    Text("No pending alerts")
                        .font(AppFonts.body)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(alerts) { alert in
                            Button(action: { onSelect(alert) }) {
                                FleetMaintenanceAlertRow(alert: alert)
                            }
                            if alert.id != alerts.last?.id {
                                Divider().padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.defaultCornerRadius)
        .modifier(AppTheme.cardShadow())
    }
}

// MARK: - Travel Analytics Card (Premium Theme)
struct TravelAnalyticsCard: View {
    let totalKms: Double
    let history: [HistoricalPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Travels")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.primary)
            
            HStack(spacing: 30) {
                if history.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 30))
                            .foregroundColor(AppTheme.primary.opacity(0.1))
                        Text("No travel data available yet")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppTheme.primary.opacity(0.3))
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primary.opacity(0.02))
                    .cornerRadius(12)
                } else {
                    Chart(history) { point in
                        AreaMark(
                            x: .value("Month", point.label),
                            y: .value("Kms", point.value)
                        )
                        .foregroundStyle(LinearGradient(colors: [AppTheme.primary.opacity(0.3), AppTheme.primary.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Month", point.label),
                            y: .value("Kms", point.value)
                        )
                        .foregroundStyle(AppTheme.primary)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.catmullRom)
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let label = value.as(String.self) {
                                    Text(label).font(.system(size: 10)).foregroundColor(AppTheme.primary.opacity(0.7))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let val = value.as(Double.self) {
                                    Text("\(Int(val))").font(.system(size: 10)).foregroundColor(AppTheme.primary.opacity(0.7))
                                }
                            }
                        }
                    }
                    .frame(height: 100)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Rectangle()
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(height: 1)
                    
                    Text("Total Travels")
                        .font(AppFonts.headline)
                        .foregroundColor(AppTheme.primary.opacity(0.7))
                    
                    Text("\(Int(totalKms).formatted()) km")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
                .frame(width: 250)
            }
        }
        .padding(35)
        .background(Color.white)
        .cornerRadius(24)
        .modifier(AppTheme.cardShadow())
    }
}

// MARK: - Driver Distance Chart
struct DriverDistanceChart: View {
    let data: [HistoricalPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Driver Distance")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                Text("km covered per driver")
                    .font(AppFonts.caption1)
                    .foregroundColor(.gray)
            }
            
            Chart(data) { item in
                BarMark(
                    x: .value("Distance", item.value),
                    y: .value("Driver", item.label)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.primary.opacity(0.6), AppTheme.primary],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(Int(item.value)) km")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label).font(AppFonts.caption2).foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height: 120)
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(height: 240)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
    }
}

// MARK: - Available Drivers Card
// MARK: - Driver Statistics Card
struct DriverStatsCard: View {
    let total: Int
    let inTransit: Int
    let idle: Int
    let offDuty: Int
    
    private var chartData: [(status: String, count: Int, color: Color)] {
        [
            ("In Transit", inTransit, AppTheme.statusInTransit),
            ("Idle / Available", idle, AppTheme.activeGreen),
            ("Off Duty", offDuty, Color.gray.opacity(0.4))
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Driver Availability")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                Text("Real-time workforce distribution")
                    .font(AppFonts.caption1)
                    .foregroundColor(.gray)
            }
            
            Spacer(minLength: 0)
            
            if total == 0 {
                HStack(spacing: 20) {
                    // Placeholder Ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.1), lineWidth: 10)
                            .frame(width: 90, height: 90)
                        
                        VStack(spacing: 0) {
                            Text("0")
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("DRIVERS")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.gray.opacity(0.3))
                                .tracking(1)
                        }
                    }
                    
                    Spacer(minLength: 10)
                    
                    // Placeholder Legend
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(["In Transit", "Idle", "Off Duty"], id: \.self) { label in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(label)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.gray.opacity(0.3))
                                    Text("0 Drivers")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray.opacity(0.2))
                                }
                            }
                        }
                    }
                    .padding(.trailing, 10)
                }
                .padding(.vertical, 10)
                .overlay(
                    Text("Waiting for backend data...")
                        .font(AppFonts.caption1)
                        .foregroundColor(.gray.opacity(0.5))
                        .offset(y: 60),
                    alignment: .center
                )
            } else {
                // Activity Ring and Legend
                HStack {
                    Spacer()
                    
                    HStack(spacing: 85) {
                        // Ring
                        ZStack {
                            Chart(chartData, id: \.status) { data in
                                SectorMark(
                                    angle: .value("Count", data.count),
                                    innerRadius: .ratio(0.7),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(data.color)
                                .cornerRadius(5)
                            }
                            .frame(width: 110, height: 110)
                            
                            VStack(spacing: 0) {
                                Text("\(total)")
                                    .font(.system(size: 26, weight: .black))
                                    .foregroundColor(AppTheme.primary)
                                Text("DRIVERS")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.gray)
                                    .tracking(1)
                            }
                        }
                        
                        // Legend
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(chartData, id: \.status) { data in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(data.color)
                                        .frame(width: 8, height: 8)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(data.status)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(AppTheme.primary.opacity(0.8))
                                        Text("\(data.count) Drivers")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(height: 260)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
    }
}


// MARK: - Least Travelled Vehicles Chart
struct LeastTravelledVehiclesChart: View {

    struct VehicleKms: Identifiable {
        let id: String
        let label: String
        let kms: Double
    }

    let entries: [VehicleKms]

    init(vehicles: [Vehicle]) {
        let sorted = vehicles
            .map { v -> VehicleKms in
                let total = v.history.reduce(0.0) { sum, trip in
                    let raw = (trip.distance ?? "")
                        .components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
                        .joined()
                    return sum + (Double(raw) ?? 0)
                }
                return VehicleKms(id: v.id, label: v.id, kms: total)
            }
            .sorted { $0.kms < $1.kms }
        self.entries = Array(sorted.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Least Travelled Vehicles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                Text("by total distance covered (km)")
                    .font(AppFonts.caption1)
                    .foregroundColor(.gray)
            }
            
            Spacer(minLength: 0)

            if entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "truck.box.badge.clock.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.primary.opacity(0.1))
                    Text("No vehicle history available.")
                        .font(AppFonts.caption1)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 0) {
                    ForEach(entries) { entry in
                        HStack {
                            Text(formatVehicleID(entry.label))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.primary.opacity(0.8))
                            
                            Spacer()
                            
                            Text("\(Int(entry.kms)) km")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.primary)
                        }
                        .padding(.vertical, 12)
                        
                        if entry.id != entries.last?.id {
                            Divider()
                                .background(AppTheme.primary.opacity(0.05))
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.red.opacity(0.6))
                Text("Low utilisation may indicate vehicles needing redeployment.")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(height: 260)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
    }
    
    private func formatVehicleID(_ id: String) -> String {
        let clean = id.components(separatedBy: .whitespacesAndNewlines).joined().uppercased()
        if clean.count >= 10 {
            let state = String(clean.prefix(2))
            let city = String(clean.dropFirst(2).prefix(2))
            let letters = String(clean.dropFirst(4).prefix(2))
            let number = String(clean.dropFirst(6))
            return "\(state) \(city) \(letters) \(number)"
        }
        return id.uppercased()
    }
}
// MARK: - Geofence Alert Banner
struct GeofenceAlertBanner: View {
    let alert: FleetDataManager.GeofenceAlert
    var onDismiss: () -> Void
    
    private var alertColor: Color {
        switch alert.type {
        case .arrival: return AppTheme.activeGreen
        case .departure: return Color.orange
        case .deviation: return Color.red
        }
    }
    
    private var alertIcon: String {
        switch alert.type {
        case .arrival: return "mappin.and.ellipse"
        case .departure: return "figure.walk.departure"
        case .deviation: return "exclamationmark.triangle.fill"
        }
    }
    
    private var alertTitle: String {
        switch alert.type {
        case .arrival: return "NEW ARRIVAL"
        case .departure: return "NEW DEPARTURE"
        case .deviation: return "ROUTE DEVIATION"
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(alertColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: alertIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(alertColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alertTitle)
                    .font(AppFonts.caption2)
                    .fontWeight(.black)
                    .tracking(1)
                    .foregroundColor(alertColor)
                
                Text(alert.message)
                    .font(AppFonts.body)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primary)
                    .lineLimit(2)
                
                Text("\(alert.timestamp, style: .time)")
                    .font(AppFonts.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
