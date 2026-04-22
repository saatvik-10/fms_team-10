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
            FleetOpsMetricItem(title: "In Transit", value: active, color: AppColors.statusInTransit)
            Divider().frame(height: 40).padding(.horizontal, 15)
            FleetOpsMetricItem(title: "Scheduled", value: scheduled, color: AppColors.statusInTransit.opacity(0.5))
            Divider().frame(height: 40).padding(.horizontal, 15)
            FleetOpsMetricItem(title: "Idle", value: idle, color: AppColors.statusIdle)
            Divider().frame(height: 40).padding(.horizontal, 15)
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
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textSecondary)
            
            Text(String(format: "%02d", value))
                .font(AppFonts.title1)
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
                            .foregroundColor(AppColors.textSecondary)
                        Text("\(assessment.routeFrom) →")
                            .font(AppFonts.footnote)
                        Text(assessment.routeTo)
                            .font(AppFonts.footnote)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ETA")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textSecondary)
                        Text(assessment.etaTime)
                            .font(AppFonts.footnote)
                            .foregroundColor(assessment.etaTime == "Delayed" ? AppColors.criticalRed : AppColors.textPrimary)
                        Text(assessment.etaDay)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
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
                    .font(AppFonts.body)
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
                            .font(AppFonts.title1)
                            .foregroundColor(.white)
                        Text("CRITICAL MASS")
                            .font(AppFonts.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(width: 140, height: 140)
                
                HStack(spacing: 30) {
                    Label {
                        Text("04 URGENT").font(AppFonts.caption2)
                    } icon: {
                        Circle().fill(AppColors.criticalRed).frame(width: 6, height: 6)
                    }
                    Label {
                        Text("14 SCHEDULED").font(AppFonts.caption2)
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
struct FleetOpsEmissionsChart: View {
    let data: [EmissionData]
    @State private var selectedTimeframe = "Weekly"
    let timeframes = ["Weekly", "Monthly", "Yearly"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("CO2 Emissions")
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.primary)
                
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
                    .foregroundStyle(item.isCurrent ? AppColors.primary : AppColors.primary.opacity(0.1))
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
        .modifier(AppColors.cardShadow())
    }
}

// MARK: - Fleet Mileage Chart (Horizontal)
struct FleetMileageChart: View {
    let data: [MileageData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Fleet Mileage (last week)")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Mileage", item.value),
                        y: .value("Day", item.day)
                    )
                    .foregroundStyle(AppColors.primary)
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
            .frame(height: 180)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
    }
}

// MARK: - Fuel Trend Chart (Vertical + Line)
struct FuelTrendChart: View {
    let data: [FuelTrendData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Last 3 Months Fuel Trend")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Fuel Burned", item.value)
                    )
                    .foregroundStyle(AppColors.primary)
                    .cornerRadius(4)
                }
                
                // Trend Line
                ForEach(data) { item in
                    LineMark(
                        x: .value("Month", item.month),
                        y: .value("Fuel Burned", item.value - 100) // Simulated trend slightly below bars
                    )
                    .foregroundStyle(AppColors.primary.opacity(0.6))
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
            .frame(height: 180)
        }
        .padding(24)
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
                    .foregroundColor(AppColors.primary)
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
        .modifier(AppColors.cardShadow())
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
                .foregroundStyle(AppColors.primary.opacity(Double(point.value) / 100.0 + 0.2))
                .cornerRadius(4)
            }
            .chartXAxis(.hidden)

            // Legend
            VStack(alignment: .leading, spacing: 6) {
                ForEach(chartData) { point in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColors.primary.opacity(Double(point.value) / 100.0 + 0.2))
                            .frame(width: 7, height: 7)
                        Text(point.label)
                            .font(AppFonts.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(point.value))%")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.primary)
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
                    colors: [AppColors.primary.opacity(0.25), AppColors.primary.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Day", point.label),
                y: .value("Val", appeared ? point.value : chartData.map(\.value).min() ?? 0)
            )
            .foregroundStyle(AppColors.primary)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Day", point.label),
                y: .value("Val", appeared ? point.value : chartData.map(\.value).min() ?? 0)
            )
            .foregroundStyle(AppColors.primary)
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
            .foregroundStyle(AppColors.primary.gradient)
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
        .background(isPositive ? AppColors.activeGreen.opacity(0.12) : Color.gray.opacity(0.1))
        .foregroundColor(isPositive ? AppColors.activeGreen : .gray)
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
                    .foregroundColor(AppColors.primary)
                Text(insight.description)
                    .font(AppFonts.caption1)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(AppColors.primary.opacity(0.2))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .modifier(AppColors.cardShadow())
    }
    
    private var bgColor: Color {
        switch insight.type {
        case .utilization: return .orange
        case .efficiency: return AppColors.primary
        case .maintenance: return AppColors.primary
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
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.primary)
                Spacer()
                Text("KG CO2")
                    .font(AppFonts.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(20)
            }
            
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Emissions", item.value)
                    )
                    .foregroundStyle(item.isCurrent ? AppColors.primary.gradient : AppColors.primary.opacity(0.15).gradient)
                    .cornerRadius(4)
                }
                
                RuleMark(y: .value("Average", 12))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(AppColors.primary.opacity(0.3))
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
            .frame(height: 180)
        }
        .padding(24)
        .frame(height: 300)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
    }
}

