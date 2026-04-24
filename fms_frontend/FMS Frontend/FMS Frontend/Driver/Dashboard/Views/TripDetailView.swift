import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Trip Progress State (Trips Tab Only)
// Drives the Start Trip / End Trip button UI.
// Teammate: inject real CLLocationDistance into distanceToDestinationMeters
// from your location/tracking layer to trigger state transitions.
enum TripProgressState {
    case notStarted      // Driver has not yet tapped "Start Trip"
    case inProgress      // Trip is underway; destination is far (>100 m)
    case nearDestination // CONSTRAINT: distance <= 100 m → "End Trip" unlocks
    case ended           // Trip completed (manually or auto-triggered)
}

struct TripDetailView: View {
    let trip: Trip

    // Set true when navigating from the Trips tab (TripsView).
    // Keeps the Home tab's "Continue Navigation" button completely unchanged.
    var showTripControls: Bool = false

    // Passed from TripsView so ReportIssueView gets the full LifecycleTrip model.
    var lifecycleTrip: LifecycleTrip? = nil

    @State private var estimatedArrival: String = "Loading..."
    @State private var routePolyline: String = ""
    @State private var isLoadingEta: Bool = true

    // ── Trips-tab state ───────────────────────────────────────────────────
    // TEAMMATE HOOK: Update distanceToDestinationMeters from your tracking
    // ViewModel/service. The UI reacts to its value automatically.
    @State var distanceToDestinationMeters: Double = 999  // stub — far by default
    @State private var tripProgressState: TripProgressState = .notStarted

    // CONSTRAINT: "End Trip" button is enabled when distance ≤ 100 m
    private var isEndTripEnabled: Bool {
        distanceToDestinationMeters <= 100
    }

    // CONSTRAINT: Auto-end trip when distance reaches 0 m (exact destination)
    private var hasReachedDestination: Bool {
        distanceToDestinationMeters <= 0
    }

    // ── Home-tab gate (unchanged behaviour) ───────────────────────────────
    // Date-gate: Compare today's date against trip date (e.g. "Oct 18")
    private var isNavigationEnabled: Bool {
        guard !trip.tripDate.isEmpty else { return true } // No lock if date is blank
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let todayString = formatter.string(from: Date())
        return todayString == trip.tripDate
    }

    // Extracted shared padding for precise alignment
    @State private var showMap = false
    @State private var showNavigationMap = false
    @State private var showReportIssue = false

    private let horizontalPadding: CGFloat = 20
    
//    private var isNavigationEnabled: Bool {
//        !isLoadingEta && !routePolyline.isEmpty
//    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                Text("\(trip.pickup.name.split(separator: ",").first ?? "") ➝ \(trip.destination.name.split(separator: ",").first ?? "")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, horizontalPadding)
                
                HStack(spacing: 16) {
                    MetricCardView(
                        title: "ESTIMATED ARRIVAL",
                        value: estimatedArrival,
                        subtext: isLoadingEta ? "" : "On time",
                        isLoading: isLoadingEta
                    )
                    MetricCardView(
                        title: "CARGO LOAD",
                        value: trip.cargoWeight,
                        subtext: trip.cargoUnits,
                        isLoading: false
                    )
                }
                .padding(.horizontal, horizontalPadding)
                
                GoogleTripMapView(trip: trip, encodedPolyline: routePolyline)
                    .frame(height: 250)
                    .cornerRadius(16)
                    .padding(.horizontal, horizontalPadding)
                    .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
                
                // ROUTE PROGRESS card removed (UI only) — TimelineView & stop data unchanged
                
