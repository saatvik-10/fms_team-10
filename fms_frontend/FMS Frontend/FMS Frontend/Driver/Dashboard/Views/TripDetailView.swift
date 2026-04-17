import SwiftUI
import GoogleMaps
import CoreLocation

struct TripDetailView: View {
    let trip: Trip
    
    @State private var estimatedArrival: String = "Loading..."
    @State private var routePolyline: String = ""
    @State private var isLoadingEta: Bool = true
    @State private var showMap = false
    @State private var showNavigationMap = false
    
    private let horizontalPadding: CGFloat = 20
    
    private var isNavigationEnabled: Bool {
        !isLoadingEta && !routePolyline.isEmpty
    }
    
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
                .padding(.horizontal, horizontalPadding)
                .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 4)
                
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
                
                ZStack {
                    PrimaryButton(
                        title: "Continue Navigation",
                        icon: "location.fill",
                        backgroundColor: AppColors.primary,
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
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .background(AppColors.screenBackground.ignoresSafeArea())
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showNavigationMap) {
            NavigationMapView(trip: trip)
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
        
        var bounds = GMSCoordinateBounds()
        let allStops = [trip.pickup] + trip.stops + [trip.destination]
        
        for stop in allStops {
            let marker = GMSMarker()
            marker.position = stop.coordinate
            marker.title = stop.name
            
            if stop.status == .completed {
                marker.icon = GMSMarker.markerImage(with: .gray)
            } else if stop.status == .active {
                let navyColor = UIColor(red: 15/255, green: 28/255, blue: 36/255, alpha: 1)
                marker.icon = GMSMarker.markerImage(with: navyColor)
            } else {
                marker.icon = GMSMarker.markerImage(with: .lightGray)
            }
            
            marker.map = uiView
            bounds = bounds.includingCoordinate(stop.coordinate)
        }
        
        if !encodedPolyline.isEmpty {
            if let path = GMSPath(fromEncodedPath: encodedPolyline) {
                let polyline = GMSPolyline(path: path)
                polyline.strokeColor = UIColor(red: 15/255, green: 28/255, blue: 36/255, alpha: 1)
                polyline.strokeWidth = 4.0
                polyline.map = uiView
            }
        }
        
        if bounds.isValid {
            let update = GMSCameraUpdate.fit(bounds, withPadding: 40.0)
            uiView.animate(with: update)
        }
    }
}
