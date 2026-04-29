import SwiftUI

struct FleetManagerDriversListView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var searchText = ""
    @State private var showingAddDriver = false
    @State private var driverToEdit: Driver? = nil
    @State private var driverToDelete: Driver? = nil
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack(alignment: .center, spacing: 16) {
                Text("Drivers")
                    .font(AppFonts.title1)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                Button(action: { showingAddDriver = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                        Text("Add Driver")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(AppColors.primary)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 28)
            .padding(.bottom, 16)
            .background(Color.white)
            
            // MARK: - Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                TextField("Search by name, license or status...", text: $searchText)
                    .font(.system(size: 16))
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 30)
            .padding(.bottom, 18)
            .background(Color.white)
            
            // MARK: - Table
            ScrollView {
                if filteredDrivers.isEmpty {
                    VStack(spacing: 10) {
                        Text(emptyStateTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.primary)
                        Text(emptyStateSubtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 25)
                    .padding(.top, 80)
                } else {
                    VStack(spacing: 0) {
                        // Column Headers
                        HStack {
                            Text("DRIVER IDENTITY")
                                .padding(.leading, 55)
                                .frame(width: 250, alignment: .leading)
                            Text("LICENSE DETAILS").frame(width: 200, alignment: .leading)
                            Spacer()
                            Text("STATUS")
                        }
                        .font(AppFonts.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 70)
                        .padding(.vertical, 20)
                        
                        VStack(spacing: 12) {
                            ForEach(filteredDrivers) { driver in
                                NavigationLink(destination: DriverDetailView(driver: driver)) {
                                    DriverRowView(driver: driver)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(action: { driverToEdit = driver }) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive, action: {
                                        driverToDelete = driver
                                        showingDeleteAlert = true
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .background(AppColors.background)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddDriver) { DriverModalView().environmentObject(dataManager) }
        .sheet(item: $driverToEdit) { driver in
            DriverModalView(driverToEdit: driver).environmentObject(dataManager)
        }
        .alert("Confirm Delete", isPresented: $showingDeleteAlert, presenting: driverToDelete) { driver in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await dataManager.deleteDriver(driver)
                }
            }
        } message: { driver in
            Text("Are you sure you want to delete \(driver.name)?")
        }
        .task {
            do {
                try await dataManager.refreshDrivers()
            } catch {
                print("Failed to refresh drivers: \(error)")
            }
        }
    }
    
    private var filteredDrivers: [Driver] {
        if searchText.isEmpty {
            return dataManager.drivers
        } else {
            return dataManager.drivers.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.id.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var emptyStateTitle: String {
        searchText.isEmpty ? "No drivers yet" : "No matching drivers found"
    }

    private var emptyStateSubtitle: String {
        searchText.isEmpty
            ? "No driver profiles are available right now. Add a driver to get started."
            : "Try a different name, license, or status to find drivers."
    }
}

struct DriverRowView: View {
    let driver: Driver
    
    var body: some View {
        HStack {
            // Identity
            HStack(spacing: 15) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 45, height: 45)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(driver.name)
                        .font(AppFonts.headline)
                }
            }
            .frame(width: 250, alignment: .leading)
            
            // License
            VStack(alignment: .leading, spacing: 2) {
                Text(driver.licenseNum)
                    .font(AppFonts.subheadline)
                Text("Exp: \(driver.licenseExp)")
                    .font(AppFonts.caption2)
                    .foregroundColor(.gray)
            }
            .frame(width: 200, alignment: .leading)
            
            Spacer()
            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                Text(driver.status.rawValue.uppercased())
                    .font(AppFonts.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(width: 96)
            .background(statusColor.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(14) // Matching vehicle card radius
        .modifier(AppColors.cardShadow())
        .padding(.horizontal, 30)
        .padding(.vertical, 6) // Spacing between rows
    }
    
    var statusColor: Color {
        switch driver.status {
        case .active, .onDuty: return AppColors.activeGreen
        case .onTrip: return AppColors.maintenanceOrange
        case .offDuty: return AppColors.criticalRed
        }
    }
}

struct FooterStat: View {
    let label: String
    let value: String
    var valueColor: Color = .black
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppFonts.caption2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(valueColor)
        }
    }
}
