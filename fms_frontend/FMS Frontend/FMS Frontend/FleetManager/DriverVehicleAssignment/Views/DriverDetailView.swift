import SwiftUI

struct DriverDetailView: View {
    let driver: Driver
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var showingEditModal = false
    @State private var showingDeleteAlert = false
    @State private var routeEta: String = "--"
    private let infoCardHeight: CGFloat = 180
    
    private var assignedVehicle: Vehicle? {
        dataManager.vehicles.first(where: {
            ($0.assignedDriver?.backendId != nil && $0.assignedDriver?.backendId == driver.backendId) ||
            ($0.assignedDriver?.id != nil && $0.assignedDriver?.id == driver.id) ||
            $0.id == driver.currentVehicleID ||
            $0.registrationNumber == driver.currentVehicleID
        })
    }
    
    private var assignedTrip: VehicleTrip? {
        assignedVehicle?.currentTrip
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }

                Text("Back")
                    .font(AppFonts.title3)

                Spacer()

                Menu {
                    Button(action: { showingEditModal = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)

            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 88, height: 88)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 34))
                                        .foregroundColor(.gray)
                                )

                            Circle()
                                .fill(statusColor)
                                .frame(width: 18, height: 18)
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(driver.name)
                                .font(AppFonts.title1)
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 6, height: 6)
                                Text(driver.status.rawValue)
                                    .font(AppFonts.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(statusColor)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .frame(width: 96, alignment: .center)
                            .background(statusColor.opacity(0.1))
                            .cornerRadius(12)
                        }

                        Spacer()
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(14)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MiniStatCard(label: "LICENSE NO.", value: driver.licenseNum)
                        MiniStatCard(label: "EXPIRY DATE", value: driver.licenseExp)
                        MiniStatCard(label: "TOTAL TRIPS", value: "\(driver.totalTrips)")
                        MiniStatCard(label: "VEHICLE CLASS", value: driver.vehicleClasses.isEmpty ? "N/A" : driver.vehicleClasses.joined(separator: ", "))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("CURRENT ASSIGNMENT")
                            .font(AppFonts.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)

                        let trip = assignedTrip
                        let routeStr = trip != nil ? "\(trip!.origin) → \(trip!.destination)" : "Idle"
                        let vehicleStr = assignedVehicle?.registrationNumber ?? "N/A"

                        HStack {
                            DetailHeaderStat(label: "VEHICLE", value: vehicleStr)
                            Spacer()
                            DetailHeaderStat(label: "ETA", value: routeEta)
                        }

                        DetailHeaderStat(label: "ACTIVE ROUTE", value: routeStr)

                        if let vehicle = assignedVehicle, trip != nil {
                            AsyncFleetVehicleMap(vehicle: vehicle)
                                .frame(height: 180)
                                .cornerRadius(12)
                                .padding(.top, 8)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(Color.white)
                    .cornerRadius(14)

                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(AppColors.background)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEditModal) {
            DriverModalView(driverToEdit: driver)
        }
        .alert("Confirm Delete", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await dataManager.deleteDriver(driver)
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this driver?")
        }
        .task {
            await loadAssignment()
        }
        .onChange(of: assignedTrip?.origin) { _, _ in
            Task { await loadRouteEta() }
        }
    }
    
    var statusColor: Color {
        switch driver.status {
        case .active: return AppColors.activeGreen
        case .onTrip: return AppColors.maintenanceOrange
        case .offDuty: return AppColors.criticalRed
        }
    }
    
    private func loadAssignment() async {
        do {
            try await dataManager.refreshVehicles()
        } catch {
            print("Failed to refresh vehicle assignment: \(error)")
        }
        await loadRouteEta()
    }
    
    private func loadRouteEta() async {
        guard let trip = assignedTrip else {
            await MainActor.run { routeEta = "--" }
            return
        }
        
        if !trip.eta.isEmpty {
            await MainActor.run { routeEta = trip.eta }
        }
        
        do {
            let route = try await FleetDirectionsService.shared.fetchDirections(
                origin: trip.origin,
                destination: trip.destination
            )
            await MainActor.run { routeEta = route.eta }
        } catch {
            await MainActor.run { routeEta = trip.eta.isEmpty ? "--" : trip.eta }
            print("Failed to load assignment ETA: \(error)")
        }
    }
}

// MARK: - Subcomponents

struct DetailHeaderStat: View {
    let label: String
    let value: String
    var color: Color = .black
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            Text(value)
                .font(AppFonts.title3)
                .foregroundColor(color)
        }
    }
}

struct MiniStatCard: View {
    let label: String
    let value: String
    var trend: String? = nil
    var trendColor: Color = .gray
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            
            HStack(alignment: .bottom) {
                Text(value)
                    .font(AppFonts.title2)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                if let trend = trend {
                    Text(trend)
                        .font(AppFonts.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(trendColor)
                        .padding(.bottom, 4)
                }
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
    }
}

// Rating related components removed

struct ActivityRow: View {
    let event: ActivityEvent
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(AppFonts.headline)
                Text(event.detail + " • " + event.time)
                    .font(AppFonts.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if let val = event.value {
                Text(val)
                    .font(AppFonts.caption1)
                    .fontWeight(.bold)
                    .foregroundColor(event.type == "incident" ? AppColors.criticalRed : .gray)
            }
        }
    }
    
    var iconName: String {
        switch event.type {
        case "completed": return "checkmark.circle.fill"
        case "refueling": return "fuelpump.fill"
        case "started": return "clock.arrow.2.circlepath"
        case "incident": return "exclamationmark.triangle.fill"
        default: return "circle.fill"
        }
    }
}
