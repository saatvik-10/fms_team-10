import SwiftUI

struct FleetAnalyticsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTimeframe = "Weekly"
    
    let timeframes = ["Daily", "Weekly", "Monthly", "Yearly"]
    
    var body: some View {
        VStack(spacing: 0) {
            // The custom header is removed to use native navigationTitle
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // Timeframe Selector
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("ENVIRONMENTAL IMPACT")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                            Text("CO2 Emission Analytics")
                                .font(.system(size: 32, weight: .black))
                        }
                        Spacer()
                        
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(timeframes, id: \.self) { time in
                                Text(time)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 300)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // Main Chart Area
                    VStack(alignment: .leading, spacing: 25) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("AVERAGE EMISSIONS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                Text("14.2 kg/mi")
                                    .font(.system(size: 28, weight: .black))
                                Text("-12.4% from last period")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.activeGreen)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("PEAK DAY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                Text("Thursday")
                                    .font(.system(size: 18, weight: .bold))
                                Text("18.2 kg/mi")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Large Chart Mockup
                        HStack(alignment: .bottom, spacing: 25) {
                            ForEach(MockDataProvider.emissionData) { item in
                                VStack(spacing: 15) {
                                    ZStack(alignment: .bottom) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.05))
                                            .frame(height: 250)
                                        
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(item.isCurrent ? Color.black : AppTheme.statusBlue.opacity(0.3))
                                            .frame(height: CGFloat(item.value * 12))
                                            .overlay(
                                                Text(String(format: "%.1f", item.value))
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(item.isCurrent ? .white : .black)
                                                    .padding(.bottom, 10),
                                                alignment: .top
                                            )
                                    }
                                    
                                    Text(item.day)
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 300)
                    }
                    .padding(40)
                    .background(Color.white)
                    .cornerRadius(24)
                    .padding(.horizontal, 30)
                    
                    // Efficiency Row
                    HStack(spacing: 30) {
                        EfficiencySectorCard(title: "Truck Fleet", value: "82%", icon: "truck.box.fill", color: .black)
                        EfficiencySectorCard(title: "Van Fleet", value: "94%", icon: "bus.fill", color: AppTheme.statusBlue)
                        EfficiencySectorCard(title: "EV Units", value: "98%", icon: "bolt.car.fill", color: AppTheme.activeGreen)
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 50)
            }
            .background(AppTheme.background)
        }
        .navigationTitle("Fleet Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}

struct EfficiencySectorCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Spacer()
                Text(value)
                    .font(.system(size: 24, weight: .black))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.1)).frame(height: 4)
                    Capsule().fill(color).frame(width: 80, height: 4)
                }
            }
        }
        .padding(25)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
        .frame(maxWidth: .infinity)
    }
}
