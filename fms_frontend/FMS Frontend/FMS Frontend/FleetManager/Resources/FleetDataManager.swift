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
    @Published var mileageData = MockDataProvider.mileageData
    @Published var fuelTrendData = MockDataProvider.fuelTrendData
    @Published var drivers = MockDataProvider.drivers
    @Published var vehicles = MockDataProvider.vehicles
    
    // Computed Metrics
    var activeCount: Int {
        vehicles.filter { $0.status == .inTransit }.count
    }
    
    var idleCount: Int {
        vehicles.filter { $0.status == .idle }.count
    }
    
    var maintenanceCount: Int {
        vehicles.filter { $0.status == .maintenance }.count
    }
    
    var scheduledCount: Int {
        vehicles.filter { $0.currentTrip?.status == .scheduled }.count
    }
    
    var allHistory: [VehicleTrip] {
        vehicles.flatMap { $0.history }.sorted { ($0.date ?? "") > ($1.date ?? "") }
    }
    
    // Actions
    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
    }
    
    func addDriver(_ driver: Driver) {
        drivers.append(driver)
    }
    
    func addOrder(trip: VehicleTrip, vehicleID: String) {
        // Simple logic to assign a trip to a vehicle
        if let index = vehicles.firstIndex(where: { $0.id == vehicleID }) {
            vehicles[index].currentTrip = trip
            // Note: If trip status is .scheduled, vehicle status might still be .idle
            // until the trip is started. For this demo, we auto-start if inTransit.
            if trip.status == .inTransit {
                vehicles[index].status = .inTransit
            }
        }
    }
}
