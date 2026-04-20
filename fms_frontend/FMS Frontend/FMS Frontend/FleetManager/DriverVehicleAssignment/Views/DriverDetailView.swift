import SwiftUI
import MapKit

struct DriverDetailView: View {
    let driver: Driver
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var showingEditModal = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
                
                Text(driver.name)
                    .font(.system(size: 20, weight: .bold))
                
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
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 25)
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 25) {
                    
                    // MARK: - Profile Section
                    HStack(spacing: 30) {
                        // Profile Image
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                )
                            
                            Circle()
                                .fill(statusColor)
                                .frame(width: 25, height: 25)
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text(driver.name)
                                .font(.system(size: 38, weight: .black))
                            
                            HStack(spacing: 5) {
                                Image(systemName: "licenseplate.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(statusColor)
                                Text(driver.vehicleClasses.joined(separator: ", "))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(statusColor)
                            }
                            

                        }
                        
                        Spacer()
                        
                        HStack(spacing: 40) {
                            DetailHeaderStat(label: "STATUS", value: driver.status.rawValue, color: statusColor)
                        }
                    }
                    .padding(30)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // MARK: - Stats Section
                    HStack(spacing: 25) {
                        MiniStatCard(label: "LICENSE NO.", value: driver.licenseNum)
                        MiniStatCard(label: "EXPIRY DATE", value: driver.licenseExp)
                        MiniStatCard(label: "TOTAL TRIPS", value: "\(driver.totalTrips)")
                    }
                    .frame(height: 120) // Consistent height for all cards
                    
                    // MARK: - Current Assignment & Activity Log
                    HStack(spacing: 25) {
                        // Left: Map Card
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("CURRENT ASSIGNMENT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                            
                            Text("Vehicle ID: \(driver.currentVehicleID ?? "N/A")")
                                .font(.system(size: 16, weight: .bold))
                            
                            // Native Map Component
                            MapComponentView()
                                .frame(height: 250)
                                .cornerRadius(12)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("ACTIVE ROUTE")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(driver.activeRoute ?? "Idle")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("ETA")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(driver.eta ?? "--")
                                        .font(.system(size: 12, weight: .bold))
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                        .padding(25)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(Color.white)
                        .cornerRadius(16)
                        
                        // Right: Activity Log
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("RECENT ACTIVITY LOG")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(spacing: 20) {
                                ForEach(driver.activityLog) { event in
                                    ActivityRow(event: event)
                                }
                            }
                        }
                        .padding(25)
                        .frame(width: 400)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                    
                }
                .padding(30)
                .padding(.bottom, 50)
            }
            .background(AppTheme.background)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEditModal) {
            DriverModalView(driverToEdit: driver)
        }
        .alert("Confirm Delete", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let index = dataManager.drivers.firstIndex(where: { $0.id == driver.id }) {
                    dataManager.drivers.remove(at: index)
                }
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this driver?")
        }
    }
    
    var statusColor: Color {
        switch driver.status {
        case .active, .onDuty: return AppTheme.activeGreen
        case .onTrip: return AppTheme.maintenanceOrange
        case .offDuty: return AppTheme.criticalRed
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
                .font(.system(size: 18, weight: .black))
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
                    .font(.system(size: 24, weight: .black))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                if let trend = trend {
                    Text(trend)
                        .font(.system(size: 10, weight: .bold))
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
                    .font(.system(size: 14, weight: .bold))
                Text(event.detail + " • " + event.time)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if let val = event.value {
                Text(val)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(event.type == "incident" ? AppTheme.criticalRed : .gray)
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

// MARK: - Native Map Simulation
struct MapComponentView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        Map(initialPosition: .region(region)) {
            Annotation("", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)) {
                Image(systemName: "truck.box.fill")
                    .padding(8)
                    .background(AppTheme.primary)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
        .disabled(true) // Static look as per Image 3
    }
}

struct MapPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
