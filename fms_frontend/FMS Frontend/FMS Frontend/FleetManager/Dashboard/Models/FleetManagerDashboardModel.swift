import Foundation
import SwiftUI

// MARK: - Dashboard
struct FleetManagerDashboardStats {
    let totalShipments: Int
    let totalShipmentsTrend: String
    let pendingPackages: Int
    let pendingPackagesTrend: String
    let deliveryShipments: Int
    let deliveryShipmentsTrend: String
    
    // Maintenance & Priority (New)
    let maintenanceSummary: String
    let criticalMass: Double
}

struct ShipmentActivity: Identifiable {
    let id = UUID()
    let orderID: String
    let category: String
    let company: String
    let arrivalTime: String
    let route: String
    let price: String
    let status: ShipmentStatus
}

enum ShipmentStatus: String {
    case delivered = "Delivered"
    case inTransit = "In Transit"
    case pending = "Pending"
    case processing = "Processing"
}

struct FleetVehicleStatus {
    var active: Int
    let activeTrend: String
    var maintenance: Int
    var idle: Int
    let critical: Int
}

struct SmartFleetAssessment: Identifiable {
    let id = UUID()
    let truckName: String
    let truckID: String
    let routeFrom: String
    let routeTo: String
    let etaTime: String
    let etaDay: String
    let status: AssessmentStatus
    let imageName: String
}

enum AssessmentStatus {
    case inTransit
    case alertReceived
    case restStop
    case scheduled
}

struct FleetMaintenanceAlert: Identifiable {
    let id: UUID
    let title: String
    let detail: String
    let iconName: String
    let status: String
    let vehicleID: String
    let taskDetails: String
    let notes: String
    let media: [String]
    var isAccepted: Bool
    
    init(id: UUID = UUID(), title: String, detail: String, iconName: String, status: String, vehicleID: String = "TRK-9042", taskDetails: String = "Standard system check and sensor calibration required.", notes: String = "User reported minor vibration at high speeds.", media: [String] = ["brake_part", "engine_part"], isAccepted: Bool = false) {
        self.id = id
        self.title = title
        self.detail = detail
        self.iconName = iconName
        self.status = status
        self.vehicleID = vehicleID
        self.taskDetails = taskDetails
        self.notes = notes
        self.media = media
        self.isAccepted = isAccepted
    }
}

struct EmissionData: Identifiable {
    let id = UUID()
    let day: String
    let value: Double
    let isCurrent: Bool
}

struct MileageData: Identifiable {
    let id = UUID()
    let day: String
    let value: Double
}

struct FuelTrendData: Identifiable {
    let id = UUID()
    let month: String
    let value: Double
}

struct HistoricalPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color?
    
    init(label: String, value: Double, color: Color? = nil) {
        self.label = label
        self.value = value
        self.color = color
    }
}

// MARK: - Management (New)

struct Driver: Identifiable {
    let id: String
    let name: String
    let email: String // New field for manual entry
    let title: String
    let licenseNum: String
    let licenseExp: String
    let status: DriverStatus
    let rating: Double
    let efficiency: String
    let totalTrips: Int
    let totalHours: Int
    let activityLog: [ActivityEvent]
    
    // Assignment info (New)
    let currentVehicleID: String?
    let vehicleClasses: [String] // Format like "LMV-NT", "HGV"
    let activeRoute: String?
    let eta: String?
    let phone: String // New field
    
    var identifier: UUID { UUID() }
}

enum DriverStatus: String {
    case active = "ACTIVE"
    case onTrip = "ON TRIP"
    case offDuty = "OFF DUTY"
    case onDuty = "ON DUTY"
}

struct MaintenancePersonnel: Identifiable {
    let id = UUID()
    let backendId: String?
    let name: String
    let phone: String
    let email: String
    let dob: Date
    let age: Int?
    let currentAssignment: String? // Vehicle ID
}

struct ActivityEvent: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let time: String
    let type: String // "completed", "refueling", "started", "incident"
    let value: String?
}

struct Vehicle: Identifiable {
    let id: String
    let make: String
    let model: String
    let type: String
    var status: VehicleStatus
    let imageName: String
    
    // Detail View Fields (New)
    let year: String
    let color: String
    let odometer: String
    let operationalStatus: String
    var currentTrip: VehicleTrip?
    let assignedDriver: Driver?
    let maintenance: VehicleMaintenance
    let history: [VehicleTrip]
    let reports: [VehicleReport]
    let assessmentReason: String? // Direct link to dashboard assessment logic
    
    let plateNumber: String // New field
    let registrationNumber: String // New field
}

enum FleetTripStatus: String, Codable {
    case scheduled = "Scheduled"
    case inTransit = "In Transit"
    case completed = "Completed"
}

struct VehicleTrip: Identifiable {
    let id = UUID()
    let vehicleID: String // Link to the owning vehicle
    let origin: String
    let destination: String
    let progress: Double
    let eta: String
    let date: String?
    let distance: String?
    let duration: String?
    let costEstimate: String?
    let startTime: Date?
    var status: FleetTripStatus
    
    // Cargo Details (New)
    let productType: String?
    let loadAmount: String?
}

struct VehicleMaintenance {
    let nextService: String
    let inspectionStatus: String
    let alerts: [FleetMaintenanceAlert]
}

struct VehicleReport: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let fileType: String // "pdf"
    
    // Detailed Report Data (New)
    let date: String
    let serviceProvider: String
    let tasks: [ReportTask]
    let totalCost: String
}

struct ReportTask: Identifiable {
    let id = UUID()
    let description: String
    let cost: String
}

enum VehicleStatus: String {
    case inTransit = "IN TRANSIT"
    case idle = "IDLE"
    case maintenance = "UNDER MAINTENANCE"
}

struct ManagerProfileData: Identifiable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let address: String?
    let username: String
    let role: String
}
