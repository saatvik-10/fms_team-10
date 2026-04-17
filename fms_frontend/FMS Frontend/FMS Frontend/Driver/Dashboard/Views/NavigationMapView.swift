//
//  NavigationMapView.swift
//  FMS Frontend
//
//  Created by Mrunal Aralkar on 17/04/26.
//

import SwiftUI
import MapKit

// MARK: - Custom Map Annotation

struct StopAnnotation: Identifiable {
    let id = UUID()
    let stop: TripStop
    let isActive: Bool
    let isDestination: Bool
}

// MARK: - Navigation Map View

struct NavigationMapView: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss

    @State private var region: MKCoordinateRegion
    @State private var routeOverlay: MKPolyline?
    @State private var showStopCard: Bool = false
    @State private var selectedStop: TripStop? = nil
    @State private var showTurnByTurn = false

    // Build ordered list: pickup → stops → destination
    private var allStops: [TripStop] {
        [trip.pickup] + trip.stops + [trip.destination]
    }

    // Only show from active stop onwards
    private var remainingStops: [TripStop] {
        guard let activeIndex = allStops.firstIndex(where: { $0.status == .active }) else {
            return allStops
        }
        return Array(allStops[activeIndex...])
    }

    private var annotations: [StopAnnotation] {
        remainingStops.map { stop in
            StopAnnotation(
                stop: stop,
                isActive: stop.status == .active,
                isDestination: stop.name == trip.destination.name
            )
        }
    }

    init(trip: Trip) {
        self.trip = trip

        let activeLat = 24.5854
        let activeLon = 73.7125
        let destLat = 28.4815
        let destLon = 77.0736

        let centerLat = (activeLat + destLat) / 2
        let centerLon = (activeLon + destLon) / 2
        let spanLat = abs(destLat - activeLat) * 1.4
        let spanLon = abs(destLon - activeLon) * 1.4

        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {

            // MARK: - Map
            RouteMapViewRepresentable(
                stops: remainingStops,
                region: $region
            )
            .ignoresSafeArea()

            // MARK: - Top Bar
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.black.opacity(0.7))
                                .frame(width: 40, height: 40)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Route \(trip.routeNumber)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Navigating to \(trip.destination.name)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    // ETA badge
                    VStack(spacing: 1) {
                        Text("ETA")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        Text(trip.destination.time)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.87, blue: 0.49))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.85), .black.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // MARK: - Bottom Stop Cards
            VStack {
                Spacer()

                VStack(spacing: 12) {
                    // Upcoming stops scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(remainingStops) { stop in
                                StopChip(stop: stop, isActive: stop.status == .active)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.35)) {
                                            region.center = stop.coordinate
                                            region.span = MKCoordinateSpan(
                                                latitudeDelta: 0.5,
                                                longitudeDelta: 0.5
                                            )
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Active stop card
                    if let active = remainingStops.first(where: { $0.status == .active }) {
                        ActiveStopCard(stop: active, destination: trip.destination)
                            .padding(.horizontal, 16)
                    }

                    // Start Navigation button
                    Button {
                        showTurnByTurn = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                            Text("Start Navigation")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.18, green: 0.87, blue: 0.49))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 16)
                    .fullScreenCover(isPresented: $showTurnByTurn) {
                        TurnByTurnNavigationView(trip: trip)
                    }

                    Spacer().frame(height: 8)
                }
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0), .black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - MapKit UIViewRepresentable

struct RouteMapViewRepresentable: UIViewRepresentable {
    let stops: [TripStop]
    @Binding var region: MKCoordinateRegion

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.overrideUserInterfaceStyle = .dark
        mapView.showsUserLocation = false
        mapView.isRotateEnabled = false
        mapView.setRegion(region, animated: false)

        // Polyline
        let coords = stops.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        mapView.addOverlay(polyline)

        // Markers
        for stop in stops {
            let annotation = StopPointAnnotation(stop: stop)
            mapView.addAnnotation(annotation)
        }

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 0.18, green: 0.87, blue: 0.49, alpha: 1.0)
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let stop = annotation as? StopPointAnnotation else { return nil }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "stop")
            view.canShowCallout = true
            switch stop.stop.status {
            case .active:
                view.markerTintColor = UIColor(red: 0.18, green: 0.87, blue: 0.49, alpha: 1.0)
            case .upcoming:
                view.markerTintColor = .white
            case .completed:
                view.markerTintColor = .gray
            }
            return view
        }
    }
}

class StopPointAnnotation: NSObject, MKAnnotation {
    let stop: TripStop
    var coordinate: CLLocationCoordinate2D { stop.coordinate }
    var title: String? { stop.name }
    var subtitle: String? { stop.time }
    init(stop: TripStop) { self.stop = stop }
}

// MARK: - Stop Chip (horizontal scroll)

struct StopChip: View {
    let stop: TripStop
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive
                      ? Color(red: 0.18, green: 0.87, blue: 0.49)
                      : Color.white.opacity(0.4))
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 1) {
                Text(stop.name.components(separatedBy: ",").first ?? stop.name)
                    .font(.system(size: 12, weight: isActive ? .bold : .medium))
                    .foregroundColor(isActive ? .white : .white.opacity(0.6))
                    .lineLimit(1)

                Text(stop.time)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(isActive
                                     ? Color(red: 0.18, green: 0.87, blue: 0.49)
                                     : .white.opacity(0.4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isActive
                      ? Color(red: 0.18, green: 0.87, blue: 0.49).opacity(0.15)
                      : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isActive
                            ? Color(red: 0.18, green: 0.87, blue: 0.49).opacity(0.5)
                            : Color.white.opacity(0.15),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Active Stop Card

struct ActiveStopCard: View {
    let stop: TripStop
    let destination: TripStop

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.18, green: 0.87, blue: 0.49).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.18, green: 0.87, blue: 0.49))
            }

            // Current & next
            VStack(alignment: .leading, spacing: 4) {
                Text("Currently at")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(stop.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            // Next stop arrow
            VStack(alignment: .trailing, spacing: 4) {
                Text("Next stop")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                HStack(spacing: 4) {
                    Text(destination.name.components(separatedBy: ",").first ?? destination.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.18, green: 0.87, blue: 0.49))
                        .lineLimit(1)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.87, blue: 0.49))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationMapView(trip: Trip.mockTrip)
}
