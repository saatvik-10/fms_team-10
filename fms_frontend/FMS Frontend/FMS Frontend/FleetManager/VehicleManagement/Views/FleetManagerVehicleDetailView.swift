import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Indian Plate Map (local to this file)
private let vmDetailPlateMap: [String: String] = [
    "TRK-9042": "KA 01 AB 9042",
    "VN-4209":  "MH 12 CD 4209",
    "EV-9910":  "DL 03 EF 9910",
    "TRK-2101": "TN 07 GH 2101",
    "VN-1100":  "RJ 14 JK 1100",
    "TRK-5502": "UP 32 MN 5502"
]
private func vmPlate(for id: String) -> String { vmDetailPlateMap[id] ?? id }

// MARK: - City coordinates
private let cityCoordinates: [String: CLLocationCoordinate2D] = [
    "DEL": .init(latitude: 28.6139, longitude: 77.2090),
    "JAI": .init(latitude: 26.9124, longitude: 75.7873),
    "BLR": .init(latitude: 12.9716, longitude: 77.5946),
    "MAA": .init(latitude: 13.0827, longitude: 80.2707),
    "COK": .init(latitude: 10.8505, longitude: 76.2711),
    "HYD": .init(latitude: 17.3850, longitude: 78.4867),
    "PNQ": .init(latitude: 18.5204, longitude: 73.8567),
    "BOM": .init(latitude: 19.0760, longitude: 72.8777),
    "AGR": .init(latitude: 27.1767, longitude: 78.0081),
    "NDA": .init(latitude: 28.5706, longitude: 77.3219)
]

