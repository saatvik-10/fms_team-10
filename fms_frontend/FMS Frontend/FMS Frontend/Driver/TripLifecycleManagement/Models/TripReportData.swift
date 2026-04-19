import Foundation

// MARK: - Trip Report Data Model
// Holds all structured fields for the professional PDF trip report.

struct TripReportData {

    // MARK: 1 – Trip Information
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

    // MARK: 2 – Distance & Fuel Metrics
    var totalDistanceKm: Double
    var fuelConsumedLiters: Double
    var fuelEfficiencyKmL: Double
    var fuelCostINR: Double

    // MARK: 3 – Performance Metrics
    var averageSpeedKmH: Double
    var maxSpeedKmH: Double
    var drivingTimeHours: Double
    var idleTimeHours: Double
    var restingHours: Double?          // optional
    var stopsCount: Int

    // MARK: 4 – Cost Breakdown
    var tollCostINR: Double
    var driverCostINR: Double
    var totalCostINR: Double           // highlighted in PDF

    // MARK: - Factory from LifecycleTrip
    static func mock(from trip: LifecycleTrip) -> TripReportData {
        // Deterministic pseudo-values derived from trip distance so each trip
        // gets its own consistent numbers without a real backend.
        let dist       = trip.distance            // miles → treat as km for demo
        let fuel       = dist / 12.4              // ~12.4 km/l efficiency
        let efficiency = dist / max(fuel, 0.001)
        let fuelCost   = fuel * 91.0              // ₹91/l
        let drivingHrs = dist / 65.0              // avg 65 km/h
        let idleHrs    = drivingHrs * 0.12
        let toll       = dist * 2.3
        let driverCost = drivingHrs * 350.0       // ₹350/hr
        let total      = fuelCost + toll + driverCost

        // Build a Google Maps URL for the route
        let srcEncoded = trip.source.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let dstEncoded = trip.destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mapURL = "https://www.google.com/maps/dir/\(srcEncoded)/\(dstEncoded)"

        return TripReportData(
            tripID:               trip.id,
            vehicleID:            "VH-\(trip.id.suffix(4))",
            vehicleNumber:        "MH-12-AB-\(trip.id.suffix(4))",
            driverName:           "Rajesh Kumar",
            driverID:             "DRV-4821",
            startDateTime:        "\(trip.dateValue)  \(trip.timeValue.components(separatedBy: " - ").first ?? "08:00")",
            endDateTime:          "\(trip.dateValue)  \(trip.timeValue.components(separatedBy: " - ").last ?? "18:00")",
            tripDuration:         String(format: "%.1f hrs", drivingHrs + idleHrs),
            startLocation:        trip.source,
            endLocation:          trip.destination,
            routeMapURL:          mapURL,
            totalDistanceKm:      dist,
            fuelConsumedLiters:   fuel,
            fuelEfficiencyKmL:    efficiency,
            fuelCostINR:          fuelCost,
            averageSpeedKmH:      65.0,
            maxSpeedKmH:          88.0,
            drivingTimeHours:     drivingHrs,
            idleTimeHours:        idleHrs,
            restingHours:         1.5,
            stopsCount:           Int(dist / 80) + 2,
            tollCostINR:          toll,
            driverCostINR:        driverCost,
            totalCostINR:         total
        )
    }
}
