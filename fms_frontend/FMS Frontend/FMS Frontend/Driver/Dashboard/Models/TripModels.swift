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
    var stops: [TripStop]
    var cargoWeight: String
    var cargoUnits: String
}

extension Trip {
    static var mockTrip: Trip {
        Trip(
            routeNumber: "IND-402",
            tripDate: "", // Dashboard mock trip has no date lock
            pickup: TripStop(
                name: "Nhava Sheva Port, Terminal 2, Mumbai",
                coordinate: CLLocationCoordinate2D(latitude: 18.9499, longitude: 72.9525),
                time: "08:00 AM",
                status: .completed
            ),
            destination: TripStop(
                name: "Sector 18, Gurgaon, Haryana",
                coordinate: CLLocationCoordinate2D(latitude: 28.4815, longitude: 77.0736),
                time: "10:00 PM",
                status: .upcoming
            ),
            stops: [
                TripStop(
                    name: "Vadodara Checkpoint",
                    coordinate: CLLocationCoordinate2D(latitude: 22.3072, longitude: 73.1812),
                    time: "02:30 PM",
                    status: .completed
                ),
                TripStop(
                    name: "Udaipur Hub",
                    coordinate: CLLocationCoordinate2D(latitude: 24.5854, longitude: 73.7125),
                    time: "08:15 PM",
                    status: .active
                ),
                TripStop(
                    name: "Jaipur Transit",
                    coordinate: CLLocationCoordinate2D(latitude: 26.9124, longitude: 75.7873),
                    time: "01:00 AM",
                    status: .upcoming
                )
            ],
            cargoWeight: "18.4t",
            cargoUnits: "Standard Pallets (24)"
        )
    }
}