                VStack(alignment: .leading, spacing: 16) {
                    RouteDetailRow(label: "PICKUP", value: trip.pickup.name)
                    RouteDetailRow(label: "DESTINATION", value: trip.destination.name)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal, horizontalPadding)
                .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 4)
                
                // ACTION BUTTONS
                if showTripControls {
                    // ── TRIPS TAB: State-driven Start / End Trip ──────────
                    tripActionButtons
                } else {
                    // ── HOME TAB: Original "Continue Navigation" (unchanged) ──
                    VStack(spacing: 16) {
                        ZStack {
                            PrimaryButton(
                                title: "Continue Navigation",
                                icon: "location.fill",
                                backgroundColor: Color(hex: "0a303a"),
                                textColor: .white
                            ) {
                                showNavigationMap = true
                            }
                            .allowsHitTesting(isNavigationEnabled)

                            if !isNavigationEnabled {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemBackground).opacity(0.45))
                                    .allowsHitTesting(false)
                            }
                        }
                        .opacity(isNavigationEnabled ? 1.0 : 0.5)

                        reportIssueButton
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 32)
                }
            }
            .padding(.top, 16)
        }
        .background(AppColors.screenBackground.ignoresSafeArea())
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showNavigationMap) {
            CustomNavigationView(trip: trip)
        }
        // ── Report Issue push navigation ──────────────────────────────────
        .navigationDestination(isPresented: $showReportIssue) {
            if let lt = lifecycleTrip {
                ReportIssueView(trip: lt)
            } else {
                // Synthesize a LifecycleTrip if navigating from the Home tab
                ReportIssueView(trip: LifecycleTrip(
                    id: trip.routeNumber,
                    source: trip.pickup.name,
                    destination: trip.destination.name,
                    status: .scheduled,
                    dateValue: trip.tripDate,
                    timeLabel: "Start",
                    timeValue: trip.pickup.time,
                    loadInfo: "N/A",
                    distance: 0.0,
                    vehicleNumber: nil
                ))
            }
        }
        .task {
            do {
                let result = try await GoogleDirectionsService.shared.fetchDirections(trip: trip)
                DispatchQueue.main.async {
                    self.estimatedArrival = result.eta
                    self.routePolyline = result.polyline
                    self.isLoadingEta = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.estimatedArrival = "Unavailable"
                    self.isLoadingEta = false
                }
            }
        }
        // CONSTRAINT: Watch distance and auto-end when destination reached
        .onChange(of: distanceToDestinationMeters) { _, newDistance in
            guard showTripControls else { return }
            if tripProgressState == .inProgress || tripProgressState == .nearDestination {
                if newDistance <= 0 {
                    // AUTO-END: Driver has reached exact destination
                    tripProgressState = .ended
                } else if newDistance <= 100 {
                    // NEAR DESTINATION: Unlock "End Trip" button (50–100 m range)
                    tripProgressState = .nearDestination
                } else {
                    // Back in progress if somehow distance increases (edge case)
                    tripProgressState = .inProgress
                }
            }
        }
    }

    // MARK: - Trips Tab Action Buttons

    @ViewBuilder
    private var tripActionButtons: some View {
        VStack(spacing: 12) {
            switch tripProgressState {

            case .notStarted:
                // ── START TRIP button ─────────────────────────────────────
                // CONSTRAINT: Only enabled on the scheduled trip date.
                // Reuses the same date-gate as the Home tab's Continue Navigation.
                if !isNavigationEnabled && !trip.tripDate.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                        Text("Available on \(trip.tripDate)")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                ZStack {
                    PrimaryButton(
                        title: "Start Trip",
                        icon: "arrow.right.circle.fill",
                        backgroundColor: Color(hex: "0a303a"),
                        textColor: .white
                    ) {
                        // TEAMMATE: trigger your navigation/tracking start here
                        guard isNavigationEnabled else { return }
                        tripProgressState = .inProgress
                    }
                    .allowsHitTesting(isNavigationEnabled)

                    // Disabled overlay when trip date hasn't arrived
                    if !isNavigationEnabled {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemBackground).opacity(0.45))
                            .allowsHitTesting(false)
                    }
                }
                .opacity(isNavigationEnabled ? 1.0 : 0.45)


            case .inProgress:
                // ── END TRIP button (locked — too far from destination) ───
                distanceHintLabel
                endTripButton(enabled: false)

            case .nearDestination:
                // ── END TRIP button (unlocked — within 100 m) ─────────────
                distanceHintLabel
                endTripButton(enabled: true)

            case .ended:
                // ── TRIP ENDED confirmation banner ────────────────────────
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(AppColors.success)
                        .font(.title3)
                    Text("Trip Completed")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.success.opacity(0.12))
                .cornerRadius(12)
            }
            
            // NOTE: Extracted outside switch for testing so it's always accessible
            reportIssueButton
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 32)
    }

    // MARK: - Sub-views

    /// Small hint showing how far the driver still is from the destination
    private var distanceHintLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "location.fill")
                .font(.caption)
                .foregroundColor(isEndTripEnabled ? AppColors.success : AppColors.secondaryText)
            Text(isEndTripEnabled
                 ? String(format: "%.0f m to destination — you can end the trip", distanceToDestinationMeters)
                 : String(format: "%.0f m to destination", distanceToDestinationMeters))
                .font(.caption)
                .foregroundColor(isEndTripEnabled ? AppColors.success : AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    /// "End Trip" button — appearance changes based on enabled state
    @ViewBuilder
    private func endTripButton(enabled: Bool) -> some View {
        ZStack {
            PrimaryButton(
                title: "End Trip",
                icon: "flag.checkered",
                backgroundColor: enabled ? AppColors.success : AppColors.secondaryText.opacity(0.25),
                textColor: enabled ? .white : AppColors.secondaryText
            ) {
                guard enabled else { return }
                // TEAMMATE: trigger your trip-end / stop-tracking logic here
                tripProgressState = .ended
            }
            .allowsHitTesting(enabled)

            // Blocked overlay when disabled
            if !enabled {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .allowsHitTesting(false)
            }
        }
        .opacity(enabled ? 1.0 : 0.45)
    }

    // MARK: - Report Issue Button

    /// Visible in all trip states for testing, now including the Home tab.
    private var reportIssueButton: some View {
        Button {
            showReportIssue = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Report Issue")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(Color(UIColor.label))
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Metric Card

struct MetricCardView: View {
    let title: String
    let value: String
    let subtext: String
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(AppColors.secondaryText)
            
            if isLoading {
                ProgressView()
                    .frame(height: 24)
            } else {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryText)
            }
            
            Text(subtext)
                .font(.caption2)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Timeline Component

struct TimelineView: View {
    let trip: Trip
    
    var allStops: [TripStop] {
        return [trip.pickup, trip.destination]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(allStops.enumerated()), id: \.element.id) { index, stop in
                HStack(alignment: .top, spacing: 16) {
                    Text(stop.time)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.secondaryText)
                        .frame(width: 65, alignment: .leading)
                        .padding(.top, 4)
                    
                    VStack(spacing: 0) {
                        Circle()
                            .fill(indicatorColor(for: stop.status))
                            .overlay(
                                Circle()
                                    .stroke(indicatorStrokeColor(for: stop.status), lineWidth: 2)
                            )
                            .frame(width: 14, height: 14)
                            .padding(.top, 4)
                        
                        if index < allStops.count - 1 {
                            Rectangle()
                                .fill(AppColors.secondaryText.opacity(0.3))
                                .frame(width: 2)
                                .frame(minHeight: 40)
                                .padding(.vertical, 2)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stop.name.split(separator: ",").first ?? "")
                            .font(.subheadline)
                            .fontWeight(stop.status == .active ? .bold : .regular)
                            .foregroundColor(textColor(for: stop.status))
                        
                        Text(statusText(for: stop.status))
                            .font(.caption)
                            .foregroundColor(statusTextColor(for: stop.status))
                    }
                    .padding(.top, 2)
                    .padding(.bottom, index == allStops.count - 1 ? 0 : 24)
                }
            }
        }
    }
    
    private func indicatorColor(for status: StopStatus) -> Color {
        switch status {
        case .completed: return AppColors.secondaryText
        case .active: return AppColors.primary
        case .upcoming: return AppColors.cardBackground
        }
    }
    
    private func indicatorStrokeColor(for status: StopStatus) -> Color {
        switch status {
        case .completed: return .clear
        case .active: return .clear
        case .upcoming: return AppColors.secondaryText
        }
    }
    
    private func textColor(for status: StopStatus) -> Color {
        switch status {
        case .completed: return AppColors.primaryText
        case .active: return AppColors.primaryText
        case .upcoming: return AppColors.secondaryText
        }
    }
    
    private func statusText(for status: StopStatus) -> String {
        switch status {
        case .completed: return "Completed"
        case .active: return "In Progress"
        case .upcoming: return "Scheduled"
        }
    }
    
    private func statusTextColor(for status: StopStatus) -> Color {
        switch status {
        case .completed: return AppColors.success
        case .active: return AppColors.primary
        case .upcoming: return AppColors.secondaryText
        }
    }
}

