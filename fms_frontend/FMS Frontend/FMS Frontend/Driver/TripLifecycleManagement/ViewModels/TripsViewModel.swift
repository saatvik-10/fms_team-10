import Foundation
import Combine

class TripsViewModel: ObservableObject {
    @Published var selectedSegment: TripSegment = .assigned
    @Published var trips: [LifecycleTrip] = []
    
    init() {
        loadMockData()
    }
    
    var filteredTrips: [LifecycleTrip] {
        trips.filter { $0.segment == selectedSegment }
    }
    
    private func loadMockData() {
        trips = [
            // Assigned Trips
            LifecycleTrip(id: "TRP-10492", source: "Mumbai, MH", destination: "Pune, MH", status: .assigned, dateValue: "Oct 18", timeLabel: "Arrival Window", timeValue: "08:00 - 10:00", loadInfo: "24 Pallets", distance: 148.4, vehicleNumber: nil),
            LifecycleTrip(id: "TRP-10495", source: "Delhi, DL", destination: "Jaipur, RJ", status: .assigned, dateValue: "Oct 19", timeLabel: "Arrival Window", timeValue: "13:30 - 15:00", loadInfo: "18 Pallets", distance: 281.0, vehicleNumber: nil),
            
            // Accepted Trips
            LifecycleTrip(id: "TRP-10488", source: "Bengaluru, KA", destination: "Mysuru, KA", status: .scheduled, dateValue: "Oct 20", timeLabel: "Scheduled Start", timeValue: "14:30", loadInfo: "12 Pallets", distance: 143.2, vehicleNumber: "MH01BK9392"),
            
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
    
    func viewSummary(_ trip: LifecycleTrip) {
        print("View Summary tapped for \(trip.id)")
    }
}
