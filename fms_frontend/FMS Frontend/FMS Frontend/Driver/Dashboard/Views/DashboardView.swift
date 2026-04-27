import SwiftUI
import CoreLocation
import GoogleMaps
import Combine

// MARK: - Colors Palette
//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (255, 0, 0, 0)
//        }
//        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
//    }
//    
//    static let appPrimary = Color(hex: "0F1C24")
//    static let appSecondaryBg = Color(hex: "C9CFD6")
//}

// MARK: - MVVM & Services

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}

class DashboardViewModel: ObservableObject {
    @Published var userName: String = UserProfile.mockDriver.name
    @Published var activeTrip: Trip = Trip.mockTrip
    @Published var activeLifecycleTrip: LifecycleTrip?
    @Published var vehicleName: String = "Tata Prima 4028.S"
    @Published var vehiclePlate: String = "MH 43 AB 1234"
    @Published var fuelLevel: String = "78%"
    @Published var maintenanceHealth: String = "Optimal"
    @Published var maintenanceProgress: Double = 0.8
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tripAPI: TripAPI

    init(tripAPI: TripAPI = .shared) {
        self.tripAPI = tripAPI
    }

    var missionStatusText: String {
        guard let status = activeLifecycleTrip?.status else { return "IN TRANSIT" }
        return status.rawValue
    }

    @MainActor
    func loadActiveTrip() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await tripAPI.getDriverTrips()
            let lifecycleTrips = response.trips.compactMap(Self.mapTripItemToLifecycleTrip)