// MARK: - Google Map (Vehicle Management local)
struct AsyncFleetVehicleMap: View {
    let vehicle: Vehicle
    @State private var routeResult: FleetDirectionsResult?
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading Map...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            } else if let result = routeResult {
                FleetGoogleMapView(
                    encodedPolyline: result.polyline,
                    originCoord: result.originCoord,
                    destCoord: result.destCoord,
                    originLabel: result.originName,
                    destLabel: result.destName
                )
            } else {
                // Fallback / Idle State
                FleetGoogleMapView(
                    encodedPolyline: "",
                    originCoord: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629), // Center of India
                    destCoord: nil,
                    originLabel: "",
                    destLabel: ""
                )
            }
        }
        .onAppear { loadRoute() }
        .onChange(of: vehicle.currentTrip?.origin) { _, _ in loadRoute() }
    }

    private func loadRoute() {
        guard let trip = vehicle.currentTrip else { return }
        isLoading = true
        Task {
            do {
                let result = try await FleetDirectionsService.shared.fetchDirections(
                    origin: trip.origin,
                    destination: trip.destination
                )
                await MainActor.run {
                    self.routeResult = result
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Map load error: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Status colour
private func vmStatusColor(_ s: VehicleStatus) -> Color {
    switch s {
    case .inTransit:   return AppTheme.activeGreen
    case .idle:        return .gray
    case .maintenance: return .orange
    case .scheduled:   return .blue
    }
}

// MARK: - Card wrapper  (equal-height trick: frame BEFORE background)
/// Wraps any VStack content so the white card always fills its available space,
/// letting HStack siblings equalise heights naturally.
private struct CardWrapper<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // ← frame FIRST
        .background(Color.white)
        .cornerRadius(20)
        .modifier(AppTheme.cardShadow())
    }
}

// MARK: - Side-by-side row helper
private struct SideBySide<A: View, B: View>: View {
    let left: A; let right: B
    init(_ left: A, _ right: B) { self.left = left; self.right = right }
    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            left .frame(maxWidth: .infinity, maxHeight: .infinity)
            right.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Detail View
struct FleetManagerVehicleDetailView: View {
    let vehicle: Vehicle
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var showingEditModal   = false
    @State private var showingDeleteAlert = false
    @State private var routeEta: String = ""
    @State private var routeDistance: String = ""
    @State private var routeDuration: String = ""

    private var hasActiveTrip: Bool {
        vehicle.status == .inTransit && vehicle.currentTrip != nil
    }
    private var hasDriver: Bool {
        vehicle.status == .inTransit && vehicle.assignedDriver != nil
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                ScrollView {
                    VStack(spacing: 20) {

                        // ── Map ────────────────────────────────────────────
                        AsyncFleetVehicleMap(vehicle: vehicle)
                            .frame(height: 230)
                            .cornerRadius(20)
                            .modifier(AppTheme.cardShadow())

                        // ── Row 1: Vehicle Info — always full width ────────
                        vehicleInfoCard

                        // ── Row 2: Assigned Driver | Active Trip ──────────
                        if hasDriver, let driver = vehicle.assignedDriver {
                            HStack(alignment: .top, spacing: 18) {
                                driverCard(driver: driver)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 205)

                                if let trip = vehicle.currentTrip {
                                    activeTripCard(trip: trip)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 205)
                                }
                            }
                        }

                        // ── Row 3: Next Service full width ────────────────
                        maintenanceCard
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)

                        // ── Row 4: Recent History | Past Reports — always ─
                        SideBySide(recentHistoryCard, pastReportsCard)
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEditModal) { AddVehicleModalView(vehicleToEdit: vehicle) }
        .alert("Delete Vehicle", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await dataManager.deleteVehicle(vehicle)
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Permanently delete \(vmPlate(for: vehicle.id))? This cannot be undone.")
        }
        .task {
            await loadRouteMetrics()
        }
        .onChange(of: vehicle.currentTrip?.origin) { _, _ in
            Task { await loadRouteMetrics() }
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Vehicles")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(AppTheme.primary)
            }
            Spacer()
            Text(vehicle.status.displayName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(vmStatusColor(vehicle.status))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(vmStatusColor(vehicle.status).opacity(0.1))
                .cornerRadius(20)
        }
        .padding(.horizontal, 24).padding(.vertical, 16)
        .background(Color.white)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Vehicle Info Card
    private var vehicleInfoCard: some View {
        CardWrapper {
            VStack(alignment: .leading, spacing: 0) {

                // ── Row A: Vehicle Number | Owner ──────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VEHICLE NUMBER").cardLabel()
                        Text(vmPlate(for: vehicle.id))
                            .font(.system(size: 20, weight: .black))
                            .tracking(0.8)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("OWNER").cardLabel()
                        Text(vehicle.make)
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .padding(22)

                Divider().padding(.horizontal, 22)

                // ── Row B: Model ─────────────────────────────
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MODEL").cardLabel()
                        Text(vehicle.model)
                            .font(.system(size: 15, weight: .bold))
                    }
                    Spacer()
                }
                .padding(22)
            }
        }
    }

    // MARK: - Active Trip Card
    private func activeTripCard(trip: VehicleTrip) -> some View {
        CardWrapper {
            VStack(alignment: .leading, spacing: 16) {
                // Header: label + ETA
                HStack(alignment: .top) {
                    Text("ACTIVE TRIP").cardLabel()
                    Spacer()
                    let etaValue = routeEta.isEmpty ? trip.eta : routeEta
                    if !etaValue.isEmpty {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("ETA").cardLabel()
                            Text(etaValue)
                                .font(.system(size: 18, weight: .black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                }
                Divider()
                // FROM → TO horizontal
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("FROM").cardLabel()
                        Text(trip.origin)
                            .font(.system(size: 18, weight: .black))
                            .lineLimit(2)
                            .minimumScaleFactor(0.65)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                        .padding(.top, 16)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("TO").cardLabel()
                        Text(trip.destination)
                            .font(.system(size: 18, weight: .black))
                            .lineLimit(2)
                            .minimumScaleFactor(0.65)
                    }
                }
                Divider()
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DISTANCE").cardLabel()
                        Text(routeDistance.isEmpty ? (trip.distance ?? "Calculating") : routeDistance)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer()
                }
            }
            .padding(22)
        }
    }

    // MARK: - Driver Card
    private func driverCard(driver: Driver) -> some View {
        CardWrapper {
            VStack(alignment: .leading, spacing: 16) {
                Text("ASSIGNED DRIVER").cardLabel()
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 22))
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(driver.name).font(.system(size: 17, weight: .bold))
                        Text(driver.title.uppercased()).cardLabel()
                    }
                    Spacer()
                    Circle().fill(AppTheme.activeGreen).frame(width: 9, height: 9)
                }
                if let route = driver.activeRoute {
                    Divider()
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.primary)
                        Text(route)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        if let eta = driver.eta {
                            Text(eta).font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                }
            }
            .padding(22)
        }
    }

    private func loadRouteMetrics() async {
        guard let trip = vehicle.currentTrip else {
            await MainActor.run {
                routeEta = ""
                routeDistance = ""
                routeDuration = ""
            }
            return
        }

        do {
            let route = try await FleetDirectionsService.shared.fetchDirections(
                origin: trip.origin,
                destination: trip.destination
            )
            await MainActor.run {
                routeEta = route.eta
                routeDistance = route.distance
                routeDuration = route.eta
            }
        } catch {
            await MainActor.run {
                routeEta = trip.eta
                routeDistance = trip.distance ?? ""
                routeDuration = trip.duration ?? ""
            }
            print("Vehicle route metrics failed: \(error)")
        }
    }

    // MARK: - Maintenance Card (next service only, no heading)
    private var maintenanceCard: some View {
        CardWrapper {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.08))
                            .frame(width: 44, height: 44)
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NEXT SERVICE")
                            .cardLabel()
                        Text(formattedNextService)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Based on vehicle registration date")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.green)
                        Text("Scheduled")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(22)
        }
    }
    
    private var formattedNextService: String {
        let dateStr = vehicle.maintenance.nextService
        guard !dateStr.isEmpty else { return "Not set" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Recent History Card
    private var recentHistoryCard: some View {
        Group {
            if vehicle.history.count > 2 {
                NavigationLink(destination: VehicleLogView(vehicle: vehicle)) {
                    historyCardBody
                        .overlay(chevronTopRight, alignment: .topTrailing)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                historyCardBody
            }
        }
    }

    private var historyCardBody: some View {
        CardWrapper {
            VStack(alignment: .leading, spacing: 14) {
                Text("RECENT HISTORY").cardLabel()
                if vehicle.history.isEmpty {
                    emptyState(icon: "clock.arrow.circlepath", message: "No history yet")
                } else {
                    let preview = Array(vehicle.history.prefix(2))
                    VStack(spacing: 0) {
                        ForEach(preview) { trip in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(trip.date ?? "").cardLabel()
                                    Text("\(trip.origin)  →  \(trip.destination)")
                                        .font(.system(size: 13, weight: .bold))
                                    if let d = trip.distance, let dr = trip.duration {
                                        Text("\(d)  •  \(dr)")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                                Text("DONE")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(AppTheme.activeGreen)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(AppTheme.activeGreen.opacity(0.1))
                                    .cornerRadius(5)
                            }
                            .padding(.vertical, 10)
                            if trip.id != preview.last?.id { Divider() }
                        }
                    }
                    if vehicle.history.count > 2 {
                        Divider()
                        Text("Tap to view all \(vehicle.history.count) trips")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(22)
        }
    }

    // MARK: - Past Reports Card
    private var pastReportsCard: some View {
        Group {
            if vehicle.reports.count > 2 {
                NavigationLink(destination: ArchiveListView(vehicle: vehicle)) {
                    reportsCardBody
                        .overlay(chevronTopRight, alignment: .topTrailing)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                reportsCardBody
            }
        }
    }

    private var reportsCardBody: some View {
        CardWrapper {
            VStack(alignment: .leading, spacing: 14) {
                Text("PAST REPORTS").cardLabel()
                if vehicle.reports.isEmpty {
                    emptyState(icon: "doc.text", message: "No reports yet")
                } else {
                    let preview = Array(vehicle.reports.prefix(2))
                    VStack(spacing: 0) {
                        ForEach(preview) { report in
                            NavigationLink(destination: MaintenanceReportDetailView(report: report, vehicle: vehicle)) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 9)
                                            .fill(AppTheme.criticalRed.opacity(0.08))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 15))
                                            .foregroundColor(AppTheme.criticalRed)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(report.title)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text(report.subtitle)
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            if report.id != preview.last?.id { Divider() }
                        }
                    }
                    if vehicle.reports.count > 2 {
                        Divider()
                        Text("Tap to view all \(vehicle.reports.count) reports")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(22)
        }
    }

    // MARK: - Shared helpers
    private var chevronTopRight: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(AppTheme.primary)
            .padding(18)
    }

    private func emptyState(icon: String, message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.gray.opacity(0.4))
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Card Label Style
private extension Text {
    func cardLabel() -> some View {
        self
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.gray)
    }
}

// MARK: - Info Pair
private struct InfoPair: View {
    let label: String; let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).cardLabel()
            Text(value).font(.system(size: 14, weight: .bold))
        }
    }
}

// MARK: - Maintenance Flow Step
private struct MaintenanceFlowStep: View {
    let icon: String; let iconColor: Color
    let title: String; let detail: String
    let detailColor: Color; let isLast: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.1)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 13)).foregroundColor(iconColor)
                }
                if !isLast {
                    Rectangle().fill(Color(.systemGray4))
                        .frame(width: 2).frame(minHeight: 22)
                        .padding(.vertical, 3)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).cardLabel()
                Text(detail).font(.system(size: 13, weight: .semibold))
                    .foregroundColor(detailColor)
            }
            .padding(.top, 6)
            .padding(.bottom, isLast ? 0 : 18)
            Spacer()
        }
    }
}
