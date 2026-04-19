import SwiftUI

struct FleetManagerDashboardView: View {
    @StateObject private var viewModel = FleetManagerDashboardViewModel()
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var showingAddOrder = false
    @State private var showingAddDriver = false
    @State private var showingAddVehicle = false
    @State private var showingManagerProfile = false
    @State private var showingRequestsList = false
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
                            Text("Lincoln Saris")
                                .font(.system(size: 32, weight: .black))
                        }
                        Spacer()
                        
                        Button(action: { showingManagerProfile = true }) {
                            Text("LS")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.primary)
                                .clipShape(Circle())
                                .modifier(AppTheme.cardShadow())
                        }
                    }
                    .padding(.horizontal, 30) // Only padding on top header block
                    .padding(.top, 40)
                }
                .padding(.bottom, 20)
                .background(Color.white)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // MARK: - Metrics Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 20) {
                                FleetOpsMetricItem(title: "Active Fleet", value: dataManager.fleetStatus.active, trend: nil, color: AppTheme.activeGreen)
                                FleetOpsMetricItem(title: "Maintenance Fleet", value: dataManager.fleetStatus.maintenance, trend: nil, color: AppTheme.maintenanceOrange)
                                FleetOpsMetricItem(title: "Idle Fleet", value: dataManager.fleetStatus.idle, trend: nil, color: AppTheme.secondary)
                                FleetOpsMetricItem(title: "Critical Fleet", value: dataManager.fleetStatus.critical, trend: nil, color: AppTheme.criticalRed)
                            }
                        }
                        .fmsCardStyle()
                        .padding(.horizontal, 0)
                        
                        // MARK: - Smart Fleet Assessments
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Smart Fleet Assessments")
                                    .font(.system(size: 18, weight: .bold))
                                Spacer()
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(dataManager.assessments) { assessment in
                                        // Wrapping in NavigationLink for clickability
                                        // Navigate to full vehicle detail by matching truckID
                                        if let matchedVehicle = dataManager.vehicles.first(where: { $0.id == assessment.truckID }) {
                                            NavigationLink(destination: FleetManagerVehicleDetailView(vehicle: matchedVehicle)) {
                                                FleetOpsAssessmentCard(assessment: assessment)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        } else {
                                            FleetOpsAssessmentCard(assessment: assessment)
                                        }
                                    }
                                }
                                .padding(.vertical, 5) // Prevent shadow clipping
                            }
                        }
                        
                        // MARK: - Quick Action Toolbar
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Quick Actions")
                                .font(.system(size: 18, weight: .bold))
                            HStack(spacing: 15) {
                            FleetOpsActionButton(title: "New Order", iconName: "plus.circle.fill") { showingAddOrder = true }
                            FleetOpsActionButton(title: "Log Repair", iconName: "wrench.and.screwdriver.fill") { }
                            FleetOpsActionButton(title: "Add Driver", iconName: "person.badge.plus.fill") { showingAddDriver = true }
                            FleetOpsActionButton(title: "Add Vehicle", iconName: "truck.box.fill") { showingAddVehicle = true }
                            FleetOpsActionButton(title: "Maintenace Requests", iconName: "printer.fill") { showingRequestsList = true }
                        }
                        .padding(.bottom, 30)
                        }

                        // MARK: - Maintenance & Priority
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Maintenance & Priority")
                                .font(.system(size: 18, weight: .bold))
                            MaintenancePriorityDarkCard(
                            summary: viewModel.stats.maintenanceSummary,
                            criticalMass: viewModel.stats.criticalMass,
                            alerts: dataManager.maintenanceAlerts
                        )
                        }
                        
                        // MARK: - CO2 Emissions
                        VStack(alignment: .leading, spacing: 20) {
                            Text("CO2 Emissions Tracker")
                                .font(.system(size: 18, weight: .bold))
                            FleetOpsEmissionsChart(data: dataManager.emissionData)
                        }
                                                
                    }
                    .padding(30)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddOrder) { OrderModalView() }
        .sheet(isPresented: $showingAddDriver) { DriverModalView() }
        .sheet(isPresented: $showingAddVehicle) { AddVehicleModalView() }
        .sheet(isPresented: $showingRequestsList) { MaintenanceRequestsListView() }
        .sheet(isPresented: $showingManagerProfile) { ManagerProfileView() }
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
                    .fill(AppTheme.primary)
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

struct ManagerProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Avatar & Header
                    VStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 100, height: 100)
                            Text("LS")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .modifier(AppTheme.cardShadow())
                        
                        VStack(spacing: 5) {
                            Text("Lincoln Saris")
                                .font(.system(size: 24, weight: .black))
                            Text("Senior Fleet Manager")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Stats
                    HStack(spacing: 20) {
                        ProfileStatBox(title: "Active Years", value: "5")
                        ProfileStatBox(title: "Vehicles Managed", value: "142")
                        ProfileStatBox(title: "Rating", value: "4.9")
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 20) {
                        Text("CONTACT INFORMATION")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        
                        ProfileDetailRow(icon: "envelope.fill", label: "Email", value: "l.saris@fleetops.net")
                        ProfileDetailRow(icon: "phone.fill", label: "Phone", value: "+1 (555) 019-2830")
                        ProfileDetailRow(icon: "building.2.fill", label: "Office", value: "Chicago Hub, Terminal 4")
                        ProfileDetailRow(icon: "badge.plus.radiowaves.right", label: "Manager ID", value: "MGR-8991-A")
                    }
                    .padding(25)
                    .background(Color.white)
                    .cornerRadius(16)
                    .modifier(AppTheme.cardShadow())
                    
                    Spacer()
                }
                .padding(30)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(AppTheme.primary))
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ProfileStatBox: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(AppTheme.primary)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(12)
        .modifier(AppTheme.cardShadow())
    }
}

struct ProfileDetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
