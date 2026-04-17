import SwiftUI
import GoogleMaps
import CoreLocation

struct TripDetailView: View {
    let trip: Trip
    
    @State private var estimatedArrival: String = "Loading..."
    @State private var routePolyline: String = ""
    @State private var isLoadingEta: Bool = true
    
    // Date-gate: Compare today's date against trip date (e.g. "Oct 18")
    private var isNavigationEnabled: Bool {
        guard !trip.tripDate.isEmpty else { return true } // No lock if date is blank
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let todayString = formatter.string(from: Date())
        return todayString == trip.tripDate
    }
    
    // Extracted shared padding for precise alignment
    private let horizontalPadding: CGFloat = 20
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // HEADER ROUTE NAME
                Text("\(trip.pickup.name.split(separator: ",").first ?? "") ➝ \(trip.destination.name.split(separator: ",").first ?? "")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, horizontalPadding)
                
                // TOP SECTION (NEW: CARDS)
                HStack(spacing: 16) {
                    // ETA Card
                    MetricCardView(
                        title: "ESTIMATED ARRIVAL",
                        value: estimatedArrival,
                        subtext: isLoadingEta ? "" : "On time",
                        isLoading: isLoadingEta
                    )
                    
                    // Cargo Load Card
                    MetricCardView(
                        title: "CARGO LOAD",
                        value: trip.cargoWeight,
                        subtext: trip.cargoUnits,
                        isLoading: false
                    )
                }
                .padding(.horizontal, horizontalPadding)
                
                // MAP SECTION (Google Maps SDK)
                GoogleTripMapView(trip: trip, encodedPolyline: routePolyline)
                    .frame(height: 250)
                    .cornerRadius(16) // Applied to container matching Timeline
                    .padding(.horizontal, horizontalPadding)
                    .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
                
                // TIMELINE SECTION (Must match Map horizontally identically)
                VStack(alignment: .leading, spacing: 0) {
                    Text("ROUTE PROGRESS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.bottom, 16)
                    
                    TimelineView(trip: trip)
                }
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(16)
                // Ensures identical horizontal padding matching Map parent bounds
                .padding(.horizontal, horizontalPadding)
                .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 4)
                
                // ROUTE DETAILS
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
                
                // ACTION BUTTON
                ZStack {
                    PrimaryButton(
                        title: "Continue Navigation",
                        icon: "location.fill",
                        backgroundColor: AppColors.primary,
                        textColor: .white
                    ) {
                        // Start navigation action
                    }
                    .allowsHitTesting(isNavigationEnabled)
                    
                    // Disabled overlay: faded effect without changing the button's look
                    if !isNavigationEnabled {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemBackground).opacity(0.45))
                            .allowsHitTesting(false)
                    }
                }
                .opacity(isNavigationEnabled ? 1.0 : 0.5)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .background(AppColors.screenBackground.ignoresSafeArea())
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
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
        return [trip.pickup] + trip.stops + [trip.destination]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(allStops.enumerated()), id: \.element.id) { index, stop in
                HStack(alignment: .top, spacing: 16) {
                    // Time column
                    Text(stop.time)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.secondaryText)
                        .frame(width: 65, alignment: .leading) // Left aligned timeframe
                        .padding(.top, 4)
                    
                    // Line and Indicator column
                    VStack(spacing: 0) {
                        // Indicator
                        Circle()
                            .fill(indicatorColor(for: stop.status))
                            .overlay(
                                Circle()
                                    .stroke(indicatorStrokeColor(for: stop.status), lineWidth: 2)
                            )
                            .frame(width: 14, height: 14)
                            .padding(.top, 4)
                        
                        // Line
                        if index < allStops.count - 1 {
                            Rectangle()
                                .fill(AppColors.secondaryText.opacity(0.3))
                                .frame(width: 2)
                                .frame(minHeight: 40)
                                .padding(.vertical, 2)
                        }
                    }
                    
                    // Content
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
    
    // Status Logic
    // completed -> green text + grey dot
    // active -> bold + navy filled dot
    // upcoming -> light grey + outlined dot
    
    private func indicatorColor(for status: StopStatus) -> Color {
        switch status {
        case .completed: return AppColors.secondaryText // Grey filled dot
        case .active: return AppColors.primary // Navy filled dot
        case .upcoming: return AppColors.cardBackground // Outlined (white filled) dot
        }
    }
    
    private func indicatorStrokeColor(for status: StopStatus) -> Color {
        switch status {
        case .completed: return .clear
        case .active: return .clear
        case .upcoming: return AppColors.secondaryText // Light grey stroke
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
        case .completed: return AppColors.success // Green Text
        case .active: return AppColors.primary
        case .upcoming: return AppColors.secondaryText
        }
    }
}

// MARK: - Google Maps SDK Wrapper

struct GoogleTripMapView: UIViewRepresentable {
    let trip: Trip
    let encodedPolyline: String
    
    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        let mapView = GMSMapView(options: options)
        mapView.isUserInteractionEnabled = false // Standard map display without scroll disruption
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        uiView.clear() // Clear existing overlays to prevent duplicates
        
        // Setup marker coordinates tracking for bounds
        var bounds = GMSCoordinateBounds()
        let allStops = [trip.pickup] + trip.stops + [trip.destination]
        
        for stop in allStops {
            let marker = GMSMarker()
            marker.position = stop.coordinate
            marker.title = stop.name
            
            // Map markers conceptually matching status schemas
            if stop.status == .completed {
                marker.icon = GMSMarker.markerImage(with: .gray)
            } else if stop.status == .active {
                // Derived AppColors.primary HEX 0F1C24 translation to UIColor
                let navyColor = UIColor(red: 15/255, green: 28/255, blue: 36/255, alpha: 1)
                marker.icon = GMSMarker.markerImage(with: navyColor)
            } else {
                marker.icon = GMSMarker.markerImage(with: .lightGray)
            }
            
            marker.map = uiView
            bounds = bounds.includingCoordinate(stop.coordinate)
        }
        
        // Re-construct the exact route polyline visually returned from Directions Matrix
        if !encodedPolyline.isEmpty {
            if let path = GMSPath(fromEncodedPath: encodedPolyline) {
                let polyline = GMSPolyline(path: path)
                polyline.strokeColor = UIColor(red: 15/255, green: 28/255, blue: 36/255, alpha: 1) // #0F1C24
                polyline.strokeWidth = 4.0 // Prominent distinct path line
                polyline.map = uiView
            }
        }
        
        if bounds.isValid {
            // Apply camera bounds mapping with padding
            let update = GMSCameraUpdate.fit(bounds, withPadding: 40.0)
            uiView.animate(with: update)
        }
    }
}
