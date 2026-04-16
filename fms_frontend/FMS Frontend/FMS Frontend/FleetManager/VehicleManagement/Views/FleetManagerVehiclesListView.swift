import SwiftUI

struct FleetManagerVehiclesListView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "ALL"
    
    let filters = ["ALL", "ACTIVE", "MAINTENANCE", "IDLE"]
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vehicles")
                        .font(.system(size: 32, weight: .bold))
                    Text("FLEET MANAGEMENT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 15) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search unique ID, driver, or VIN...", text: $searchText)
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .frame(width: 300)
                    
                    Menu {
                        ForEach(filters, id: \.self) { filter in
                            Button(filter) { selectedFilter = filter }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundColor(.gray)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Menu {
                        Button("ID (Ascending)") { }
                        Button("ID (Descending)") { }
                        Button("Status") { }
                    } label: {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.gray)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(30)
            .background(Color.white)
            
            // MARK: - Filters
            HStack(spacing: 0) {
                HStack(spacing: 20) {
                    ForEach(filters, id: \.self) { filter in
                        Button(action: { selectedFilter = filter }) {
                            Text(filter)
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 20)
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
                
                Spacer()
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
                        VehicleGridCard(vehicle: vehicle)
                    }
                }
                .padding(30)
            }
            .background(AppTheme.background)
        }
        .navigationBarHidden(true)
    }
    
    var filteredVehicles: [Vehicle] {
        if selectedFilter == "ALL" {
            return MockDataProvider.vehicles
        } else {
            return MockDataProvider.vehicles.filter { $0.status.rawValue == selectedFilter }
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
                    .font(.system(size: 10, weight: .black))
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
                    .font(.system(size: 18, weight: .black))
                Text("\(vehicle.model) • \(vehicle.make)".uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 5)
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(16)
        .modifier(AppTheme.cardShadow())
    }
    
    var statusColor: Color {
        switch vehicle.status {
        case .inTransit: return Color.black
        case .idle: return Color.gray.opacity(0.5)
        case .maintenance: return AppTheme.criticalRed
        }
    }
}
