import SwiftUI

struct FleetManagerDashboardView: View {
    @StateObject private var viewModel = FleetManagerDashboardViewModel()
    @State private var showingAddOrder = false
    @State private var showingAddDriver = false
    @State private var showingAddVehicle = false
    @State private var selectedTopTab: String = "Monitoring"
    
    let topTabs = ["Monitoring", "Analytics", "Optimization", "Fleet Status"]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Greeting (Cleaned up as requested)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good Morning,")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.textSecondary)
                            Text("Lincoln Saris")
                                .font(.system(size: 32, weight: .bold))
                        }
                        Spacer()
                        
                        Image(systemName: "bell.fill")
                            .foregroundColor(.gray)
                            .padding(10)
                            .background(Color.white)
                            .clipShape(Circle())
                            .modifier(AppTheme.cardShadow())
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                }
                .padding(.bottom, 20)
                .background(Color.white)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // MARK: - Vehicle Status Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Vehicle Status")
                                    .font(.system(size: 18, weight: .bold))
                                Spacer()
                                Button("VIEW FULL FLEET") { }
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            
                            HStack(spacing: 20) {
                                FleetOpsMetricItem(title: "Active", value: viewModel.fleetStatus.active, trend: viewModel.fleetStatus.activeTrend, color: AppTheme.activeGreen)
                                FleetOpsMetricItem(title: "Maintenance", value: viewModel.fleetStatus.maintenance, trend: nil, color: AppTheme.maintenanceOrange)
                                FleetOpsMetricItem(title: "Idle", value: viewModel.fleetStatus.idle, trend: nil, color: AppTheme.secondary)
                                FleetOpsMetricItem(title: "Critical", value: viewModel.fleetStatus.critical, trend: nil, color: AppTheme.criticalRed)
                            }
                        }
                        .fmsCardStyle()
                        
                        // MARK: - Smart Fleet Assessments
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Smart Fleet Assessments")
                                    .font(.system(size: 18, weight: .bold))
                                Spacer()
                                HStack(spacing: 12) {
                                    Image(systemName: "chevron.left")
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 12))
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(viewModel.assessments) { assessment in
                                        // Wrapping in NavigationLink for clickability
                                        NavigationLink(destination: SmartFleetDetailView(assessment: assessment)) {
                                            FleetOpsAssessmentCard(assessment: assessment)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.vertical, 5) // Prevent shadow clipping
                            }
                        }
                        
                        // MARK: - Maintenance & Priority
                        MaintenancePriorityDarkCard(alerts: viewModel.maintenanceAlerts)
                        
                        // MARK: - CO2 Emissions
                        FleetOpsEmissionsChart(data: viewModel.emissionData)
                        
                        // MARK: - Quick Action Toolbar
                        HStack(spacing: 15) {
                            FleetOpsActionButton(title: "New Order", iconName: "plus.circle.fill") { showingAddOrder = true }
                            FleetOpsActionButton(title: "Log Repair", iconName: "wrench.and.screwdriver.fill") { }
                            FleetOpsActionButton(title: "Add Driver", iconName: "person.badge.plus.fill") { showingAddDriver = true }
                            FleetOpsActionButton(title: "Add Vehicle", iconName: "truck.box.fill") { showingAddVehicle = true }
                            FleetOpsActionButton(title: "Reports", iconName: "printer.fill") { }
                        }
                        .padding(.bottom, 30)
                        
                    }
                    .padding(30)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddOrder) { OrderModalView() }
        .sheet(isPresented: $showingAddDriver) { DriverModalView() }
        .sheet(isPresented: $showingAddVehicle) { AddVehicleModalView() }
    }
}

struct NavBarItem: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: isActive ? .bold : .medium))
                .foregroundColor(isActive ? .black : .gray)
            
            if isActive {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 20, height: 2)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 20, height: 2)
            }
        }
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 14, weight: .bold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(20)
        .modifier(AppTheme.cardShadow())
    }
}
