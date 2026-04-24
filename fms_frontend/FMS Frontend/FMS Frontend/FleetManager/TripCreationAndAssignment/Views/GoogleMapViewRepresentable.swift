import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Fleet Google Map View
// A self-contained UIViewRepresentable that renders a GMSMapView for the Fleet Manager trip detail.
// Features:
//  • User location blue-dot
//  • Compass enabled
//  • Start marker (green) + End marker (navy)
//  • Encoded polyline route drawn in navy
//  • Camera auto-fits to route bounds; initially focuses on user location
//  • Only redraws when polyline string changes (performance cache)

struct FleetGoogleMapView: UIViewRepresentable {

    // MARK: - Inputs
    let encodedPolyline: String         // Google encoded polyline from Directions API
    let originCoord: CLLocationCoordinate2D?
    let destCoord: CLLocationCoordinate2D?
    let originLabel: String
    let destLabel: String

    // MARK: - Coordinator
    final class Coordinator: NSObject {
        var mapView: GMSMapView?
        var lastPolyline: String = ""
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - makeUIView

    func makeUIView(context: Context) -> GMSMapView {
        // Default camera — Delhi fallback
        let camera = GMSCameraPosition.camera(
            withLatitude: 28.6139, longitude: 77.2090, zoom: 12
        )
        let options = GMSMapViewOptions()
        options.camera = camera

        let mapView = GMSMapView(options: options)
        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = false // We don't need the default button
        mapView.isUserInteractionEnabled = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true

        context.coordinator.mapView = mapView
        return mapView
    }

    // MARK: - updateUIView

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Performance guard: skip redraw if polyline hasn't changed
        guard context.coordinator.lastPolyline != encodedPolyline ||
              originCoord != nil || destCoord != nil else { return }
        context.coordinator.lastPolyline = encodedPolyline

        uiView.clear()

        let navyColor = UIColor(red: 10/255, green: 48/255, blue: 58/255, alpha: 1) // #0a303a

        // MARK: Draw polyline
        var routePath: GMSPath? = nil
        if !encodedPolyline.isEmpty, let path = GMSPath(fromEncodedPath: encodedPolyline) {
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = navyColor
            polyline.strokeWidth = 5.5
            polyline.geodesic = true
            polyline.map = uiView
            routePath = path
        }

        // MARK: Start marker (green)
        if let origin = originCoord, CLLocationCoordinate2DIsValid(origin) {
            let marker = GMSMarker(position: origin)
            marker.title = originLabel.isEmpty ? "Pickup" : originLabel
            marker.icon = GMSMarker.markerImage(with: UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1))
            marker.map = uiView
        }

        // MARK: End marker (navy)
        if let dest = destCoord, CLLocationCoordinate2DIsValid(dest) {
            let marker = GMSMarker(position: dest)
            marker.title = destLabel.isEmpty ? "Destination" : destLabel
            marker.icon = GMSMarker.markerImage(with: navyColor)
            marker.map = uiView
        }

        // MARK: Camera
        if let path = routePath {
            let bounds = GMSCoordinateBounds(path: path)
            if bounds.isValid {
                DispatchQueue.main.async {
                    uiView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50.0))
                }
                return
            }
        }

        // Fallback: zoom in on dest or origin if polyline unavailable
        if let dest = destCoord, CLLocationCoordinate2DIsValid(dest) {
            uiView.animate(to: GMSCameraPosition.camera(withTarget: dest, zoom: 13))
        } else if let origin = originCoord, CLLocationCoordinate2DIsValid(origin) {
            uiView.animate(to: GMSCameraPosition.camera(withTarget: origin, zoom: 13))
        }
    }
}
