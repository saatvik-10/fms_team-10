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
            LifecycleTrip(id: "TRP-10492", source: "Chicago, IL", destination: "Detroit, MI", status: .assigned, dateValue: "Oct 18", timeLabel: "Arrival Window", timeValue: "08:00 - 10:00", loadInfo: "24 Pallets", distance: 283.4),
            LifecycleTrip(id: "TRP-10495", source: "Gary, IN", destination: "Columbus, OH", status: .assigned, dateValue: "Oct 19", timeLabel: "Arrival Window", timeValue: "13:30 - 15:00", loadInfo: "18 Pallets", distance: 250.0),
            
            // Accepted Trips
            LifecycleTrip(id: "TRP-10488", source: "Indianapolis, IN", destination: "Louisville, KY", status: .scheduled, dateValue: "Oct 20", timeLabel: "Scheduled Start", timeValue: "14:30", loadInfo: "12 Pallets", distance: 114.2),
            
            // Past Trips
            LifecycleTrip(id: "TRP-10470", source: "Nashville, TN", destination: "Atlanta, GA", status: .completed, dateValue: "Oct 15", timeLabel: "Completion Time", timeValue: "Yesterday, 18:45", loadInfo: "20 Pallets", distance: 248.1)
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
                distance: existing.distance
            )
        }
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
