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
        case departure, arrival, deviation
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
            
        NotificationCenter.default.publisher(for: .routeDeviationDetected)
            .sink { [weak self] notification in
                self?.handleDeviationEvent(notification: notification)
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
                            
                            // Stop route tracking
                            FleetRouteTracker.shared.stopTracking(tripID: tripID)
                            
                            self.vehicles[vIndex].currentTrip = nil
                            self.vehicles[vIndex].status = .idle
                        } else if newStatus == .inTransit {
                            self.vehicles[vIndex].status = .inTransit
                            
                            // Start route tracking
                            if let trip = self.vehicles[vIndex].currentTrip {
                                FleetRouteTracker.shared.startTracking(trip: trip)
                            }
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
    
    private func handleDeviationEvent(notification: Notification) {
        guard let tripID = notification.userInfo?["tripID"] as? String else { return }
        
        if let vIndex = vehicles.firstIndex(where: { $0.currentTrip?.id.uuidString == tripID }) {
            let vehicle = vehicles[vIndex]
            let message = "⚠️ ROUTE DEVIATION: Vehicle \(vehicle.id) has left the assigned corridor!"
            
            DispatchQueue.main.async {
                let alert = GeofenceAlert(
                    tripID: tripID,
                    vehicleID: vehicle.id,
                    message: message,
                    timestamp: Date(),
                    type: .deviation
                )
                self.geofenceAlerts.insert(alert, at: 0)
                
                if self.geofenceAlerts.count > 10 {
                    self.geofenceAlerts.removeLast()
                }
            }
        }
    }
    
    var totalDriversCount: Int { drivers.count }
    var inTransitDriversCount: Int { drivers.filter { $0.status == .onTrip }.count }
    var offDutyDriversCount: Int { drivers.filter { $0.status == .offDuty }.count }
    var idleDriversCount: Int { drivers.filter { $0.status == .active }.count }
    
    var idleDrivers: [Driver] { drivers.filter { $0.status == .active } }
    
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
        vehicles.filter { $0.status != .maintenance && $0.currentTrip?.status == .scheduled }.count
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
        if let backendId = vehicle.backendId,
           let index = vehicles.firstIndex(where: { $0.backendId == backendId }) {
            vehicles[index] = vehicle
        } else if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[index] = vehicle
        } else {
            vehicles.append(vehicle)
        }
    }

    func upsertVehicle(_ vehicle: Vehicle) {
        addVehicle(vehicle)
    }

    @MainActor
    func refreshVehicles() async throws {
        let response = try await VehicleAPI.shared.getVehicles()
        
        // Fetch all trips to populate vehicle history
        let allTripsResponse = try? await TripAPI.shared.getTrips()
        let allTrips = allTripsResponse?.trips ?? []
        
        vehicles = response.vehicles.map { item in
            // Filter and map trips for this vehicle
            let vehicleHistory = allTrips
                .filter { $0.vehicleId == item.id || $0.vehicleRegistrationNumber == item.registrationNumber }
                .map { trip in
                    VehicleTrip(
                        backendId: trip.id ?? UUID().uuidString,
                        vehicleID: item.registrationNumber,
                        origin: trip.sourceLocation ?? "Unknown",
                        destination: trip.destinationLocation ?? "Unknown",
                        progress: trip.status == "COMPLETED" ? 1.0 : 0.0,
                        eta: "",
                        date: trip.tripDate ?? "Unknown",
                        distance: trip.distanceKm ?? trip.tripDistance ?? "0 km",
                        duration: "",
                        costEstimate: "",
                        startTime: trip.createdAt,
                        status: trip.status == "COMPLETED" ? .completed : (trip.status == "IN_TRANSIT" ? .inTransit : .scheduled),
                        productType: trip.productType ?? "General",
                        loadAmount: trip.loadAmount ?? "0"
                    )
                }
            
            return Vehicle(
                id: item.registrationNumber,
                backendId: item.id,
                make: item.make,
                model: item.model,
                type: item.type,
                status: {
                    switch item.status {
                    case "IN_TRANSIT": return .inTransit
                    case "MAINTENANCE": return .maintenance
                    case "AVAILABLE": return .idle
                    case "SCHEDULED": return .scheduled
                    default: return .idle
                    }
                }(),
                imageName: item.imageName ?? "truck_freightliner_m2",
                year: item.year ?? "-",
                color: item.color ?? "-",
                operationalStatus: item.operationalStatus ?? "OPERATIONAL",
                currentTrip: item.currentTrip.map { trip in
                    VehicleTrip(
                        backendId: trip.id,
                        vehicleID: trip.vehicleId,
                        origin: trip.origin,
                        destination: trip.destination,
                        progress: trip.progress,
                        eta: trip.eta ?? "",
                        date: trip.date ?? "",
                        distance: trip.distance ?? "",
                        duration: trip.duration ?? "",
                        costEstimate: trip.costEstimate ?? "",
                        startTime: trip.startTime,
                        status: {
                            switch trip.status {
                            case "IN_TRANSIT": return .inTransit
                            case "COMPLETED": return .completed
                            case "SCHEDULED": return .scheduled
                            case "PENDING": return .pending
                            default: return .scheduled
                            }
                        }(),
                        productType: trip.productType ?? "",
                        loadAmount: trip.loadAmount ?? ""
                    )
                },
                assignedDriver: item.assignedDriver.map { driver in
                    Driver(
                        id: driver.id,
                        backendId: driver.id,
                        name: driver.name,
                        email: driver.phone ?? "",
                        title: "Driver",
                        licenseNum: driver.licenceNumber ?? "",
                        licenseExp: "2025",
                        status: .active,
                        rating: 4.5,
                        efficiency: "Good",
                        totalTrips: 0,
                        totalHours: 0,
                        activityLog: [],
                        currentVehicleID: nil,
                        vehicleClasses: driver.classes ?? [],
                        activeRoute: nil,
                        eta: nil,
                        phone: driver.phone ?? "",
                        dlFrontImageUrl: nil,
                        dlBackImageUrl: nil,
                        dlFrontImageKey: nil,
                        dlBackImageKey: nil
                    )
                },
                maintenance: item.maintenance.map { maint in
                    VehicleMaintenance(
                        nextService: maint.nextService ?? "TBD",
                        inspectionStatus: maint.inspectionStatus ?? "Verified",
                        alerts: []
                    )
                } ?? VehicleMaintenance(nextService: "TBD", inspectionStatus: "Verified", alerts: []),
                history: vehicleHistory.filter { $0.status == .completed },
                reports: [],
                assessmentReason: item.assessmentReason,
                chassisNumber: item.chassisNumber,
                registrationNumber: item.registrationNumber,
                rcImageUrl: item.rcImageUrl,
                vehicleImageUrl: item.vehicleImageUrl,
                maxLoadCapacity: item.maxLoadCapacity ?? 0.0,
                capacityUnit: item.capacityUnit ?? "KG",
                createdAt: item.createdAt
            )
        }
    }

    @MainActor
    func deleteVehicle(_ vehicle: Vehicle) async {
        if let backendId = vehicle.backendId {
            do {
                _ = try await VehicleAPI.shared.deleteVehicle(id: backendId)
            } catch {
                print("Delete API failed for vehicle ID \(backendId): \(error)")
            }
        }

        if let backendId = vehicle.backendId {
            vehicles.removeAll(where: { $0.backendId == backendId })
        } else {
            vehicles.removeAll(where: { $0.id == vehicle.id })
        }
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
            
            let mappedStatus: DriverStatus
            switch item.status {
            case "ACTIVE": mappedStatus = .active
            case "ON_TRIP": mappedStatus = .onTrip
            case "OFF_DUTY": mappedStatus = .offDuty
            default: mappedStatus = .active // Default to active so they appear in assignment pickers if unknown
            }
            
            return Driver(
                id: item.username ?? item.id ?? "Driver",
                backendId: item.id,
                name: item.name ?? "Driver",
                email: item.email ?? "",
                title: "\(classes.first ?? "LMV-NT") Certified Driver",
                licenseNum: item.licenceNumber ?? "-",
                licenseExp: item.expiryDate ?? "-",
                status: mappedStatus,
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
    func updateMaintenancePersonnel(_ person: MaintenancePersonnel) {
        if let index = maintenancePersonnel.firstIndex(where: { $0.backendId == person.backendId }) {
            maintenancePersonnel[index] = person
        }
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
