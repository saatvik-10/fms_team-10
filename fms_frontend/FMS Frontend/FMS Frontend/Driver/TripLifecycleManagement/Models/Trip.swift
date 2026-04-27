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
    let cargoWeight: String
    let sourceCoordinate: CLLocationCoordinate2D?
    let destinationCoordinate: CLLocationCoordinate2D?

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
        destinationCoordinate: CLLocationCoordinate2D? = nil
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
    }
    
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
//            stops: [
//                TripStop(
//                    name: "Transit Checkpoint",
//                    coordinate: CLLocationCoordinate2D(latitude: 22.3072, longitude: 73.1812),
//                    time: "02:30 PM",
//                    status: .upcoming
//                )
//            ],
            cargoWeight: self.cargoWeight,
            cargoUnits: self.loadInfo
        )
    }
}
