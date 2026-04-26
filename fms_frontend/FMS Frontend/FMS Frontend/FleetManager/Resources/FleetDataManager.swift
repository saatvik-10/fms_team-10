import Combine
import SwiftUI
import Foundation

class FleetDataManager: ObservableObject {
    @Published var dashboardStats = FleetManagerDashboardStats(
        totalShipments: 0,
        totalShipmentsTrend: "0%",
        pendingPackages: 0,
        pendingPackagesTrend: "0%",
        deliveryShipments: 0,
        deliveryShipmentsTrend: "0%",
        maintenanceSummary: "No dashboard data available yet.",
        criticalMass: 0
    )
    @Published var shipments: [ShipmentActivity] = []
    @Published var fleetStatus = FleetVehicleStatus(active: 0, activeTrend: "0%", maintenance: 0, idle: 0, critical: 0)
    @Published var assessments: [SmartFleetAssessment] = []
    @Published var maintenanceAlerts: [FleetMaintenanceAlert] = []
    @Published var emissionData: [EmissionData] = []
    @Published var mileageData: [MileageData] = []
    @Published var fuelTrendData: [FuelTrendData] = []
    
    // Performance Trends (New)
    @Published var utilizationTrend: [HistoricalPoint] = []
    @Published var efficiencyTrend: [HistoricalPoint] = []
    @Published var costTrend: [HistoricalPoint] = []
    @Published var idleTrend: [HistoricalPoint] = []
    
    @Published var drivers: [Driver] = []
    @Published var vehicles: [Vehicle] = []
    @Published var maintenancePersonnel: [MaintenancePersonnel] = []
    
    // New Analytics (New)
    @Published var maintenanceCostPerVehicle: [HistoricalPoint] = []
    @Published var totalKmsTravelled: Double = 0
    @Published var driverDistanceData: [HistoricalPoint] = []
    
    @Published var travelsHistory: [HistoricalPoint] = []
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
        if let backendId = driver.backendId,
           let index = drivers.firstIndex(where: { $0.backendId == backendId }) {
            drivers[index] = driver
        } else if let index = drivers.firstIndex(where: { $0.id == driver.id }) {
            drivers[index] = driver
        } else {
            drivers.append(driver)
        }
    }

    func upsertDriver(_ driver: Driver) {
        addDriver(driver)
    }

    @MainActor
    func refreshDrivers() async throws {
        let response = try await DriverAPI.shared.getDrivers()
        drivers = response.drivers.map { item in
            let classes = item.classes ?? []
            return Driver(
                id: item.username ?? item.id ?? "Driver",
                backendId: item.id,
                name: item.name ?? "Driver",
                email: item.email ?? "",
                title: "\(classes.first ?? "LMV-NT") Certified Driver",
                licenseNum: item.licenceNumber ?? "-",
                licenseExp: item.expiryDate ?? "-",
                status: .offDuty,
                rating: 5.0,
                efficiency: "100%",
                totalTrips: 0,
                totalHours: 0,
                activityLog: [],
                currentVehicleID: nil,
                vehicleClasses: classes,
                activeRoute: nil,
                eta: nil,
                phone: item.phone ?? "",
                dlFrontImageUrl: item.dlFrontImageUrl,
                dlBackImageUrl: item.dlBackImageUrl,
                dlFrontImageKey: item.dlFrontImageKey,
                dlBackImageKey: item.dlBackImageKey
            )
        }
    }
    
    func addMaintenancePersonnel(_ person: MaintenancePersonnel) {
        maintenancePersonnel.append(person)
    }

    @MainActor
    func saveDriverFromAPI(_ driver: Driver) {
        upsertDriver(driver)
    }

    @MainActor
    func deleteDriver(_ driver: Driver) async {
        if let backendId = driver.backendId {
            do {
                _ = try await DriverAPI.shared.deleteDriver(id: backendId)
            } catch {
                print("Delete API failed for driver ID \(backendId): \(error)")
            }
        }

        if let backendId = driver.backendId {
            drivers.removeAll(where: { $0.backendId == backendId })
        } else {
            drivers.removeAll(where: { $0.id == driver.id })
        }
    }

    @MainActor
    func refreshMaintenancePersonnel() async throws {
        let response = try await MaintenanceAPI.shared.getMaintenances()
        maintenancePersonnel = response.maintenances.map { item in
            MaintenancePersonnel(
                backendId: item.id,
                name: item.name ?? "To be integrated",
                phone: item.phone ?? "To be integrated",
                email: item.email ?? "To be integrated",
                dob: item.dob ?? Date(),
                age: item.age,
                currentAssignment: nil
            )
        }
    }
    
    @MainActor
    func deleteMaintenancePersonnel(_ person: MaintenancePersonnel) async {
        if let targetId = person.backendId {
            do {
                _ = try await MaintenanceAPI.shared.deleteMaintenance(id: targetId)
            } catch {
                print("Delete API failed for maintenance ID \(targetId): \(error)")
            }
        }

        if let targetId = person.backendId {
            maintenancePersonnel.removeAll(where: { $0.backendId == targetId })
        } else {
            maintenancePersonnel.removeAll(where: { $0.id == person.id })
        }
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
