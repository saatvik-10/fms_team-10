//
//  TripsViewModel.swift
//  Created by Tanishka Kumar
//

import Foundation
import Combine

class TripsViewModel: ObservableObject {
    @Published var selectedSegment: TripSegment = .accepted
    @Published var trips: [LifecycleTrip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let tripAPI: TripAPI
    
    init(tripAPI: TripAPI = .shared) {
        self.tripAPI = tripAPI
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

            // Deduplicate by trip ID  backend may return duplicates
            // when multiple trip records share the same vehicle
            var seen = Set<String>()
            let uniqueTrips = mappedTrips.filter { seen.insert($0.id).inserted }

            if uniqueTrips.isEmpty {
                trips = []
            } else {
                trips = uniqueTrips
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

        let departure = trip.tripDate ?? trip.departureTime
        let status = TripStatusHelper.resolve(backendStatus: trip.status, departureRaw: departure)
        let loadInfo = trip.loadAmount ?? buildLoadInfo(amount: trip.amount, unit: trip.unit)

        return LifecycleTrip(
            id: id,
            source: source,
            destination: destination,
            status: status,
            dateValue: TripStatusHelper.formatDateValue(from: departure),
            timeLabel: status == .completed ? "Completion Time" : "Scheduled Start",
            timeValue: TripStatusHelper.formatTimeValue(from: departure),
            loadInfo: loadInfo,
            distance: parseDistanceKm(trip.distanceKm ?? trip.tripDistance),
            vehicleNumber: trip.vehicleRegistrationNumber,
            cargoWeight: formatCargoWeight(amount: trip.amount, unit: trip.unit),
            sourceCoordinate: nil,
            destinationCoordinate: nil,
            rawDeparture: departure
        )
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
    
    private func loadMockData() {
        trips = [
            // Accepted Trips
            LifecycleTrip(id: "TRP-10488", source: "Mumbai, MH", destination: "Gurgaon, HR", status: .scheduled, dateValue: "Oct 20", timeLabel: "Scheduled Start", timeValue: "14:30", loadInfo: "12 Pallets", distance: 1412.0, vehicleNumber: "MH01BK9392"),
            
            // Past Trips
            LifecycleTrip(id: "TRP-10470", source: "Chennai, TN", destination: "Kochi, KL", status: .completed, dateValue: "Oct 15", timeLabel: "Completion Time", timeValue: "Yesterday, 18:45", loadInfo: "20 Pallets", distance: 684.1, vehicleNumber: "XYZ-9876")
        ]
    }
    
    func acceptTrip(_ trip: LifecycleTrip) {
        print("[DEBUG] [DEBUG] Accept Trip tapped for \(trip.id)")
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
        print("[DEBUG] [DEBUG] Decline Trip tapped for \(trip.id)")
        trips.removeAll { $0.id == trip.id }
    }
    
    func startTrip(_ trip: LifecycleTrip) {
        print("[DEBUG] [DEBUG] Start Trip tapped for \(trip.id)")
    }
    
    func endTrip(_ tripId: String) {
        print("[DEBUG] [DEBUG] End Trip called for \(tripId)")

        // Immediately update UI
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            let existing = trips[index]
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

        // Call backend to persist the completion
        Task {
            do {
                let response = try await tripAPI.completeTripForDriver(tripId: tripId)
                print("[SUCCESS] [SUCCESS]  Trip completed on backend: \(response.message)")
            } catch {
                print("[ERROR] [ERROR]  Failed to complete trip on backend: \(error.localizedDescription)")
            }
        }
    }
    
    func viewSummary(_ trip: LifecycleTrip) {
        print("[DEBUG] [DEBUG] View Summary tapped for \(trip.id)")
    }
}
