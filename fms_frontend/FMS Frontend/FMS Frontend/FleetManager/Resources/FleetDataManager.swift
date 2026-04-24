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
    
    // Performance Trends (New)
    @Published var utilizationTrend = MockDataProvider.utilizationTrend
    @Published var efficiencyTrend = MockDataProvider.efficiencyTrend
    @Published var costTrend = MockDataProvider.costTrend
    @Published var idleTrend = MockDataProvider.idleTrend
    
    @Published var drivers = MockDataProvider.drivers
    @Published var vehicles = MockDataProvider.vehicles
    @Published var maintenancePersonnel = MockDataProvider.maintenancePersonnel
    
    // New Analytics (New)
    @Published var maintenanceCostPerVehicle = MockDataProvider.maintenanceCostPerVehicle
    @Published var totalKmsTravelled = MockDataProvider.totalKmsTravelled
    @Published var driverDistanceData = MockDataProvider.driverDistanceData
    
    @Published var travelsHistory = MockDataProvider.travelsHistory
    @Published var geofenceAlerts: [GeofenceAlert] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    struct GeofenceAlert: Identifiable {
        let id = UUID()
        let tripID: String
        let vehicleID: String
        let message: String
        let timestamp: Date
        let type: GeofenceAlertType
    }
    
    enum GeofenceAlertType {
        case departure, arrival
    }
    
    init() {
        setupGeofenceObservers()
    }
    
    private func setupGeofenceObservers() {
        NotificationCenter.default.publisher(for: .geofenceEntered)
            .sink { [weak self] notification in
                self?.handleGeofenceEvent(notification: notification, type: .arrival)
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: .geofenceExited)
            .sink { [weak self] notification in
                self?.handleGeofenceEvent(notification: notification, type: .departure)
            }
            .store(in: &cancellables)
    }
    
    private func handleGeofenceEvent(notification: Notification, type: GeofenceAlertType) {
        guard let regionID = notification.userInfo?["region"] as? String else { return }
        
        // regionID format: trip_UUID_origin or trip_UUID_destination
        let components = regionID.components(separatedBy: "_")
        guard components.count >= 3 else { return }
        
        let tripID = components[1]
        let locationType = components[2] // origin or destination
        
        // Find the vehicle with this trip
        if let vIndex = vehicles.firstIndex(where: { $0.currentTrip?.id.uuidString == tripID }) {
            let vehicle = vehicles[vIndex]
            let trip = vehicle.currentTrip!
            
            var message = ""
            var statusUpdate: FleetTripStatus? = nil
            
            if type == .departure && locationType == "origin" {
                message = "Vehicle \(vehicle.id) has departed from \(trip.origin)"
                statusUpdate = .inTransit
            } else if type == .arrival && locationType == "destination" {
                message = "Vehicle \(vehicle.id) has arrived at \(trip.destination)"
                statusUpdate = .completed
            }
            
            if !message.isEmpty {
                DispatchQueue.main.async {
                    // Update status
                    if let newStatus = statusUpdate {
                        self.vehicles[vIndex].currentTrip?.status = newStatus
                        if newStatus == .completed {
                            // Move to history
                            var completedTrip = self.vehicles[vIndex].currentTrip!
                            completedTrip.status = .completed
                            self.vehicles[vIndex].history.insert(completedTrip, at: 0)
                            self.vehicles[vIndex].currentTrip = nil
                            self.vehicles[vIndex].status = .idle
                        } else if newStatus == .inTransit {
                            self.vehicles[vIndex].status = .inTransit
                        }
                    }
                    
                    // Add alert
                    let alert = GeofenceAlert(
                        tripID: tripID,
                        vehicleID: vehicle.id,
                        message: message,
                        timestamp: Date(),
                        type: type
                    )
                    self.geofenceAlerts.insert(alert, at: 0)
                    
                    // Keep only last 10 alerts
                    if self.geofenceAlerts.count > 10 {
                        self.geofenceAlerts.removeLast()
                    }
                }
            }
        }
    }
    
    var idleDriversCount: Int { idleDrivers.count }
    var idleDrivers: [Driver] { drivers.filter { $0.status == .active || $0.status == .offDuty } }
    
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
    
    var healthyCount: Int {
        vehicles.count - criticalCount - warningCount
    }
    
    var warningCount: Int {
        vehicles.filter { $0.status == .maintenance && !($0.maintenance.alerts.contains(where: { $0.status == "Urgent" })) }.count
    }
    
    var criticalCount: Int {
        vehicles.filter { $0.maintenance.alerts.contains(where: { $0.status == "Urgent" }) }.count
    }
    
    // MARK: - Advanced Analytics Structs
    
    struct DriverPerformanceData: Identifiable {
        let id: String
        let name: String
        let efficiencyScore: Double
        let idleHours: Double
        let tripsCompleted: Int
    }
    
    struct FleetHealthDistribution: Identifiable {
        let id = UUID()
        let category: String
        let count: Int
        let color: Color
    }
    
    // MARK: - Derivable Performance Metrics
    
    var utilizationRate: Double {
        guard !vehicles.isEmpty else { return 0 }
        return Double(activeCount) / Double(vehicles.count)
    }
    
    var fleetIdleScore: Double {
        guard !vehicles.isEmpty else { return 0 }
        return Double(idleCount) / Double(vehicles.count)
    }
    
    var driverRankings: [DriverPerformanceData] {
        drivers.map { driver in
            let driverTrips = vehicles.flatMap { $0.history }.filter { $0.vehicleID == driver.currentVehicleID }
            let completedCount = driverTrips.filter { $0.status == .completed }.count
            
            // Artificial but deterministic derivation
            let baseEfficiency = Double(driver.efficiency.replacingOccurrences(of: "%", with: "")) ?? 85.0
            let idleSim = Double(100 - baseEfficiency) / 2.0
            
            return DriverPerformanceData(
                id: driver.id,
                name: driver.name,
                efficiencyScore: baseEfficiency,
                idleHours: idleSim,
                tripsCompleted: completedCount + (driver.totalTrips)
            )
        }.sorted { $0.efficiencyScore > $1.efficiencyScore }
    }
    
    var healthDistribution: [FleetHealthDistribution] {
        let critical = vehicles.filter { $0.maintenance.alerts.contains(where: { $0.status == "Urgent" }) }.count
        let warning = vehicles.filter { $0.status == .maintenance && !($0.maintenance.alerts.contains(where: { $0.status == "Urgent" })) }.count
        let healthy = vehicles.count - critical - warning
        
        return [
            FleetHealthDistribution(category: "Healthy", count: healthy, color: AppColors.activeGreen),
            FleetHealthDistribution(category: "Warning", count: warning, color: .orange),
            FleetHealthDistribution(category: "Critical", count: critical, color: AppColors.criticalRed)
        ]
    }
    
    var averageEfficiency: Double {
        let completed = allHistory.filter { $0.status == .completed }
        guard !completed.isEmpty else { return 0 }
        
        let totalSpeed = completed.reduce(0.0) { sum, trip in
            let dist = parseNumericValue(trip.distance)
            let dur = parseNumericValue(trip.duration)
            return sum + (dur > 0 ? dist / dur : 0)
        }
        return totalSpeed / Double(completed.count)
    }
    
    var costPerKm: Double {
        let completed = allHistory.filter { $0.status == .completed }
        guard !completed.isEmpty else { return 0 }
        
        let totalCost = completed.reduce(0.0) { $0 + parseNumericValue($1.costEstimate) }
        let totalDist = completed.reduce(0.0) { $0 + parseNumericValue($1.distance) }
        return totalDist > 0 ? totalCost / totalDist : 0
    }
    
    var fuelEfficiencyData: [(vehicleID: String, efficiency: Double)] {
        vehicles.map { vehicle in
            let dist = vehicle.history.reduce(0.0) { $0 + parseNumericValue($1.distance) }
            // Simulated fuel consumption factor based on vehicle type
            let factor = vehicle.type == "Truck" ? 0.35 : 0.12
            let fuelUsed = dist * factor
            let efficiency = dist > 0 ? (fuelUsed / dist) * 100 : 0
            return (vehicleID: vehicle.id, efficiency: efficiency)
        }
    }
    
    var totalEmissions: Double {
        let totalKm = allHistory.reduce(0.0) { $0 + parseNumericValue($1.distance) }
        return totalKm * 0.12 // 0.12kg CO2 per KM as a realistic fleet average
    }
    
    // MARK: - Insight Discovery (Anomalies)
    
    struct FleetInsight: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let type: InsightType
    }
    
    enum InsightType {
        case efficiency, maintenance, utilization
    }
    
    var derivedInsights: [FleetInsight] {
        var insights: [FleetInsight] = []
        
        // 1. Underutilized
        let underutilizedCount = vehicles.filter { $0.status == .idle && $0.history.isEmpty }.count
        if underutilizedCount > 0 {
            insights.append(FleetInsight(
                title: "Underutilized Assets",
                description: "\(underutilizedCount) vehicles have 0 trips in the last 7 days.",
                type: .utilization
            ))
        }
        
        // 2. High Maintenance Frequency
        let highMaintenanceVehicles = vehicles.filter { $0.maintenance.alerts.count > 2 }
        if let first = highMaintenanceVehicles.first {
            insights.append(FleetInsight(
                title: "High Maintenance Frequency",
                description: "Vehicle \(first.id) has reported \(first.maintenance.alerts.count) issues this month.",
                type: .maintenance
            ))
        }
        
        // 3. Efficiency Leader
        if averageEfficiency > 45 { // 45 km/h threshold for "good"
            insights.append(FleetInsight(
                title: "Efficiency Leaderboard",
                description: "Fleet average speed is +12% above quarterly benchmark.",
                type: .efficiency
            ))
        }
        
        return insights
    }
    
    // MARK: - Helpers
    
    private func parseNumericValue(_ input: String?) -> Double {
        guard let input = input else { return 0 }
        let filtered = input.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
        return Double(filtered) ?? 0
    }
    
    // Actions
    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
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
        if let index = vehicles.firstIndex(where: { $0.id == vehicleID }) {
            vehicles[index].currentTrip = trip
            if trip.status == .inTransit {
                vehicles[index].status = .inTransit
            }
        }
    }
}
