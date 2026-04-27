import Foundation
import Combine

class TripsViewModel: ObservableObject {
    @Published var selectedSegment: TripSegment = .assigned
    @Published var trips: [LifecycleTrip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tripAPI: TripAPI
    
    init(tripAPI: TripAPI = .shared) {
        self.tripAPI = tripAPI
        Task {
            await loadDriverTrips()
        }
    }
    
    var filteredTrips: [LifecycleTrip] {
        trips.filter { $0.segment == selectedSegment }
    }

    @MainActor
    func loadDriverTrips() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await tripAPI.getDriverTrips()
            let mappedTrips = response.trips.compactMap(Self.mapTripItemToLifecycleTrip)

            if mappedTrips.isEmpty {
                trips = []
            } else {
                trips = mappedTrips
            }
        } catch {
            errorMessage = error.localizedDescription
            loadMockData()
        }

        isLoading = false
    }

    private static func mapTripItemToLifecycleTrip(_ trip: TripItem) -> LifecycleTrip? {
        guard let id = trip.id,
              let source = trip.sourceLocation,
              let destination = trip.destinationLocation else {
            return nil
        }

        let status = mapTripStatus(trip.status)
        let loadInfo = trip.loadAmount ?? buildLoadInfo(amount: trip.amount, unit: trip.unit)
        let departure = trip.tripDate ?? trip.departureTime

        return LifecycleTrip(
            id: id,
            source: source,
            destination: destination,
            status: status,
            dateValue: formatDateValue(from: departure),
            timeLabel: status == .completed ? "Completion Time" : "Scheduled Start",
            timeValue: formatTimeValue(from: departure),
            loadInfo: loadInfo,
            distance: parseDistanceKm(trip.tripDistance),
            vehicleNumber: trip.vehicleRegistrationNumber,
            cargoWeight: formatCargoWeight(amount: trip.amount, unit: trip.unit),
            sourceCoordinate: nil,
            destinationCoordinate: nil
        )
    }

    private static func mapTripStatus(_ rawStatus: String?) -> TripStatus {
        switch rawStatus?.uppercased() {
        case "COMPLETED":
            return .completed
        case "PENDING", "CANCELLED":
            return .assigned
        default:
            return .scheduled
        }
    }

    private static func buildLoadInfo(amount: Int?, unit: String?) -> String {
        if let amount, let unit {
            return "\(amount) \(unit)"
        }
        return "N/A"
    }

    private static func formatCargoWeight(amount: Int?, unit: String?) -> String {
        guard let amount, let unit else { return "N/A" }
        let shortUnit = unit.lowercased().contains("kg") ? "kg" : unit
        return "\(amount) \(shortUnit)"
    }

    private static func parseDistanceKm(_ value: String?) -> Double {
        guard let value, !value.isEmpty else { return 0.0 }
        let filtered = value.filter { "0123456789.".contains($0) }
        return Double(filtered) ?? 0.0
    }

    private static func formatDateValue(from raw: String?) -> String {
        guard let raw, let date = parseDate(raw) else { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private static func formatTimeValue(from raw: String?) -> String {
        guard let raw, let date = parseDate(raw) else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func parseDate(_ raw: String) -> Date? {
        let isoWithFractional = ISO8601DateFormatter()
        isoWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFractional.date(from: raw) {
            return date
        }

        let isoBasic = ISO8601DateFormatter()
        isoBasic.formatOptions = [.withInternetDateTime]
        if let date = isoBasic.date(from: raw) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: raw)
    }
    
    private func loadMockData() {
        trips = [
            // Assigned Trips
            LifecycleTrip(id: "TRP-10492", source: "Mumbai, MH", destination: "Pune, MH", status: .assigned, dateValue: "Oct 18", timeLabel: "Arrival Window", timeValue: "08:00 - 10:00", loadInfo: "24 Pallets", distance: 148.4, vehicleNumber: nil),
            LifecycleTrip(id: "TRP-10495", source: "Delhi, DL", destination: "Jaipur, RJ", status: .assigned, dateValue: "Oct 19", timeLabel: "Arrival Window", timeValue: "13:30 - 15:00", loadInfo: "18 Pallets", distance: 281.0, vehicleNumber: nil),
            
            // Accepted Trips
            LifecycleTrip(id: "TRP-10488", source: "Mumbai, MH", destination: "Gurgaon, HR", status: .scheduled, dateValue: "Oct 20", timeLabel: "Scheduled Start", timeValue: "14:30", loadInfo: "12 Pallets", distance: 1412.0, vehicleNumber: "MH01BK9392"),
            
            // Past Trips
            LifecycleTrip(id: "TRP-10470", source: "Chennai, TN", destination: "Kochi, KL", status: .completed, dateValue: "Oct 15", timeLabel: "Completion Time", timeValue: "Yesterday, 18:45", loadInfo: "20 Pallets", distance: 684.1, vehicleNumber: "XYZ-9876")
        ]
    }
    
    func acceptTrip(_ trip: LifecycleTrip) {
        print("Accept Trip tapped for \(trip.id)")
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            let existing = trips[index]
            trips[index] = LifecycleTrip(
                id: existing.id,
                source: existing.source,
                destination: existing.destination,
                status: .scheduled,
                dateValue: existing.dateValue,
                timeLabel: "Scheduled Start",
                timeValue: "Pending",
                loadInfo: existing.loadInfo,
                distance: existing.distance,
                vehicleNumber: generateRandomVehicleNumber()
            )
        }
    }
    
    private func generateRandomVehicleNumber() -> String {
        let prefixes = ["MH01", "DL01", "KA01", "GA01"]
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let randomPrefix = prefixes.randomElement() ?? "MH01"
        let randomLetter1 = letters.randomElement() ?? "A"
        let randomLetter2 = letters.randomElement() ?? "B"
        let randomNumber = Int.random(in: 1000...9999)
        return "\(randomPrefix)\(randomLetter1)\(randomLetter2)\(randomNumber)"
    }
    
    func declineTrip(_ trip: LifecycleTrip) {
        print("Decline Trip tapped for \(trip.id)")
        trips.removeAll { $0.id == trip.id }
    }
    
    func startTrip(_ trip: LifecycleTrip) {
        print("Start Trip tapped for \(trip.id)")
    }
    
    func endTrip(_ tripId: String) {
        print("End Trip called for \(tripId)")
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            let existing = trips[index]
            
            // Format current time for completion time
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let dateString = formatter.string(from: Date())
            
            formatter.dateFormat = "'Today', HH:mm"
            let timeString = formatter.string(from: Date())
            
            trips[index] = LifecycleTrip(
                id: existing.id,
                source: existing.source,
                destination: existing.destination,
                status: .completed,
                dateValue: dateString,
                timeLabel: "Completion Time",
                timeValue: timeString,
                loadInfo: existing.loadInfo,
                distance: existing.distance,
                vehicleNumber: existing.vehicleNumber
            )
        }
    }
    
    func viewSummary(_ trip: LifecycleTrip) {
        print("View Summary tapped for \(trip.id)")
    }
}
