import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerView
                
                yourTripsCard
                
                metricsRow
                
                statusPill
                
                analyticsSection
                
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Subviews
extension DashboardView {
    
    // 1. HEADER
    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 52, height: 52)
                .foregroundColor(Color.gray.opacity(0.8))
            
            Text("Good Morning, Marcus")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                // Action
            }) {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // 2. YOUR TRIPS CARD
    private var yourTripsCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Your Trips")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                TripStatView(number: "12", label: "TOTAL")
                Spacer()
                TripStatView(number: "02", label: "ONGOING")
                Spacer()
                TripStatView(number: "10", label: "PENDING")
            }
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    // 3. METRICS ROW
    private var metricsRow: some View {
        HStack {
            MetricItemView(value: "42 km", label: "DISTANCE")
            Spacer()
            MetricItemView(value: "3h 20m", label: "TIME")
            Spacer()
            MetricItemView(value: "25 min", label: "DELAY")
        }
        .padding(.horizontal, 16)
    }
    
    // 4. STATUS PILL
    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.primary)
                .frame(width: 6, height: 6)
            Text("Status: On Time")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
    
    // 5. AWARENESS ANALYTICS SECTION
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AWARENESS ANALYTICS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(1.5)
                .padding(.leading, 4)
            
            AnalyticsCard(
                title: "FUEL CONSUMPTION",
                status: "Efficient",
                subtext: "-8.4%",
                caption: "Fuel usage lower than yesterday",
                progress: 0.3
            )
            
            AnalyticsCard(
                title: "CO2 EMISSIONS",
                status: "Normal",
                subtext: nil,
                caption: "Emissions within normal range",
                progress: 0.55
            )
        }
    }
    
    // 6. QUICK ACTIONS SECTION
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("QUICK ACTIONS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(1.5)
                .padding(.leading, 4)
            
            HStack(spacing: 16) {
                QuickActionCard(icon: "exclamationmark.triangle.fill", text: "Report Issue")
                QuickActionCard(icon: "checklist", text: "Inspection")
            }
        }
    }
}

// MARK: - Components

struct TripStatView: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(number)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(1.0)
        }
    }
}

struct MetricItemView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .tracking(1.0)
        }
    }
}

struct AnalyticsCard: View {
    let title: String
    let status: String
    let subtext: String?
    let caption: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                
                Spacer()
                
                // Minimal vertical bar indicators
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<4) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(i == 3 ? Color.secondary.opacity(0.3) : Color.primary)
                            .frame(width: 3, height: CGFloat(8 + (i % 2 == 0 ? 4 : 8)))
                    }
                }
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(status)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let subtext = subtext {
                    Text(subtext)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
            
            Text(caption)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct QuickActionCard: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.primary)
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
