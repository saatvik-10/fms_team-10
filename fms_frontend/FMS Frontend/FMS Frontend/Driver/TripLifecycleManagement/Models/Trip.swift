import Foundation
import CoreLocation

// MARK: - Enums

enum TripStatus: String, CaseIterable {
    case scheduled = "SCHEDULED"
    case ongoing   = "IN_TRANSIT"   // matches backend TripStatus.IN_TRANSIT
    case completed = "COMPLETED"
}

enum TripSegment: String, CaseIterable {
    case accepted = "Upcoming"
    case past     = "Completed"
}

// MARK: - Centralized Status Helper

struct TripStatusHelper {

    // MARK: Date Parsing

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

    // MARK: Status Resolution

    /// Resolves the trip status from backend data.
    ///
    /// Priority order:
    /// 1. Backend says COMPLETED → `.completed`
    /// 2. Backend says IN_TRANSIT → `.ongoing`
    /// 3. Departure time has passed → `.ongoing`
    /// 4. Departure time is in the future → `.scheduled`
    /// 5. Fallback → `.scheduled`
    static func resolve(backendStatus: String?, departureRaw: String?) -> TripStatus {
        switch backendStatus?.uppercased() {
        case "COMPLETED":
            return .completed
        case "IN_TRANSIT":
            return .ongoing
        default:
            break
        }

        // Time-based fallback: if departure has passed, treat as ongoing
        if let raw = departureRaw, let departureDate = parseDate(raw) {
            return departureDate > Date() ? .scheduled : .ongoing
        }

        return .scheduled
    }

    /// Returns true if the departure time has passed (i.e. trip can be started).
    static func isDepartureReached(departureRaw: String?) -> Bool {
        guard let raw = departureRaw, let date = parseDate(raw) else { return false }
        return Date() >= date
    }

    // MARK: Display Formatters

    /// e.g. "Apr 29, 14:30"
    static func formatScheduledDateTime(from raw: String?) -> String {
        guard let raw, let date = parseDate(raw) else { return "TBD" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, HH:mm"
        return fmt.string(from: date)
    }

    /// e.g. "Apr 29"
    static func formatDateValue(from raw: String?) -> String {
        guard let raw, let date = parseDate(raw) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }

    /// e.g. "14:30"
    static func formatTimeValue(from raw: String?) -> String {
        guard let raw, let date = parseDate(raw) else { return "TBD" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
}

// MARK: - LifecycleTrip Model

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

    /// Raw ISO-8601 departure string from backend — used for time-based gating.
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

    // MARK: Computed

    var segment: TripSegment {
        switch status {
        case .scheduled, .ongoing: return .accepted
        case .completed:           return .past
        }
    }

    /// True when departure time has been reached and trip hasn't started yet.
    var isDepartureReached: Bool {
        TripStatusHelper.isDepartureReached(departureRaw: rawDeparture)
    }

    /// Human-readable scheduled date/time, e.g. "Apr 29, 14:30".
    var scheduledDateTimeText: String {
        TripStatusHelper.formatScheduledDateTime(from: rawDeparture)
    }
}

// MARK: - Conversion to Dashboard Trip Model

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