// MARK: - Driver Behavior Ranked List
struct DriverBehaviorRankedList: View {
    let rankings: [FleetDataManager.DriverPerformanceData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Top 3 Driver Efficiency")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            
            Chart(rankings.prefix(3)) { driver in
                BarMark(
                    x: .value("Score", driver.efficiencyScore),
                    y: .value("Driver", driver.name)
                )
                .foregroundStyle(AppColors.primary.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(Int(driver.efficiencyScore))%")
                        .font(AppFonts.caption1)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
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
            .frame(height: 180)
            
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(height: 300)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
    }
}

// MARK: - Operational Cost Chart (Area)
struct OperationalCostChart: View {
    let trend: [HistoricalPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Operational Cost Trend")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            
            Chart(trend) { point in
                AreaMark(
                    x: .value("Day", point.label),
                    y: .value("Cost", point.value)
                )
                .foregroundStyle(LinearGradient(colors: [AppColors.primary.opacity(0.3), AppColors.primary.opacity(0)], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("Day", point.label),
                    y: .value("Cost", point.value)
                )
                .foregroundStyle(AppColors.primary)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label).font(AppFonts.caption2).foregroundColor(.gray)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 180)
            
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(height: 300)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
    }
}

// MARK: - Fuel Performance Comparison
struct FuelPerformanceChart: View {
    let data: [(vehicleID: String, efficiency: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Fuel Efficiency (L/100km)")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            
            Chart(data, id: \.vehicleID) { item in
                BarMark(
                    x: .value("Vehicle", item.vehicleID),
                    y: .value("Efficiency", item.efficiency)
                )
                .foregroundStyle(AppColors.primary.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let id = value.as(String.self) {
                            Text(id).font(AppFonts.caption2).foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height: 180)
            
            Text("Lower is better • Peer average: 18.2L")
                .font(AppFonts.caption2)
                .foregroundColor(.gray)
        }
        .padding(24)
        .frame(height: 300)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
    }
}

// MARK: - Fleet Health Status Stacked Bar
struct FleetHealthStatusStackedBar: View {
    let healthy: Int
    let warning: Int
    let critical: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Fleet Health Index")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            
            Chart {
                BarMark(x: .value("Status", healthy))
                    .foregroundStyle(AppColors.deepSeaGreen)
                BarMark(x: .value("Status", warning))
                    .foregroundStyle(AppColors.mediumSeaGreen)
                BarMark(x: .value("Status", critical))
                    .foregroundStyle(AppColors.lightSeaGreen)
            }
            .frame(height: 48)
            .chartXAxis(.hidden)
            .cornerRadius(10)
            
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(AppColors.deepSeaGreen).frame(width: 8, height: 8)
                    Text("Healthy: \(healthy)")
                        .font(AppFonts.caption2)
                        .foregroundColor(.gray)
                }
                HStack(spacing: 6) {
                    Circle().fill(AppColors.mediumSeaGreen).frame(width: 8, height: 8)
                    Text("Warning: \(warning)")
                        .font(AppFonts.caption2)
                        .foregroundColor(.gray)
                }
                HStack(spacing: 6) {
                    Circle().fill(AppColors.lightSeaGreen).frame(width: 8, height: 8)
                    Text("Critical: \(critical)")
                        .font(AppFonts.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
    }
}

// MARK: - Trip Status Breakdown (Donut)
struct TripStatusDonutChart: View {
    let active: Int
    let scheduled: Int
    let maintenance: Int
    
    private var data: [(status: String, count: Int, color: Color)] {
        [
            ("In Transit", active, AppColors.primary),
            ("Scheduled", scheduled, AppColors.primary.opacity(0.6)),
            ("Maintenance", maintenance, AppColors.primary.opacity(0.3))
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Trip Status Overview")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            
            ZStack {
                Chart(data, id: \.status) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(5)
                }
                .frame(height: 160)
                
                VStack(spacing: 0) {
                    Text("\(active + scheduled + maintenance)")
                        .font(AppFonts.title1)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
                    Text("TOTAL")
                        .font(AppFonts.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(data, id: \.status) { item in
                    HStack {
                        Circle().fill(item.color).frame(width: 8, height: 8)
                        Text(item.status).font(AppFonts.caption2).foregroundColor(.gray)
                        Spacer()
                        Text("\(item.count)").font(AppFonts.caption2).fontWeight(.bold)
                    }
                }
            }
        }
        .padding(24)
        .frame(height: 350)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
    }
}

// MARK: - Maintenance Alert Card
struct MaintenanceAlertCard: View {
    let alerts: [FleetMaintenanceAlert]
    let onSelect: (FleetMaintenanceAlert) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Maintenance Alert")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            
            if alerts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 30))
                        .foregroundColor(AppColors.lightSeaGreen.opacity(0.3))
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
        .background(AppColors.cardBackground)
        .cornerRadius(AppColors.defaultCornerRadius)
        .modifier(AppColors.cardShadow())
    }
}
