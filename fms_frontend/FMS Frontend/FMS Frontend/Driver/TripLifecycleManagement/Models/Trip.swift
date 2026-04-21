import Foundation
import CoreLocation

// MARK: - Enums

enum TripStatus: String, CaseIterable {
    case assigned = "NEW TASK"
    case scheduled = "SCHEDULED"
    case completed = "COMPLETED"
}

enum TripSegment: String, CaseIterable {
    case assigned = "Assigned"
    case accepted = "Accepted"
    case past = "Past"
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
    
    var segment: TripSegment {
        switch status {
        case .assigned: return .assigned
        case .scheduled: return .accepted
        case .completed: return .past
        }
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
                coordinate: CLLocationCoordinate2D(latitude: 18.9499, longitude: 72.9525),
                time: "08:00 AM",
                status: .upcoming
            ),
            destination: TripStop(
                name: self.destination,
                coordinate: CLLocationCoordinate2D(latitude: 28.4815, longitude: 77.0736),
                time: "10:00 PM",
                status: .upcoming
            ),
//            stops: [
//                TripStop(
//                    name: "Transit Checkpoint",
//                    coordinate: CLLocationCoordinate2D(latitude: 22.3072, longitude: 73.1812),
//                    time: "02:30 PM",
//                    status: .upcoming
//                )
//            ],
            cargoWeight: "18.4t",
            cargoUnits: self.loadInfo
        )
    }
}
