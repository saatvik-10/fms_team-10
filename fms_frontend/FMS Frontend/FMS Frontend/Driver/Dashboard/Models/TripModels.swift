import Foundation
import CoreLocation

enum StopStatus: String {
    case completed
    case active
    case upcoming
}

struct TripStop: Identifiable {
    let id = UUID()
    var name: String
    var coordinate: CLLocationCoordinate2D
    var time: String
    var status: StopStatus
}

struct Trip {
    var routeNumber: String
    var tripDate: String
    var pickup: TripStop
    var destination: TripStop
    var cargoWeight: String
    var cargoUnits: String
}

extension Trip {
    static var mockTrip: Trip {
        Trip(
            routeNumber: "IND-900", tripDate: "",
            pickup: TripStop(
                name: "Mysore Palace",
                coordinate: CLLocationCoordinate2D(latitude: 12.3051, longitude: 76.6551),
                time: "08:00 AM",
                status: .completed
            ),
            destination: TripStop(
                name: "Bangalore Airport (Kempegowda International Airport)",
                coordinate: CLLocationCoordinate2D(latitude: 13.1986, longitude: 77.7066),
                time: "01:30 PM",
                status: .upcoming
            ),
            cargoWeight: "12.0t",
            cargoUnits: "Industrial Goods (18)"
        )
    }
}
