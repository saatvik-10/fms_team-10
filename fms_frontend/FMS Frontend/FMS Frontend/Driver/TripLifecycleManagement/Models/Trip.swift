import Foundation
import CoreLocation

// MARK: - Enums

enum TripStatus: String, CaseIterable {
    case scheduled = "SCHEDULED"
<<<<<<< HEAD
    case ongoing   = "IN TRANSIT"
=======
    case inTransit = "IN TRANSIT"
>>>>>>> 2ef748cbb5af745efc1818e835726b23f6d63e50
    case completed = "COMPLETED"
}

enum TripSegment: String, CaseIterable {
    case accepted = "Upcoming"
    case past = "Completed"
}

// MARK: - Centralized Status Helper

/// Derives a trip's dynamic status from its backend status string and departure time.
/// - If the backend already says "COMPLETED" → `.completed`
/// - Otherwise, compares departure time against `Date()`:
///   • Future → `.scheduled`
///   • Past or now → `.ongoing`
struct TripStatusHelper {

    /// Shared date-parsing pipeline (ISO-8601 variants + custom fallback).
    static func parseDate(_ raw: String) -> Date? {
        let isoFrac = ISO8601DateFormatter()
        isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoFrac.date(from: raw) { return d }

        let isoBasic = ISO8601DateFormatter()
        isoBasic.formatOptions = [.withInternetDateTime]
        if let d = isoBasic.date(from: raw) { return d }

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return fmt.date(from: raw)
    }

    /// Resolve a TripStatus from backend raw values.
    static func resolve(backendStatus: String?, departureRaw: String?) -> TripStatus {
        // Explicit completion from backend
        if backendStatus?.uppercased() == "COMPLETED" {
            return .completed
        }

        // Time-based: if we can parse the departure time, compare with now
        if let raw = departureRaw, let departureDate = parseDate(raw) {
            return departureDate > Date() ? .scheduled : .ongoing
        }

        // Fallback: treat as scheduled
        return .scheduled
    }

    /// Format a departure date for display (e.g. "Apr 29, 14:30").
    static func formatScheduledDateTime(from raw: String?) -> String {
        guard let raw, let date = parseDate(raw) else { return "TBD" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, HH:mm"
        return fmt.string(from: date)
    }

    /// Format just the date portion (e.g. "Apr 29").
    static func formatDateValue(from raw: String?) -> String {
        guard let raw, let date = parseDate(raw) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }

    /// Format just the time portion (e.g. "14:30").
    static func formatTimeValue(from raw: String?) -> String {
        guard let raw, let date = parseDate(raw) else { return "TBD" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
}

// MARK: - Model

struct LifecycleTrip: Identifiable {
    let id: String
    let source: String
    let destination: String
    let status: TripStatus
    let dateValue: String
    let timeLabel: String
    let timeValue: String
    let loadInfo: String
    let distance: Double
    let vehicleNumber: String?
    let cargoWeight: String
    let sourceCoordinate: CLLocationCoordinate2D?
    let destinationCoordinate: CLLocationCoordinate2D?

    /// Raw departure string from backend — used for time-based status checks.
    let rawDeparture: String?

    init(
        id: String,
        source: String,
        destination: String,
        status: TripStatus,
        dateValue: String,
        timeLabel: String,
        timeValue: String,
        loadInfo: String,
        distance: Double,
        vehicleNumber: String?,
        cargoWeight: String = "N/A",
        sourceCoordinate: CLLocationCoordinate2D? = nil,
        destinationCoordinate: CLLocationCoordinate2D? = nil,
        rawDeparture: String? = nil
    ) {
        self.id = id
        self.source = source
        self.destination = destination
        self.status = status
        self.dateValue = dateValue
        self.timeLabel = timeLabel
        self.timeValue = timeValue
        self.loadInfo = loadInfo
        self.distance = distance
        self.vehicleNumber = vehicleNumber
        self.cargoWeight = cargoWeight
        self.sourceCoordinate = sourceCoordinate
        self.destinationCoordinate = destinationCoordinate
        self.rawDeparture = rawDeparture
    }
    
    var segment: TripSegment {
        switch status {
<<<<<<< HEAD
        case .scheduled, .ongoing: return .accepted
        case .completed:           return .past
=======
        case .scheduled: return .accepted
        case .inTransit: return .accepted
        case .completed: return .past
>>>>>>> 2ef748cbb5af745efc1818e835726b23f6d63e50
        }
    }

    /// Formatted "date & time" string for UI messages like "Trip available on Apr 29, 14:30".
    var scheduledDateTimeText: String {
        TripStatusHelper.formatScheduledDateTime(from: rawDeparture)
    }
}

// MARK: - Conversion to Dashboard Trip model

extension LifecycleTrip {
    func toTripModel() -> Trip {
        Trip(
            routeNumber: self.id,
            tripDate: self.dateValue,
            pickup: TripStop(
                name: self.source,
                coordinate: self.sourceCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                time: "08:00 AM",
                status: .active
            ),
            destination: TripStop(
                name: self.destination,
                coordinate: self.destinationCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
                time: "10:00 PM",
                status: .upcoming
            ),
            cargoWeight: self.cargoWeight,
            cargoUnits: self.loadInfo
        )
    }
}
