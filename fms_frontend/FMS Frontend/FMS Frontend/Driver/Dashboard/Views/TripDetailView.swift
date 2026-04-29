import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Trip Progress State

enum TripProgressState {
    case notStarted   // status = SCHEDULED, departure time not reached
    case canStart     // status = SCHEDULED, departure time reached
    case inProgress   // status = IN_TRANSIT (navigation active)
    case ended        // status = COMPLETED locally
}

// MARK: - TripDetailView

struct TripDetailView: View {
    let trip: Trip

    var showTripControls: Bool = false
    var lifecycleTrip: LifecycleTrip? = nil
    var onTripEnded: (() -> Void)? = nil

    @State private var estimatedArrival: String = "Loading..."
    @State private var routePolyline: String = ""
    @State private var isLoadingEta: Bool = true
    @State private var resolvedDestinationCoordinate: CLLocationCoordinate2D?

    @StateObject private var locationManager = LocationManager()

    // Trip state
    @State private var currentStatus: TripStatus
    @State private var isStartingTrip: Bool = false
    @State private var isEndingTrip: Bool = false
    @State private var actionError: String? = nil

    // Navigation
    @State private var showNavigationMap = false
    @State private var showReportIssue = false

    private let horizontalPadding: CGFloat = 20

    init(trip: Trip,
         showTripControls: Bool = false,
         lifecycleTrip: LifecycleTrip? = nil,
         onTripEnded: (() -> Void)? = nil) {
        self.trip = trip
        self.showTripControls = showTripControls
        self.lifecycleTrip = lifecycleTrip
        self.onTripEnded = onTripEnded
        // Initialise current status from lifecycle trip so we track local mutations
        _currentStatus = State(initialValue: lifecycleTrip?.status ?? .scheduled)
    }

    // MARK: - Derived State

    private var isCompleted: Bool   { currentStatus == .completed }
    private var isOngoing: Bool     { currentStatus == .ongoing }
    private var isScheduled: Bool   { currentStatus == .scheduled }

    /// Start button is visible and active only when:
    ///  - status is SCHEDULED
    ///  - AND departure time has been reached
    private var canStartTrip: Bool {
        isScheduled && (lifecycleTrip?.isDepartureReached ?? false)
    }

    private var tripId: String {
        lifecycleTrip?.id ?? trip.routeNumber
    }

    // MARK: - ETA Formatter

    private func formatETA(_ eta: String) -> String {
        eta
            .replacingOccurrences(of: " hours", with: " hrs")
            .replacingOccurrences(of: " hour",  with: " hr")
            .replacingOccurrences(of: " mins",  with: " min")
            .replacingOccurrences(of: " minutes", with: " min")
            .replacingOccurrences(of: " minute",  with: " min")
    }

    // MARK: - Body

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

