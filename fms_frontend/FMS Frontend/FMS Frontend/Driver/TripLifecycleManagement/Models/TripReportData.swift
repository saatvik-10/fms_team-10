//
//  TripReportData.swift
//  Created by Kunal Khude
//

import Foundation

// MARK: - Trip Report Data Model
// Holds all structured fields for the professional PDF trip report.

struct TripReportData {

    // MARK: 1  Trip Information
    var tripID: String
    var vehicleID: String
    var vehicleNumber: String
    var driverName: String
    var driverID: String
    var startDateTime: String
    var endDateTime: String
    var tripDuration: String
    var startLocation: String
    var endLocation: String
    var routeMapURL: String?           // optional Google Maps deep-link

    // MARK: 2  Distance & Fuel Metrics
    var totalDistanceKm: Double
    var fuelConsumedLiters: Double
    var fuelEfficiencyKmL: Double
    var fuelCostINR: Double

    // MARK: 3  Performance Metrics
    var averageSpeedKmH: Double
    var maxSpeedKmH: Double
    var drivingTimeHours: Double
    var idleTimeHours: Double
    var restingHours: Double?          // optional
    var stopsCount: Int

    // MARK: 4  Cost Breakdown
    var tollCostINR: Double
    var driverCostINR: Double
    var totalCostINR: Double           // highlighted in PDF

    // MARK: - Factory from LifecycleTrip (uses real trip data)
    static func mock(from trip: LifecycleTrip, driverName: String? = nil) -> TripReportData {
        // Use actual trip distance from the backend
        let dist = trip.distance

        // Derive metrics from actual distance
        let avgSpeed     = dist > 0 ? 55.0 : 0.0                // conservative avg for trucks
        let drivingHrs   = dist > 0 ? dist / avgSpeed : 0.0
        let idleHrs      = drivingHrs * 0.10                     // ~10% idle
        let totalDuration = drivingHrs + idleHrs

        // Fuel estimates based on distance
        let fuelEfficiency = 12.4                                 // km/l typical for fleet
        let fuel           = dist / max(fuelEfficiency, 0.001)
        let fuelCost       = fuel * 91.0                          // 91/l

        // Cost estimates
        let toll       = dist * 2.3
        let driverCost = drivingHrs * 350.0                       // 350/hr
        let total      = fuelCost + toll + driverCost

        // Build a Google Maps URL for the route (using real source/destination)
        let srcEncoded = trip.source.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let dstEncoded = trip.destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mapURL = "https://www.google.com/maps/dir/\(srcEncoded)/\(dstEncoded)"

        // Use actual vehicle number from trip
        let vehicleNum = trip.vehicleNumber ?? "N/A"

        // Use actual trip date/time values
        let startDT = "\(trip.dateValue)  \(trip.timeValue)"
        
        // For end time: if completed, show completion time; otherwise estimate
        let endDT: String
        if trip.status == .completed {
            endDT = "\(trip.dateValue)  \(trip.timeValue)"
        } else {
            let durationFormatted = String(format: "%.1f hrs", totalDuration)
            endDT = "Est. \(durationFormatted) after start"
        }

        return TripReportData(
            tripID:               trip.id,
            vehicleID:            "VH-\(trip.id.suffix(4))",
            vehicleNumber:        vehicleNum,
            driverName:           driverName ?? "Driver",
            driverID:             trip.id,
            startDateTime:        startDT,
            endDateTime:          endDT,
            tripDuration:         String(format: "%.1f hrs", totalDuration),
            startLocation:        trip.source,
            endLocation:          trip.destination,
            routeMapURL:          mapURL,
            totalDistanceKm:      dist,
            fuelConsumedLiters:   fuel,
            fuelEfficiencyKmL:    fuelEfficiency,
            fuelCostINR:          fuelCost,
            averageSpeedKmH:      avgSpeed,
            maxSpeedKmH:          avgSpeed * 1.4,   // estimated peak
            drivingTimeHours:     drivingHrs,
            idleTimeHours:        idleHrs,
            restingHours:         nil,              // no mock resting hours
            stopsCount:           max(1, Int(dist / 120)),  // ~1 stop per 120 km
            tollCostINR:          toll,
            driverCostINR:        driverCost,
            totalCostINR:         total
        )
    }
}
