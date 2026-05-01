//
//  FleetGeofenceManager.swift
//  Created by Tanishka Kumar
//

import Foundation
import CoreLocation
import Combine

extension Notification.Name {
    static let geofenceEntered = Notification.Name("GeofenceEntered")
    static let geofenceExited = Notification.Name("GeofenceExited")
    static let routeDeviationDetected = Notification.Name("routeDeviationDetected")
}

class FleetGeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = FleetGeofenceManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // meters
        
        // Note: allowsBackgroundLocationUpdates requires 'Location updates' to be enabled in 
        // the Xcode project's Background Modes capability. 
        // Region monitoring (geofencing) actually works in the background without this flag.
        // locationManager.allowsBackgroundLocationUpdates = true
        
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestPermissions() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startMonitoring(trip: VehicleTrip) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            print("[DEBUG] [DEBUG] Geofencing is not supported on this device!")
            return
        }
        
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            print("[DEBUG] [DEBUG] Location permission not granted for geofencing.")
            requestPermissions()
            return
        }
        
        let radius = trip.geofenceRadius ?? 1000.0
        
        if let origin = trip.originCoordinate {
            let originRegion = CLCircularRegion(center: origin, radius: radius, identifier: "trip_\(trip.id)_origin")
            originRegion.notifyOnEntry = true
            originRegion.notifyOnExit = true
            locationManager.startMonitoring(for: originRegion)
            print("[DEBUG] [DEBUG] Started monitoring origin region for trip \(trip.id)")
        }
        
        if let dest = trip.destCoordinate {
            let destRegion = CLCircularRegion(center: dest, radius: radius, identifier: "trip_\(trip.id)_destination")
            destRegion.notifyOnEntry = true
            destRegion.notifyOnExit = true
            locationManager.startMonitoring(for: destRegion)
            print("[DEBUG] [DEBUG] Started monitoring destination region for trip \(trip.id)")
        }
    }
    
    func stopMonitoringAll() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            print("[DEBUG] [DEBUG]  GEOFENCE EVENT: Entered region \(circularRegion.identifier)")
            
            // In a real app, we would update the trip status in FleetDataManager
            // e.g., if identifier contains "destination", status = .completed
            
            // Post a notification for the UI to handle if needed
            NotificationCenter.default.post(name: .geofenceEntered, object: nil, userInfo: ["region": circularRegion.identifier])
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let circularRegion = region as? CLCircularRegion {
            print("[DEBUG] [DEBUG]  GEOFENCE EVENT: Exited region \(circularRegion.identifier)")
            
            // e.g., if identifier contains "origin", status = .inTransit
            
            NotificationCenter.default.post(name: .geofenceExited, object: nil, userInfo: ["region": circularRegion.identifier])
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[ERROR] [ERROR] Location Manager failed: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("[ERROR] Monitoring failed for region \(region?.identifier ?? "unknown"): \(error)")
    }
}
