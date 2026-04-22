import SwiftUI

struct FleetManagerVehiclesListView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var searchText = ""
    @State private var selectedFilter = "ALL"
    @State private var showingAddVehicle = false
    
    let filters = ["ALL", "IN TRANSIT", "MAINTENANCE", "IDLE"]
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack(spacing: 20) {
                Text("Vehicles Management")
                    .font(AppFonts.title3)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search unique ID, driver, or VIN...", text: $searchText)
                        .font(AppFonts.body)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                Button(action: { showingAddVehicle = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Vehicle")
                    }
                    .font(AppFonts.button)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColors.primary)
                    .cornerRadius(8)
                }
            }
            .padding(30)
            .background(Color.white)
            
            // MARK: - Filters
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(filters, id: \.self) { filter in
                        Button(action: { selectedFilter = filter }) {
                            Text(filter)
                                .font(AppFonts.caption2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedFilter == filter ? Color.white : Color.clear)
                                .foregroundColor(selectedFilter == filter ? .black : .gray)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(5)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(25)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            .background(Color.white)
            
            // MARK: - Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 25),
                    GridItem(.flexible(), spacing: 25),
                    GridItem(.flexible(), spacing: 25)
                ], spacing: 30) {
                    ForEach(filteredVehicles) { vehicle in
                        NavigationLink(destination: FleetManagerVehicleDetailView(vehicle: vehicle)) {
                            VehicleGridCard(vehicle: vehicle)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(30)
            }
            .background(AppColors.background)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddVehicle) { AddVehicleModalView() }
    }
    
    var filteredVehicles: [Vehicle] {
        if selectedFilter == "ALL" {
            return dataManager.vehicles
        } else {
            return dataManager.vehicles.filter { $0.status.rawValue == selectedFilter }
        }
    }
}

struct VehicleGridCard: View {
    let vehicle: Vehicle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Image with Status Overlay
            ZStack(alignment: .topTrailing) {
                // Placeholder Image
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 180)
                    .overlay(
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                    )
                
                // Status Overlay
                Text(vehicle.status.rawValue)
                    .font(AppFonts.caption2)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor)
                    .cornerRadius(8)
                    .padding(10)
            }
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.id)
                    .font(AppFonts.title3)
                Text("\(vehicle.model) • \(vehicle.make)".uppercased())
                    .font(AppFonts.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 5)
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
    }
    
    var statusColor: Color {
        switch vehicle.status {
        case .inTransit: return AppColors.primary
        case .idle: return Color.gray.opacity(0.5)
        case .maintenance: return AppColors.criticalRed
        }
    }
}