                VStack(alignment: .leading, spacing: 16) {
                    RouteDetailRow(label: "PICKUP",      value: trip.pickup.name)
                    RouteDetailRow(label: "DESTINATION", value: trip.destination.name)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal, horizontalPadding)
                .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 4)

                // Error banner
                if let err = actionError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, horizontalPadding)
                }

                // Action buttons
                actionButtonsSection

            }
            .padding(.top, 16)
        }
        .background(AppColors.screenBackground.ignoresSafeArea())
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showNavigationMap) {
            CustomNavigationView(
                trip: trip,
                resolvedDestinationCoordinate: resolvedDestinationCoordinate,
                onEndTrip: {
                    showNavigationMap = false
                    handleEndTrip()
                }
            )
        }
        .navigationDestination(isPresented: $showReportIssue) {
            if let lt = lifecycleTrip {
                ReportIssueView(trip: lt)
            } else {
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
            await fetchStaticRoute()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            guard let currentLoc = newLocation else { return }
            let destination = resolvedDestinationCoordinate ?? trip.destination.coordinate
            guard CLLocationCoordinate2DIsValid(destination),
                  !(destination.latitude == 0 && destination.longitude == 0) else { return }
            Task {
                do {
                    let result = try await GoogleDirectionsService.shared.fetchSegmentDirections(
                        origin: currentLoc.coordinate,
                        destination: destination
                    )
                    self.estimatedArrival = formatETA(result.eta)
                    self.isLoadingEta = false
                } catch {
                    self.estimatedArrival = "Unavailable"
                    self.isLoadingEta = false
                }
            }
        }
    }

    // MARK: - Static Route Fetch

    private func fetchStaticRoute() async {
        do {
            let result = try await GoogleDirectionsService.shared.fetchDirections(trip: trip)
            routePolyline = result.polyline
            resolvedDestinationCoordinate = result.destinationCoordinate
            estimatedArrival = formatETA(result.eta)
            isLoadingEta = false
        } catch {
            estimatedArrival = "Unavailable"
            isLoadingEta = false
        }
    }

    // MARK: - Action Buttons Section

    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if isCompleted {
                completedBanner

            } else if isOngoing {
                // IN TRANSIT — show navigation + end trip
                PrimaryButton(
                    title: "Continue Navigation",
                    icon: "location.fill",
                    backgroundColor: Color(hex: "0a303a"),
                    textColor: .white
                ) {
                    showNavigationMap = true
                }

                endTripButton

            } else {
                // SCHEDULED
                if canStartTrip {
                    // Departure reached → Start Trip ENABLED
                    PrimaryButton(
                        title: isStartingTrip ? "Starting…" : "Start Trip",
                        icon: "arrow.right.circle.fill",
                        backgroundColor: Color(hex: "0a303a"),
                        textColor: .white
                    ) {
                        guard !isStartingTrip else { return }
                        handleStartTrip()
                    }
                    .disabled(isStartingTrip)
                    .opacity(isStartingTrip ? 0.6 : 1.0)
                } else {
                    // Departure not yet reached → Start Trip DISABLED
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption)
                                .foregroundColor(AppColors.secondaryText)
                            Text("Available from \(lifecycleTrip?.scheduledDateTimeText ?? trip.tripDate)")
                                .font(.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        PrimaryButton(
                            title: "Start Trip",
                            icon: "arrow.right.circle.fill",
                            backgroundColor: Color(hex: "0a303a"),
                            textColor: .white
                        ) { /* disabled */ }
                        .allowsHitTesting(false)
                        .opacity(0.4)
                    }
                }
            }

            if !isCompleted {
                reportIssueButton
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 32)
    }

    // MARK: - Start Trip

    private func handleStartTrip() {
        guard !isStartingTrip else { return }
        isStartingTrip = true
        actionError = nil

        Task {
            do {
                _ = try await TripAPI.shared.startTripForDriver(tripId: tripId)
                currentStatus = .ongoing
                // Open navigation immediately after start
                showNavigationMap = true
            } catch {
                actionError = "Could not start trip: \(error.localizedDescription)"
            }
            isStartingTrip = false
        }
    }

    // MARK: - End Trip

    private func handleEndTrip() {
        guard !isEndingTrip else { return }
        isEndingTrip = true
        actionError = nil

        Task {
            do {
                _ = try await TripAPI.shared.completeTripForDriver(tripId: tripId)
                currentStatus = .completed
                onTripEnded?()
            } catch {
                // Still mark locally even if backend call fails (optimistic)
                currentStatus = .completed
                onTripEnded?()
                print("⚠️ Complete trip backend error: \(error.localizedDescription)")
            }
            isEndingTrip = false
        }
    }

    // MARK: - Sub-views

    private var completedBanner: some View {
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

    private var endTripButton: some View {
        Button {
            handleEndTrip()
        } label: {
            HStack(spacing: 8) {
                if isEndingTrip {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 14, weight: .bold))
                }
                Text(isEndingTrip ? "Ending…" : "End Trip")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red)
            .cornerRadius(12)
        }
        .disabled(isEndingTrip)
        .opacity(isEndingTrip ? 0.6 : 1.0)
    }

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
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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

// MARK: - Timeline

struct TimelineView: View {
    let trip: Trip

    var allStops: [TripStop] { [trip.pickup, trip.destination] }

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
                            .overlay(Circle().stroke(indicatorStrokeColor(for: stop.status), lineWidth: 2))
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
        case .active:    return AppColors.primary
        case .upcoming:  return AppColors.cardBackground
        }
    }

    private func indicatorStrokeColor(for status: StopStatus) -> Color {
        switch status {
        case .upcoming: return AppColors.secondaryText
        default:        return .clear
        }
    }

    private func textColor(for status: StopStatus) -> Color {
        switch status {
        case .upcoming: return AppColors.secondaryText
        default:        return AppColors.primaryText
        }
    }

    private func statusText(for status: StopStatus) -> String {
        switch status {
        case .completed: return "Completed"
        case .active:    return "In Progress"
        case .upcoming:  return "Scheduled"
        }
    }

    private func statusTextColor(for status: StopStatus) -> Color {
        switch status {
        case .completed: return AppColors.success
        case .active:    return AppColors.primary
        case .upcoming:  return AppColors.secondaryText
        }
    }
}

// MARK: - Google Trip Map

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

        let dest = trip.destination
        let navyColor = UIColor(red: 15/255, green: 28/255, blue: 36/255, alpha: 1)

        let marker = GMSMarker(position: dest.coordinate)
        marker.title = dest.name
        marker.icon = GMSMarker.markerImage(with: navyColor)
        marker.map = uiView

        if !encodedPolyline.isEmpty, let path = GMSPath(fromEncodedPath: encodedPolyline) {
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = navyColor
            polyline.strokeWidth = 6.0
            polyline.map = uiView

            let bounds = GMSCoordinateBounds(path: path)
            if bounds.isValid {
                DispatchQueue.main.async {
                    uiView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 40.0))
                }
            }
        } else if CLLocationCoordinate2DIsValid(dest.coordinate),
                  !(dest.coordinate.latitude == 0 && dest.coordinate.longitude == 0) {
            uiView.animate(to: GMSCameraPosition.camera(withTarget: dest.coordinate, zoom: 14))
        }
    }
}
