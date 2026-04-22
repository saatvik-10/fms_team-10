import SwiftUI

struct FleetManagerDashboardView: View {
    @StateObject private var viewModel = FleetManagerDashboardViewModel()
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var showingAddOrder = false
    @State private var showingManagerProfile = false
    @State private var showingAlertDetail = false
    @State private var selectedAlert: FleetMaintenanceAlert?
    @State private var selectedHistoryTrip: VehicleTrip?
    @State private var showingAllTrips = false // New: Navigation to full history
    
    var body: some View {
        ZStack {
            AppColors.secondaryBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                FleetDashboardHeaderView(showingProfile: $showingManagerProfile)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 35) {
                        
                        // MARK: - Section 1: Command Center (High-Level Pulse)
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Command Center")
                                .font(AppFonts.title2)
                                .foregroundColor(AppColors.primary)
                            
                            FleetStatusMetricsGrid(
                                active: dataManager.activeCount,
                                idle: dataManager.idleCount,
                                maintenance: dataManager.maintenanceCount,
                                scheduled: dataManager.scheduledCount
                            )
                            
                            FleetHealthStatusStackedBar(
                                healthy: dataManager.healthyCount,
                                warning: dataManager.warningCount,
                                critical: dataManager.criticalCount
                            )
                                .frame(maxWidth: .infinity)
                        }
                        
                        // MARK: - Section 2: Active Logistics (Prioritized Operations)
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Active Logistics")
                                    .font(AppFonts.title2)
                                    .foregroundColor(AppColors.primary)
                                
                                Spacer()
                                
                                Button(action: { showingAddOrder = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Create Trip")
                                    }
                                    .font(AppFonts.button)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(AppColors.primary)
                                    .clipShape(Capsule())
                                }
                            }
                            
                            if dataManager.vehicles.compactMap({ $0.currentTrip }).isEmpty {
                                FleetDashboardEmptyTripsView(action: { showingAddOrder = true })
                            } else {
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
                        
                        // MARK: - Section 3: Performance Analytics (Deep Intelligence)
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Performance Analytics")
                                .font(AppFonts.title2)
                                .foregroundColor(AppColors.primary)
                            
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                                DriverBehaviorRankedList(rankings: dataManager.driverRankings)
                                OperationalCostChart(trend: dataManager.costTrend)
                                FuelPerformanceChart(data: dataManager.fuelEfficiencyData)
                                FleetCO2EmissionsBarGraph(data: dataManager.emissionData)
                            }
                        }
                        
                        // MARK: - Section 4: Maintenance & History
                        HStack(spacing: 20) {
                            MaintenanceAlertCard(alerts: dataManager.maintenanceAlerts, onSelect: { alert in
                                selectedAlert = alert
                                showingAlertDetail = true
                            })
                            .frame(height: 380) // Enforce consistent height parity
                            
                            TripHistoryCard(trips: dataManager.allHistory, onSelect: { trip in
                                selectedHistoryTrip = trip
                            }, onViewAll: {
                                showingAllTrips = true
                            })
                            .frame(height: 380) // Match maintenance card height
                        }
                        
                        // spacer for bottom tab bar
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 25)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedHistoryTrip) { trip in
            // Find the vehicle associated with this trip to pass as a binding
            // Note: Since we only need the binding to satisfy the detail view's signature,
            // we find the index in our live dataManager array.
            if let index = dataManager.vehicles.firstIndex(where: { $0.id == trip.vehicleID }) {
                FleetTripDetailView(vehicle: $dataManager.vehicles[index], tripOverride: trip)
            }
        }
        .sheet(isPresented: $showingAddOrder) { 
            FleetCreateTripModal(isPresented: $showingAddOrder)
        }
        .sheet(isPresented: $showingManagerProfile) { 
            ManagerProfileView()
        }
        .sheet(item: $selectedAlert) { alert in
            FleetMaintenanceAlertDetailView(alert: alert)
        }
        .fullScreenCover(isPresented: $showingAllTrips) {
            AllTripsView()
        }
    }
}

struct FleetDashboardHeaderView: View {
    @Binding var showingProfile: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dashboard")
                    .font(AppFonts.largeTitle)
                    .foregroundColor(AppColors.primary)
            }
            Spacer()
            
            Button(action: { showingProfile = true }) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 44, height: 44)
                    Text("VR")
                        .font(AppFonts.button)
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
                    .font(AppFonts.title3)
                Text("Start your first trip to track vehicle movements and delivery status.")
                    .font(AppFonts.body)
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
                            .font(AppFonts.headline)
                            .fontWeight(.black)
                            .foregroundColor(AppColors.primary)
                        Text(vehicle.model)
                            .font(AppFonts.caption2)
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
                        .font(AppFonts.caption2)
                        .fontWeight(.bold)
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
        ZStack {
            AppColors.secondaryBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Manager Profile")
                        .font(AppFonts.title2)
                        .foregroundColor(AppColors.primary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppColors.primary.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(25)
                .background(Color.white)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // 1. Manager Identity Card
                        VStack(spacing: 20) {
                            HStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [AppColors.primary, AppColors.deepSeaGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 80, height: 80)
                                    Text("VR")
                                        .font(.system(size: 32, weight: .black))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Vikram S. Rathore")
                                        .font(AppFonts.title3)
                                        .foregroundColor(AppColors.primary)
                                    Text("Fleet Operations Manager")
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        Text("ID: FMS-2026-089")
                                            .font(AppFonts.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(AppColors.primary.opacity(0.05))
                                            .cornerRadius(4)
                                        Spacer()
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            
                            Divider()
                            
                            VStack(spacing: 15) {
                                ProfileInfoRow(icon: "envelope.fill", label: "Email", value: "vikram.rathore@fms.com")
                                ProfileInfoRow(icon: "phone.fill", label: "Work Phone", value: "+91 98765 43210")
                                ProfileInfoRow(icon: "building.2.fill", label: "Department", value: "Logistics Optimization")
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .modifier(AppColors.cardShadow())
                        
                        // Action Section
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                Text("Sign Out of Session")
                                    .fontWeight(.bold)
                            }
                            .font(AppFonts.body)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.red.opacity(0.05))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.1), lineWidth: 1))
                        }
                    }
                    .padding(25)
                }
            }
        }
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.primary.opacity(0.4))
                .frame(width: 24)
            
            Text(label)
                .font(AppFonts.caption1)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.body)
                .foregroundColor(AppColors.primary)
        }
    }
}

struct ProfileActionRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(AppFonts.body)
                .foregroundColor(AppColors.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
