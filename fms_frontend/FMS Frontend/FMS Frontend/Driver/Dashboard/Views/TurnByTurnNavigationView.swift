import SwiftUI
import MapKit
import UIKit

struct TurnByTurnNavigationView: View {
    @StateObject private var locationManager = LocationManager()
    let trip: Trip
    @Environment(\.dismiss) private var dismiss

    @State private var route: MKRoute?
    @State private var currentStepIndex: Int = 0
    @State private var region: MKCoordinateRegion
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var remainingDistance: String = ""
    @State private var remainingTime: String = ""

    private var origin: TripStop {
        trip.stops.first(where: { $0.status == .active }) ?? trip.pickup
    }

    private var destination: TripStop {
        trip.destination
    }

    init(trip: Trip) {
        self.trip = trip
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.0, longitude: 75.0),
            span: MKCoordinateSpan(latitudeDelta: 6.0, longitudeDelta: 6.0)
        ))
    }

    var remainingStopsCount: Int {
        let pendingStops = trip.stops.filter { $0.status != .completed }

        let destinationIncluded = trip.stops.contains {
            $0.coordinate.latitude == trip.destination.coordinate.latitude &&
            $0.coordinate.longitude == trip.destination.coordinate.longitude
        }

        return destinationIncluded ? pendingStops.count : pendingStops.count + 1
    }

    var body: some View {
        ZStack(alignment: .top) {

            // MAP
            if let route = route {
                NavigationRouteMapView(
                    route: route,
                    origin: origin,
                    destination: destination,
                    currentStepIndex: currentStepIndex,
                    region: $region
                )
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // TOP BAR
            if let route = route {
                let steps = route.steps.filter { !$0.instructions.isEmpty }
                let step = currentStepIndex < steps.count ? steps[currentStepIndex] : nil

                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }

                    Text(step?.instructions ?? "Navigate")
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.7))
            }
        }

        // ✅ CORRECT BOTTOM PANEL
        .overlay(
            Group {
                if route != nil {
                    VStack {
                        Spacer()

                        HStack(spacing: 0) {
                            
                            VStack(spacing: 4) {
                                Text(remainingTime)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                Text("ETA")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)

                            Divider()
                                .frame(height: 30)
                                .background(Color.white.opacity(0.2))

                            VStack(spacing: 4) {
                                Text(remainingDistance)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                Text("DISTANCE")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)

                            Divider()
                                .frame(height: 30)
                                .background(Color.white.opacity(0.2))

                            VStack(spacing: 4) {
                                Text("\(remainingStopsCount)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                Text("STOPS LEFT")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                        .background(Color.black)
                        .clipShape(RoundedCorner(radius: 24, corners: [.topLeft, .topRight]))
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            },
            alignment: .bottom
        )
        .navigationBarHidden(true)
        .onAppear { fetchRoute() }
    }

    func fetchRoute() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.transportType = .automobile

        MKDirections(request: request).calculate { response, _ in
            DispatchQueue.main.async {
                guard let route = response?.routes.first else { return }
                self.route = route
                self.remainingDistance = formatDistance(route.distance)
                self.remainingTime = formatTime(route.expectedTravelTime)
            }
        }
    }

    func formatDistance(_ meters: CLLocationDistance) -> String {
        meters >= 1000 ? String(format: "%.1f km", meters / 1000) : "\(Int(meters)) m"
    }

    func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        return mins >= 60 ? "\(mins/60)h \(mins%60)m" : "\(mins) min"
    }
}

// MARK: - Map View

struct NavigationRouteMapView: UIViewRepresentable {
    let route: MKRoute
    let origin: TripStop
    let destination: TripStop
    let currentStepIndex: Int
    @Binding var region: MKCoordinateRegion

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.addOverlay(route.polyline)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NavigationRouteMapView

        init(_ parent: NavigationRouteMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.green
            renderer.lineWidth = 6
            return renderer
        }
    }
}

// MARK: - Rounded Corner

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
