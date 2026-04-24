import SwiftUI

struct FleetManagerDashboardView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var showingAddOrder = false
    @State private var showingManagerProfile = false
    @State private var showingAlertDetail = false
    @State private var selectedAlert: FleetMaintenanceAlert?
    @State private var selectedHistoryTrip: VehicleTrip?
    @State private var showingAllTrips = false
    let profile: ManagerProfileData?
    
    init(profile: ManagerProfileData? = nil) {
        self.profile = profile
    }
    
    var body: some View {
        ZStack {
            AppTheme.secondaryBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                FleetDashboardHeaderView(showingProfile: $showingManagerProfile, profile: profile)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // MARK: - Section 1: Fleet Overview
                        VStack(alignment: .leading, spacing: 15) {
                            DashboardSectionHeader(title: "Fleet Overview")
                            
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
                        
                        // MARK: - Section 2: Active Logistics
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                DashboardSectionHeader(title: "Active Logistics")
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
                                    .background(AppTheme.primary)
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
                        
                        // MARK: - Section 3: Maintenance Cost Analytics
                        VStack(alignment: .leading, spacing: 15) {
                            DashboardSectionHeader(title: "Maintenance Analytics")
                            
                            // Weekly trend + Per vehicle side by side
                            HStack(alignment: .top, spacing: 15) {
                                OperationalCostChart(trend: dataManager.costTrend)
                                    .frame(maxWidth: .infinity)
                                
                                MaintenanceCostPerVehicleChart(data: dataManager.maintenanceCostPerVehicle)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // MARK: - Section 4: Fleet Intelligence
                        VStack(alignment: .leading, spacing: 15) {
                            DashboardSectionHeader(title: "Fleet Intelligence")
                            
                            // Outer card wrapping all Fleet Intelligence content
                            VStack(spacing: 16) {
                                // Row A: Total KMs (full width — dark card)
                                TravelAnalyticsCard(
                                    totalKms: dataManager.totalKmsTravelled,
                                    history: dataManager.travelsHistory
                                )
                                
                                // Row B: Least Travelled Vehicles + Available Drivers (side by side)
                                HStack(alignment: .top, spacing: 15) {
                                    LeastTravelledVehiclesChart(vehicles: dataManager.vehicles)
                                        .frame(maxWidth: .infinity)
                                    
                                    IdleDriversAnalytic(drivers: dataManager.idleDrivers)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(AppTheme.defaultCornerRadius)
                            .modifier(AppTheme.cardShadow())
                        }
                        
                        // MARK: - Separator
                        Rectangle()
                            .fill(AppTheme.primary.opacity(0.08))
                            .frame(maxWidth: .infinity)
                            .frame(height: 1)
                            .padding(.vertical, 4)
                        
                        // MARK: - Section 5: Maintenance & History
                        HStack(alignment: .top, spacing: 20) {
                            MaintenanceAlertCard(alerts: dataManager.maintenanceAlerts, onSelect: { alert in
                                selectedAlert = alert
                                showingAlertDetail = true
                            })
                            
                            TripHistoryCard(trips: dataManager.allHistory, onSelect: { trip in
                                selectedHistoryTrip = trip
                            }, onViewAll: {
                                showingAllTrips = true
                            })
                        }
                        
                        // Bottom padding for tab bar
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 25)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedHistoryTrip) { trip in
            if let index = dataManager.vehicles.firstIndex(where: { $0.id == trip.vehicleID }) {
                FleetTripDetailView(vehicle: $dataManager.vehicles[index], tripOverride: trip)
            }
        }
        .sheet(isPresented: $showingAddOrder) {
            FleetCreateTripModal(isPresented: $showingAddOrder)
        }
        .sheet(isPresented: $showingManagerProfile) {
            ManagerProfileView(profile: profile)
        }
        .sheet(item: $selectedAlert) { alert in
            FleetMaintenanceAlertDetailView(alert: alert)
        }
        .fullScreenCover(isPresented: $showingAllTrips) {
            AllTripsView()
        }
    }
}

// MARK: - Section Header Helper
struct DashboardSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(AppTheme.primary)
    }
}

// MARK: - Dashboard Header
struct FleetDashboardHeaderView: View {
    @Binding var showingProfile: Bool
    let profile: ManagerProfileData?
    
    init(showingProfile: Binding<Bool>, profile: ManagerProfileData? = nil) {
        self._showingProfile = showingProfile
        self.profile = profile
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dashboard")
                    .font(AppFonts.largeTitle)
                    .foregroundColor(AppTheme.primary)
            }
            Spacer()
            
            Button(action: { showingProfile = true }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 44, height: 44)
                    Text(profileInitial)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .modifier(AppTheme.cardShadow())
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 20)
        .padding(.bottom, 15)
        .background(Color.white)
    }
    
    var profileInitial: String {
        guard let name = profile?.name, let first = name.first else { return "M" }
        return String(first).uppercased()
    }
}

    
    
    // MARK: - Empty Trips State
    struct FleetDashboardEmptyTripsView: View {
        let action: () -> Void
        
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "box.truck.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.primary.opacity(0.2))
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
            .frame(maxWidth: .infinity, minHeight: 240)
            .background(Color.white)
            .cornerRadius(AppTheme.defaultCornerRadius)
            .modifier(AppTheme.cardShadow())
        }
    }
    
    // MARK: - Trip Card (Grid)
    struct FleetTripCardView: View {
        let trip: VehicleTrip
        let vehicle: Vehicle
        
        var body: some View {
            HStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.primary.opacity(0.6))
                }
                .frame(width: 70, height: 70)
                .padding(.leading, 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vehicle.id)
                                .font(AppFonts.headline)
                                .fontWeight(.black)
                                .foregroundColor(AppTheme.primary)
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
            .modifier(AppTheme.cardShadow())
            .frame(maxWidth: .infinity)
            .frame(height: 100)
        }
        
        private var statusColor: Color {
            switch trip.status {
            case .scheduled: return Color.gray
            case .inTransit: return AppTheme.statusInTransit
            case .completed: return AppTheme.activeGreen
            }
        }
    }
    
    // MARK: - Manager Profile
    struct ManagerProfileView: View {
        @Environment(\.dismiss) var dismiss
        let profile: ManagerProfileData?
        
        init(profile: ManagerProfileData? = nil) {
            self.profile = profile
        }
        
        var body: some View {
            ZStack {
                AppTheme.secondaryBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Manager Profile")
                            .font(AppFonts.title2)
                            .foregroundColor(AppTheme.primary)
                        Spacer()
                        Button(action: { dismiss() }) {
                            Text("Done")
                                .font(AppFonts.headline)
                                .foregroundColor(AppTheme.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppTheme.primary.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(25)
                    .background(Color.white)
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack(spacing: 20) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: [AppTheme.primary, AppTheme.deepSeaGreen], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 80, height: 80)
                                        Text(initials)
                                            .font(.system(size: 32, weight: .black))
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(profile?.name ?? "Manager")
                                            .font(AppFonts.title3)
                                            .foregroundColor(AppTheme.primary)
                                        Text("Fleet Operations Manager")
                                            .font(AppFonts.subheadline)
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Divider()
                                
                                VStack(spacing: 15) {
                                    ProfileInfoRow(icon: "envelope.fill", label: "Email", value: profile?.email ?? "To be integrated")
                                    ProfileInfoRow(icon: "phone.fill", label: "Work Phone", value: profile?.phone ?? "To be integrated")
                                }
                            }
                            .padding(24)
                            .background(Color.white)
                            .cornerRadius(20)
                            .modifier(AppTheme.cardShadow())
                            
                            signOutButton
                        }
                        .padding(25)
                    }
                }
            }
        }
        
        var initials: String {
            guard let name = profile?.name, let first = name.first else { return "M" }
            return String(first).uppercased()
        }
        
        var signOutButton: some View {
            Button(action: {
                AuthAPI.shared.logout()
                dismiss()
            }) {
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
    }
    
    
    // MARK: - Profile Info Row
    struct ProfileInfoRow: View {
        let icon: String
        let label: String
        let value: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primary.opacity(0.4))
                    .frame(width: 24)
                Text(label)
                    .font(AppFonts.caption1)
                    .foregroundColor(.gray)
                Spacer()
                Text(value)
                    .font(AppFonts.body)
                    .foregroundColor(AppTheme.primary)
            }
        }
    }
    
    // MARK: - Profile Action Row
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
                    .foregroundColor(AppTheme.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