            if let active = lifecycleTrips.first(where: { $0.status == .scheduled })
                ?? lifecycleTrips.first(where: { $0.status == .assigned })
                ?? lifecycleTrips.first {
                activeLifecycleTrip = active
                activeTrip = active.toTripModel()
                vehiclePlate = active.vehicleNumber ?? "UNASSIGNED"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private static func mapTripItemToLifecycleTrip(_ trip: TripItem) -> LifecycleTrip? {
        guard let id = trip.id,
              let source = trip.sourceLocation,
              let destination = trip.destinationLocation else {
            return nil
        }

        let status = mapTripStatus(trip.status)
        let loadInfo = trip.loadAmount ?? buildLoadInfo(amount: trip.amount, unit: trip.unit)
        let departure = trip.tripDate ?? trip.departureTime

        return LifecycleTrip(
            id: id,
            source: source,
            destination: destination,
            status: status,
            dateValue: formatDateValue(from: departure),
            timeLabel: status == .completed ? "Completion Time" : "Scheduled Start",
            timeValue: formatTimeValue(from: departure),
            loadInfo: loadInfo,
            distance: parseDistanceKm(trip.tripDistance),
            vehicleNumber: trip.vehicleRegistrationNumber,
            cargoWeight: formatCargoWeight(amount: trip.amount, unit: trip.unit)
        )
    }

    private static func mapTripStatus(_ rawStatus: String?) -> TripStatus {
        switch rawStatus?.uppercased() {
        case "COMPLETED":
            return .completed
        case "PENDING", "CANCELLED":
            return .assigned
        default:
            return .scheduled
        }
    }

    private static func buildLoadInfo(amount: Int?, unit: String?) -> String {
        if let amount, let unit {
            return "\(amount) \(unit)"
        }
        return "N/A"
    }

    private static func formatCargoWeight(amount: Int?, unit: String?) -> String {
        guard let amount, let unit else { return "N/A" }
        return "\(amount) \(unit)"
    }

    private static func parseDistanceKm(_ value: String?) -> Double {
        guard let value, !value.isEmpty else { return 0.0 }
        let filtered = value.filter { "0123456789.".contains($0) }
        return Double(filtered) ?? 0.0
    }

    private static func formatDateValue(from raw: String?) -> String {
        guard let raw, let date = parseDate(raw) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private static func formatTimeValue(from raw: String?) -> String {
        guard let raw, let date = parseDate(raw) else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func parseDate(_ raw: String) -> Date? {
        let isoWithFractional = ISO8601DateFormatter()
        isoWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFractional.date(from: raw) {
            return date
        }

        let isoBasic = ISO8601DateFormatter()
        isoBasic.formatOptions = [.withInternetDateTime]
        if let date = isoBasic.date(from: raw) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: raw)
    }
}

// MARK: - Main Tab View

struct DashboardView: View {
    @Binding var userRole: AppUserRole

    var body: some View {
        TabView {
            NavigationStack {
                DashboardHomeView(userRole: $userRole)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            TripsView()
            .tabItem {
                Label("Trips", systemImage: "map.fill")
            }
        }
        .accentColor(AppColors.primary)
    }
}

// MARK: - Dashboard Content

struct DashboardHomeView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var showProfile = false
    @Binding var userRole: AppUserRole
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Active Mission Section
                MissionCardView(viewModel: viewModel, locationManager: locationManager)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await viewModel.loadActiveTrip()
        }
        .alert(
            "Could not load active trip",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("Retry") {
                Task { await viewModel.loadActiveTrip() }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
        .navigationDestination(isPresented: $showProfile) {
            DriverProfileView(onLogout: {
                AuthAPI.shared.logout()
                userRole = .none
            })
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 16) {
            Text("Home")
                .font(.system(.title, design: .default, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            
            Button(action: { showProfile = true }) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title3)
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Reusable Components

struct MissionCardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Content
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("ACTIVE MISSION")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(viewModel.missionStatusText)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                
                Text(viewModel.vehiclePlate)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            .padding(16)
            
            // Map Integratation
            GoogleMapView(locationManager: locationManager)
                .frame(height: 200)
                .clipped()
            
            // Details
            VStack(alignment: .leading, spacing: 16) {
                RouteDetailRow(label: "PICKUP", value: viewModel.activeTrip.pickup.name)
                RouteDetailRow(label: "DESTINATION", value: viewModel.activeTrip.destination.name)
                
                NavigationLink(
                    destination: TripDetailView(
                        trip: viewModel.activeTrip,
                        lifecycleTrip: viewModel.activeLifecycleTrip
                    )
                ) {
                    HStack {
                        Text("View Trip")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "0a303a"))
                    .cornerRadius(12)
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct VehicleCardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    Image(systemName: "box.truck.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppColors.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.vehicleName)
                            .font(.headline)
                            .foregroundColor(.black)
                        Text(viewModel.vehiclePlate)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Fuel")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.fuelLevel)
                        .font(.headline)
                        .foregroundColor(.black)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Maintenance Health")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(viewModel.maintenanceHealth)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.secondaryBackground)
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(Color(hex: "0a303a"))
                            .frame(width: geo.size.width * viewModel.maintenanceProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}


struct RouteDetailRow: View {
    var label: String
    var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            let parts = value.split(separator: ",", maxSplits: 1).map(String.init)
            
            VStack(alignment: .leading, spacing: 2) {
                // ✅ Place name (bold)
                Text(parts.first ?? "")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                // ✅ Remaining address (lighter)
                if parts.count > 1 {
                    Text(parts[1])
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// MARK: - Navigation Destination Placeholders

// TripDetailView is implemented in its own file

// MARK: - Google Maps Wrapper

struct GoogleMapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    
    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        let mapView = GMSMapView(options: options)
        mapView.isMyLocationEnabled = true
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        if let location = locationManager.location {
            let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 14.0)
            uiView.animate(to: camera)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(userRole: .constant(.driver))
    }
}

struct DriverProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: AppSessionStore
    var onLogout: (() -> Void)? = nil
    @State private var isOffDuty: Bool = false
    
    var formattedExpiryDate: String {
        guard let date = session.driverProfile?.expiryDate else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
    
    var formattedClasses: String {
        guard let classes = session.driverProfile?.classes, !classes.isEmpty else { return "-" }
        return classes.joined(separator: ", ")
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(AppColors.primary)
                    
                    VStack(spacing: 4) {
                        Text(session.driverProfile?.name ?? "Driver")
                            .font(.title2.bold())
                        Text("Certified Commercial Driver")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)
            
            Section("Account Details") {
                AppProfileInfoRow(label: "USERNAME", value: session.driverProfile?.username ?? "-")
                AppProfileInfoRow(label: "PHONE", value: session.driverProfile?.phone ?? "-")
                AppProfileInfoRow(label: "EMAIL", value: session.driverProfile?.email ?? "-")
                AppProfileInfoRow(label: "DL NUMBER", value: session.driverProfile?.licenceNumber ?? "-")
                AppProfileInfoRow(label: "EXPIRY DATE", value: formattedExpiryDate)
                AppProfileInfoRow(label: "DL CLASSES", value: formattedClasses)
                AppProfileInfoRow(label: "JOINED", value: session.driverProfile?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "-")

                HStack {
                    Text("TURN ON OFFDUTY")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("", isOn: $isOffDuty)
                        .labelsHidden()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            
            Section {
                Button(action: {
                    session.logout()
                    onLogout?()
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Profile")
    }
}

