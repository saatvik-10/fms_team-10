import SwiftUI

// MARK: - Vehicle Status Filter (no "All")
private enum VehicleFilter: String, CaseIterable {
    case inTransit   = "IN TRANSIT"
    case maintenance = "MAINTENANCE"
    case idle        = "IDLE"

    var displayName: String { rawValue }
}

struct FleetManagerVehiclesListView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var searchText = ""
    @State private var selectedFilter: VehicleFilter = .inTransit
    @State private var showingAddVehicle = false

    // Long-press delete state
    @State private var vehicleToDelete: Vehicle? = nil
    @State private var showDeleteAlert = false

    // MARK: - Filtered Vehicles (search + segment)
    var filteredVehicles: [Vehicle] {
        let byStatus = dataManager.vehicles.filter {
            $0.status.rawValue == selectedFilter.rawValue
        }
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return byStatus
        }
        let query = searchText.lowercased()
        return byStatus.filter { vehicle in
            let name   = "\(vehicle.make) \(vehicle.model)".lowercased()
            let number = vehicle.registrationNumber.lowercased()
            let idRaw  = vehicle.id.lowercased()
            return name.contains(query) || number.contains(query) || idRaw.contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Header Row
            HStack(alignment: .center, spacing: 16) {
                Text("Vehicles")
                    .font(AppFonts.title1)
                    .foregroundColor(AppColors.primaryText)

                Spacer()

                Button(action: { showingAddVehicle = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                        Text("Add Vehicle")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background(AppTheme.primary)
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
                TextField("Search by vehicle name or number...", text: $searchText)
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

            // MARK: - Segment Control
            HStack(spacing: 0) {
                ForEach(VehicleFilter.allCases, id: \.self) { filter in
                    Button(action: { selectedFilter = filter }) {
                        Text(filter.displayName)
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedFilter == filter ? Color.white : Color.clear)
                            .foregroundColor(selectedFilter == filter ? .black : .gray)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(5)
            .background(Color(.systemGray5))
            .cornerRadius(25)
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            .background(Color.white)

            // MARK: - Vehicle Grid
            ScrollView {
                if filteredVehicles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(searchText.isEmpty
                             ? "No vehicles in this category"
                             : "No results for \"\(searchText)\"")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ], spacing: 24) {
                        ForEach(filteredVehicles) { vehicle in
                            NavigationLink(destination: FleetManagerVehicleDetailView(vehicle: vehicle)) {
                                VehicleGridCard(vehicle: vehicle)
                            }
                            .buttonStyle(PlainButtonStyle())
                            // Long-press → confirm delete
                            .contextMenu {
                                Button(role: .destructive) {
                                    vehicleToDelete = vehicle
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete Vehicle", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(30)
                }
            }
            .background(AppTheme.background)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddVehicle) { AddVehicleModalView().environmentObject(dataManager) }
        .task {
            do {
                try await dataManager.refreshVehicles()
            } catch {
                print("Failed to refresh vehicles: \(error)")
            }
        }
        // Long-press delete confirmation alert
        .alert("Delete Vehicle", isPresented: $showDeleteAlert, presenting: vehicleToDelete) { v in
            Button("Cancel", role: .cancel) { vehicleToDelete = nil }
            Button("Delete", role: .destructive) {
                Task {
                    await dataManager.deleteVehicle(v)
                    await MainActor.run {
                        vehicleToDelete = nil
                    }
                }
            }
        } message: { v in
            Text("Are you sure you want to permanently delete \(v.registrationNumber)? This cannot be undone.")
        }
    }
}

// MARK: - Vehicle Grid Card
struct VehicleGridCard: View {
    let vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Image area — full bleed, flush to top corners
            Rectangle()
                .fill(Color(.systemGray6))
                .frame(height: 170)
                .overlay(
                    Group {
                        if let urlString = vehicle.vehicleImageUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .tint(AppTheme.primary)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 170)
                                        .clipped()
                                case .failure(_):
                                    placeholderView
                                @unknown default:
                                    placeholderView
                                }
                            }
                        } else {
                            placeholderView
                        }
                    }
                )
                .clipShape(TopRoundedRectangle(radius: 18))

            // Vehicle Info
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(vehicle.registrationNumber)
                        .font(AppFonts.title2)
                        .foregroundColor(AppColors.primaryText)
                        .tracking(0.5)
                    Spacer()
                    Text("\(Int(vehicle.maxLoadCapacity)) \(vehicle.capacityUnit)")
                        .font(AppFonts.caption1)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.primary.opacity(0.1))
                        .cornerRadius(6)
                }

                Text("\(vehicle.make) \(vehicle.model)".uppercased())
                    .font(AppFonts.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(Color.white)
        .cornerRadius(18)
        .modifier(AppTheme.cardShadow())
    }

    private var placeholderView: some View {
        Image(systemName: "truck.box.fill")
            .font(.system(size: 44))
            .foregroundColor(.gray.opacity(0.4))
    }
}

// MARK: - Top-only corner radius shape
private struct TopRoundedRectangle: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                    radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                    radius: radius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

