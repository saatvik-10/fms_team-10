import SwiftUI

struct FleetManagerDashboardView: View {
    @StateObject private var viewModel = FleetManagerDashboardViewModel()
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var showingAddOrder = false
    @State private var showingManagerProfile = false
    @State private var showingAlertDetail = false
    @State private var selectedAlert: FleetMaintenanceAlert?
    
    var body: some View {
        ZStack {
            AppColors.secondaryBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                FleetDashboardHeaderView(showingProfile: $showingManagerProfile)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        
                        // MARK: - Row 1: Fleet Status Metrics (Full Width)
                        FleetStatusMetricsGrid(
                            active: dataManager.activeCount,
                            idle: dataManager.idleCount,
                            maintenance: dataManager.maintenanceCount,
                            scheduled: dataManager.scheduledCount
                        )
                        
                        // MARK: - Row 2: Trips Section (Moved Up)
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Trips")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(AppColors.primary)
                                
                                Spacer()
                                
                                Button(action: { showingAddOrder = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Create Trip")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.primary)
                                    .clipShape(Capsule())
                                }
                            }
                            
                            if dataManager.vehicles.compactMap({ $0.currentTrip }).isEmpty {
                                // Empty State
                                FleetDashboardEmptyTripsView(action: { showingAddOrder = true })
                            } else {
                                // Trips Grid (3 per line)
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 15),
                                    GridItem(.flexible(), spacing: 15),
                                    GridItem(.flexible(), spacing: 15)
                                ], spacing: 15) {
                                    ForEach(dataManager.vehicles.indices, id: \.self) { index in
                                        if let trip = dataManager.vehicles[index].currentTrip {
                                            NavigationLink(destination: FleetTripDetailView(vehicle: $dataManager.vehicles[index])) {
                                                FleetTripCardView(trip: trip, vehicle: dataManager.vehicles[index])
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Row 3: Insights (Side-by-Side)
                        HStack(spacing: 20) {
                            // Maintenance Alerts Card
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Maintenance Alert")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppColors.primary)
                                
                                if dataManager.maintenanceAlerts.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(AppColors.activeGreen.opacity(0.3))
                                        Text("No pending alerts")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    ScrollView {
                                        VStack(spacing: 0) {
                                            ForEach(dataManager.maintenanceAlerts) { alert in
                                                Button(action: {
                                                    selectedAlert = alert
                                                    showingAlertDetail = true
                                                }) {
                                                    FleetMaintenanceAlertRow(alert: alert)
                                                }
                                                if alert.id != dataManager.maintenanceAlerts.last?.id {
                                                    Divider().padding(.vertical, 4)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppColors.defaultCornerRadius)
                            .modifier(AppColors.cardShadow())
                            
                            // Trip History Card
                            TripHistoryCard(trips: dataManager.allHistory)
                        }
                        
                        // MARK: - Row 4: Operational Analytics
                        VStack(spacing: 25) {
                            // CO2 Emissions (Interactive)
                            FleetOpsEmissionsChart(data: dataManager.emissionData)
                            
                            HStack(spacing: 20) {
                                // Fleet Mileage (Horizontal)
                                FleetMileageChart(data: dataManager.mileageData)
                                
                                // Fuel Trend (Vertical + Trend Line)
                                FuelTrendChart(data: dataManager.fuelTrendData)
                            }
                        }
                        
                        // spacer for bottom tab bar
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddOrder) { 
            FleetCreateTripModal(isPresented: $showingAddOrder)
        }
        .sheet(isPresented: $showingManagerProfile) { 
            ManagerProfileView()
        }
        .sheet(item: $selectedAlert) { alert in
            FleetMaintenanceAlertDetailView(alert: alert)
        }
    }
}

struct FleetDashboardHeaderView: View {
    @Binding var showingProfile: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dashboard")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(AppColors.primary)
            }
            Spacer()
            
            Button(action: { showingProfile = true }) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 44, height: 44)
                    Text("VR")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .modifier(AppColors.cardShadow())
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 20)
        .padding(.bottom, 15)
        .background(Color.white)
    }
}

struct FleetDashboardEmptyTripsView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "box.truck.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary.opacity(0.2))
                .padding(.top, 40)
            
            VStack(spacing: 8) {
                Text("No Active Trips")
                    .font(.system(size: 18, weight: .bold))
                Text("Start your first trip to track vehicle movements and delivery status.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, minHeight: 240) // Unified height and end-to-end width
        .background(Color.white)
        .cornerRadius(AppColors.defaultCornerRadius)
        .modifier(AppColors.cardShadow())
    }
}

struct FleetTripCardView: View {
    let trip: VehicleTrip
    let vehicle: Vehicle
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Icon Area (Health-style)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.primary.opacity(0.6))
            }
            .frame(width: 70, height: 70)
            .padding(.leading, 12)
            
            // Right: Content Area
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vehicle.id)
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(AppColors.primary)
                        Text(vehicle.model)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray.opacity(0.3))
                }
                
                Spacer(minLength: 0)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(trip.status.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(4)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 15)
        }
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
        .frame(maxWidth: .infinity)
        .frame(height: 100) // Fixed height for consistency in grid
    }
    
    private var statusColor: Color {
        switch trip.status {
        case .scheduled: return Color.gray
        case .inTransit: return AppColors.statusInTransit
        case .completed: return AppColors.activeGreen
        }
    }
}

struct ManagerProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Manager Information")) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 60, height: 60)
                            Text("VR")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Vikram S. Rathore")
                                .font(.headline)
                            Text("Fleet Operations Manager")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 10)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Account Settings")) {
                    Label("Notifications", systemImage: "bell.fill")
                    Label("Privacy & Security", systemImage: "lock.fill")
                    Label("Help & Support", systemImage: "questionmark.circle.fill")
                }
                
                Section {
                    Button(role: .destructive, action: { 
                        // Logout logic
                    }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
