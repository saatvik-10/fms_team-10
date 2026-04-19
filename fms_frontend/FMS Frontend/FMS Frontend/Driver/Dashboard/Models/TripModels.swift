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
    var pickup: TripStop
    var destination: TripStop
    var stops: [TripStop]
    var cargoWeight: String
    var cargoUnits: String
}

extension Trip {
    static var mockTrip: Trip {
        Trip(
            routeNumber: "IND-900",
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
            stops: [
                TripStop(
                    name: "Mandya",
                    coordinate: CLLocationCoordinate2D(latitude: 12.5218, longitude: 76.8950),
                    time: "09:30 AM",
                    status: .upcoming
                ),
                TripStop(
                    name: "Ramanagara",
                    coordinate: CLLocationCoordinate2D(latitude: 12.7218, longitude: 77.2811),
                    time: "11:00 AM",
                    status: .upcoming
                ),
                TripStop(
                    name: "Yelahanka",
                    coordinate: CLLocationCoordinate2D(latitude: 13.1007, longitude: 77.5963),
                    time: "12:45 PM",
                    status: .upcoming
                )
            ],
            cargoWeight: "12.0t",
            cargoUnits: "Industrial Goods (18)"
        )
    }
}
