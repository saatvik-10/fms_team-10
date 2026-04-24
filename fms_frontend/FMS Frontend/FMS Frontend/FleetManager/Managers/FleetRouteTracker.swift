import Foundation
import CoreLocation
import GoogleMaps
import Combine

class FleetRouteTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = FleetRouteTracker()
    
    private let locationManager = CLLocationManager()
    private var trackedTrips: [String: VehicleTrip] = [:] // tripID.uuidString : Trip
    
    // Deviation threshold in meters
    var deviationThreshold: Double = 500.0
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50.0 // Only check every 50 meters to save battery
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func startTracking(trip: VehicleTrip) {
        guard trip.encodedPolyline != nil else { return }
        trackedTrips[trip.id.uuidString] = trip
        locationManager.startUpdatingLocation()
        print("Started route tracking for trip: \(trip.id.uuidString)")
    }
    
    func stopTracking(tripID: String) {
        trackedTrips.removeValue(forKey: tripID)
        if trackedTrips.isEmpty {
            locationManager.stopUpdatingLocation()
            print("Stopped all route tracking")
        }
    }
    
    func stopAllTracking() {
        trackedTrips.removeAll()
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        for (tripID, trip) in trackedTrips {
            guard let encodedPath = trip.encodedPolyline,
                  let path = GMSPath(fromEncodedPath: encodedPath) else { continue }
            
            // Check if current location is within tolerance of the path
            let isOnPath = GMSGeometryIsLocationOnPathTolerance(
                location.coordinate,
                path,
                true, // geodesic
                deviationThreshold
            )
            
            if !isOnPath {
                print("⚠️ ROUTE DEVIATION DETECTED for Trip \(tripID)")
                NotificationCenter.default.post(
                    name: .routeDeviationDetected,
                    object: nil,
                    userInfo: [
                        "tripID": tripID,
                        "location": location,
                        "distance": deviationThreshold // Approximate
                    ]
                )
            }
        }
    }
}
