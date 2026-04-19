import SwiftUI
import GoogleMaps

struct CustomGoogleMapViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: NavigationViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> GMSMapView {
        // Use trip pickup as initial camera position so map is never blank on load
        let initialCoord = viewModel.currentLocation
            ?? viewModel.trip.pickup.coordinate

        let camera = GMSCameraPosition.camera(
            withTarget: initialCoord,
            zoom: 15
        )
        let options = GMSMapViewOptions()
        options.camera = camera
        let mapView = GMSMapView(options: options)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = false
        mapView.settings.compassButton = true
        mapView.mapType = .normal
        mapView.settings.tiltGestures = true
        mapView.settings.rotateGestures = true
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {

        // 1. Polyline — redraw only on change
        if viewModel.polylineString != context.coordinator.lastPolylineString {
            context.coordinator.lastPolylineString = viewModel.polylineString
            context.coordinator.currentPolyline?.map = nil
            context.coordinator.currentPolyline = nil

            if !viewModel.polylineString.isEmpty,
               let path = GMSPath(fromEncodedPath: viewModel.polylineString) {
                let polyline = GMSPolyline(path: path)
                polyline.strokeColor = UIColor(red: 15/255, green: 28/255, blue: 36/255, alpha: 1)
                polyline.strokeWidth = 8.0
                
                polyline.map = uiView
                context.coordinator.currentPolyline = polyline
            }
        }

        // 2. Next-stop marker — redraw only when destination changes
        let newDestKey = viewModel.nextStopCoordinate
            .map { "\($0.latitude),\($0.longitude)" } ?? ""
        if newDestKey != context.coordinator.lastDestinationKey {
            context.coordinator.lastDestinationKey = newDestKey
            context.coordinator.destinationMarker?.map = nil
            context.coordinator.destinationMarker = nil

            if let dest = viewModel.nextStopCoordinate {
                let marker = GMSMarker(position: dest)
                marker.title = "Next Stop"
                marker.icon = GMSMarker.markerImage(
                    with: UIColor(red: 15/255, green: 28/255, blue: 36/255, alpha: 1)
                )
                marker.map = uiView
                context.coordinator.destinationMarker = marker
            }
        }

        // 3. Camera follows user — unconditional, with bearing
        if let location = viewModel.currentLocation {
            let camera = GMSCameraPosition(
                target: location,
                zoom: 20,              // closer like Google Maps
                bearing: viewModel.userHeading,
                viewingAngle: 50       // 🔥 THIS gives navigation tilt
            )
            CATransaction.begin()
            CATransaction.setAnimationDuration(1.0)
            uiView.animate(to: camera)
            CATransaction.commit()
        }
    }

    class Coordinator: NSObject {
        var parent: CustomGoogleMapViewRepresentable
        var lastPolylineString: String = ""
        var currentPolyline: GMSPolyline?
        var destinationMarker: GMSMarker?
        var lastDestinationKey: String = ""

        init(_ parent: CustomGoogleMapViewRepresentable) {
            self.parent = parent
        }
    }
}
