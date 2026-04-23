import Combine
import SwiftUI
import Foundation

class FleetDataManager: ObservableObject {
    @Published var dashboardStats = MockDataProvider.dashboardStats
    @Published var shipments = MockDataProvider.shipments
    @Published var fleetStatus = MockDataProvider.fleetStatus
    @Published var assessments = MockDataProvider.assessments
    @Published var maintenanceAlerts = MockDataProvider.maintenanceAlerts
    @Published var emissionData = MockDataProvider.emissionData
    @Published var drivers = MockDataProvider.drivers
    @Published var vehicles = MockDataProvider.vehicles
    @Published var maintenancePersonnel = MockDataProvider.maintenancePersonnel
    
    // Actions
    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
        // Update stats if needed
        fleetStatus.idle += 1
    }
    
    func addDriver(_ driver: Driver) {
        drivers.append(driver)
    }
    
    func addMaintenancePersonnel(_ person: MaintenancePersonnel) {
        maintenancePersonnel.append(person)
    }
    
    func deleteMaintenancePersonnel(_ person: MaintenancePersonnel) {
        maintenancePersonnel.removeAll(where: { $0.id == person.id })
    }
    
    func addOrder(trip: VehicleTrip, vehicleID: String) {
        // Simple logic to assign a trip to a vehicle
        if let index = vehicles.firstIndex(where: { $0.id == vehicleID }) {
            vehicles[index].currentTrip = trip
            vehicles[index].status = .inTransit
            
            // Adjust stats mock
            fleetStatus.active += 1
            if fleetStatus.idle > 0 { fleetStatus.idle -= 1 }
        }
    }
}
