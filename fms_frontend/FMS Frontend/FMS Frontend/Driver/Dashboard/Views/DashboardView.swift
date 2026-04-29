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
    @Published var activeTrip: Trip?
    @Published var activeLifecycleTrip: LifecycleTrip?
    @Published var vehiclePlate: String = "UNASSIGNED"
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tripAPI: TripAPI

    init(tripAPI: TripAPI = .shared) {
        self.tripAPI = tripAPI
    }

    /// Dashboard status label: "SCHEDULED" or "IN TRANSIT"
    var missionStatusText: String {
        guard let status = activeLifecycleTrip?.status else { return "SCHEDULED" }
        return status.rawValue
    }

    /// Color for the status badge
    var missionStatusColor: Color {
        guard let status = activeLifecycleTrip?.status else { return .blue }
        switch status {
        case .ongoing:   return .green
        case .scheduled: return .blue
        case .completed: return .gray
        }
    }

    @MainActor
    func loadActiveTrip() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await tripAPI.getDriverTrips()
            let lifecycleTrips = response.trips.compactMap(Self.mapTripItemToLifecycleTrip)

            // Deduplicate by trip ID
            var seen = Set<String>()
            let uniqueTrips = lifecycleTrips.filter { seen.insert($0.id).inserted }

            // Filter out completed trips — dashboard only shows scheduled/ongoing
            let activeTrips = uniqueTrips.filter { $0.status != .completed }

            if let active = activeTrips.first(where: { $0.status == .ongoing })
                ?? activeTrips.first(where: { $0.status == .scheduled })
                ?? activeTrips.first {
                activeLifecycleTrip = active
                activeTrip = active.toTripModel()
                vehiclePlate = active.vehicleNumber ?? "UNASSIGNED"
            } else {
                activeLifecycleTrip = nil
                activeTrip = nil
                vehiclePlate = "UNASSIGNED"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Call backend to mark trip completed, then refresh the dashboard
    @MainActor
    func completeTripAndReload(tripId: String) {
        Task {
            do {
                let response = try await tripAPI.completeTripForDriver(tripId: tripId)
                print("✅ Trip completed from dashboard: \(response.message)")
            } catch {
                print("❌ Failed to complete trip: \(error.localizedDescription)")
            }
            await loadActiveTrip()
        }
    }

    private static func mapTripItemToLifecycleTrip(_ trip: TripItem) -> LifecycleTrip? {
        guard let id = trip.id,
              let source = trip.sourceLocation,
              let destination = trip.destinationLocation else {
            return nil
        }

        let departure = trip.tripDate ?? trip.departureTime
        let status = TripStatusHelper.resolve(backendStatus: trip.status, departureRaw: departure)
        let loadInfo = trip.loadAmount ?? buildLoadInfo(amount: trip.amount, unit: trip.unit)

        return LifecycleTrip(
            id: id,
            source: source,
            destination: destination,
            status: status,
            dateValue: TripStatusHelper.formatDateValue(from: departure),
            timeLabel: status == .completed ? "Completion Time" : "Scheduled Start",
            timeValue: TripStatusHelper.formatTimeValue(from: departure),
            loadInfo: loadInfo,
            distance: parseDistanceKm(trip.distanceKm ?? trip.tripDistance),
            vehicleNumber: trip.vehicleRegistrationNumber,
            cargoWeight: formatCargoWeight(amount: trip.amount, unit: trip.unit),
            rawDeparture: departure
        )
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
            
            // --- CHAT INTEGRATION ---
            NavigationStack {
                ChatListView()
            }
            .tabItem {
                Label("Messages", systemImage: "message.fill")
            }
            // ------------------------
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
                if viewModel.isLoading {
                    ProgressView("Loading trip data...")
                        .padding(.top, 40)
                } else if viewModel.activeTrip != nil {
                    MissionCardView(viewModel: viewModel, locationManager: locationManager)
                } else {
                    EmptyTripStateCard()
                }
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
            
//            Button(action: {}) {
//                Image(systemName: "bell.fill")
//                    .font(.title3)
//                    .foregroundColor(.black)
//                    .padding(12)
//                    .background(Color.white)
//                    .clipShape(Circle())
//                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
//            }
            
            Button(action: { showProfile = true }) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title3)
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .accessibilityLabel("Open Profile")
            .accessibilityHint("Double tap to view and manage your driver profile")
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
                        .background(viewModel.missionStatusColor.opacity(0.1))
                        .foregroundColor(viewModel.missionStatusColor)
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
            if let trip = viewModel.activeTrip {
                VStack(alignment: .leading, spacing: 16) {
                    RouteDetailRow(label: "PICKUP", value: trip.pickup.name)
                    RouteDetailRow(label: "DESTINATION", value: trip.destination.name)
                    
                    NavigationLink(
                        destination: TripDetailView(
                            trip: trip,
                            lifecycleTrip: viewModel.activeLifecycleTrip,
                            onTripEnded: {
                                if let tripId = viewModel.activeLifecycleTrip?.id {
                                    viewModel.completeTripAndReload(tripId: tripId)
                                }
                            }
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
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct EmptyTripStateCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.2.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Active Trips")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.black)
            
            Text("You currently have no scheduled or ongoing trips.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
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
        guard let date = session.userProfile?.expiryDate else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
    }
    
    var formattedClasses: String {
        guard let classes = session.userProfile?.classes, !classes.isEmpty else { return "-" }
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
                        .accessibilityHidden(true) // decorative; name below covers identity
                    
                    VStack(spacing: 4) {
                        Text(session.userProfile?.name ?? "Driver")
                            .font(.title2.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text("Certified Commercial Driver")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                // Group avatar + name + role as one VoiceOver element
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(session.driverProfile?.name ?? "Driver"), Certified Commercial Driver")
            }
            .listRowBackground(Color.clear)
            
            Section("Account Details") {
                AppProfileInfoRow(label: "USERNAME", value: session.userProfile?.username ?? "-")
                AppProfileInfoRow(label: "PHONE", value: session.userProfile?.phone ?? "-")
                AppProfileInfoRow(label: "EMAIL", value: session.userProfile?.email ?? "-")
                AppProfileInfoRow(label: "DL NUMBER", value: session.userProfile?.licenceNumber ?? "-")
                AppProfileInfoRow(label: "EXPIRY DATE", value: formattedExpiryDate)
                AppProfileInfoRow(label: "DL CLASSES", value: formattedClasses)
                AppProfileInfoRow(label: "JOINED", value: session.userProfile?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "-")

                HStack {
                    Text("TURN ON OFFDUTY")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("", isOn: $isOffDuty)
                        .labelsHidden()
                        .accessibilityLabel("Off Duty Status")
                        .accessibilityHint(isOffDuty ? "Currently off duty. Double tap to go on duty" : "Currently on duty. Double tap to go off duty")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
                .frame(minHeight: 44)
            }
            
            Section {
                Button(action: {
                    session.logout()
                    onLogout?()
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                }
                .accessibilityLabel("Logout")
                .accessibilityHint("Double tap to log out of your driver account")
            }
        }
        .navigationTitle("Profile")
    }
}
