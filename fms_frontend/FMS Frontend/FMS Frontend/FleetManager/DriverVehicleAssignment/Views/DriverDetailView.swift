import SwiftUI

struct DriverDetailView: View {
    let driver: Driver
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var showingEditModal = false
    @State private var showingDeleteAlert = false
    private let infoCardHeight: CGFloat = 180
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }

                Text(driver.name)
                    .font(.system(size: 20, weight: .semibold))

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
                                .font(.system(size: 26, weight: .bold))
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 6, height: 6)
                                Text(driver.status.rawValue)
                                    .font(.system(size: 10, weight: .bold))
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
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)

                        HStack {
                            DetailHeaderStat(label: "VEHICLE", value: driver.currentVehicleID ?? "N/A")
                            Spacer()
                            DetailHeaderStat(label: "ETA", value: driver.eta ?? "--")
                        }

                        DetailHeaderStat(label: "ACTIVE ROUTE", value: driver.activeRoute ?? "Idle")
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, minHeight: infoCardHeight, maxHeight: infoCardHeight, alignment: .topLeading)
                    .background(Color.white)
                    .cornerRadius(14)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT ACTIVITY")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)

                        if driver.activityLog.isEmpty {
                            Text("No recent activity")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        } else {
                            ScrollView {
                                VStack(spacing: 14) {
                                    ForEach(driver.activityLog) { event in
                                        ActivityRow(event: event)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, minHeight: infoCardHeight, maxHeight: infoCardHeight, alignment: .topLeading)
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
        case .active, .onDuty: return AppColors.activeGreen
        case .onTrip: return AppColors.maintenanceOrange
        case .offDuty: return AppColors.criticalRed
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