// MARK: - Google Maps SDK Wrapper

// MARK: - Google Maps SDK Wrapper (Navigation-aware preview)
// Replace the existing GoogleTripMapView struct with this one.

struct GoogleTripMapView: UIViewRepresentable {
    let trip: Trip
    let encodedPolyline: String

    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        let mapView = GMSMapView(options: options)
        mapView.isUserInteractionEnabled = false
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        uiView.clear()

        // Destination marker — route goes directly to trip.destination
        let activeStop = trip.destination

        let destMarker = GMSMarker(position: activeStop.coordinate)
        destMarker.title = activeStop.name
        let navyColor = UIColor(red: 15/255, green: 28/255, blue: 36/255, alpha: 1)
        destMarker.icon = GMSMarker.markerImage(with: navyColor)
        destMarker.map = uiView

        // Draw current-segment polyline only
        if !encodedPolyline.isEmpty, let path = GMSPath(fromEncodedPath: encodedPolyline) {
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = navyColor
            polyline.strokeWidth = 6.0
            polyline.map = uiView

            // Static overview: fit to polyline bounds (this is a preview, not live nav)
            let bounds = GMSCoordinateBounds(path: path)
            if bounds.isValid {
                DispatchQueue.main.async {
                    uiView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 40.0))
                }
            }
        } else if CLLocationCoordinate2DIsValid(activeStop.coordinate) {
            // Fallback: center on active stop
            uiView.animate(to: GMSCameraPosition.camera(
                withTarget: activeStop.coordinate, zoom: 14
            ))
        }
    }
}
