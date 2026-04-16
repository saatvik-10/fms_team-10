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
    let active: Int
    let activeTrend: String
    let maintenance: Int
    let idle: Int
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

struct MaintenanceAlert: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let iconName: String
    let status: String
}

struct EmissionData: Identifiable {
    let id = UUID()
    let day: String
    let value: Double
    let isCurrent: Bool
}

// MARK: - Management (New)

struct Driver: Identifiable {
    let id: String
    let name: String
    let title: String
    let licenseNum: String
    let licenseExp: String
    let status: DriverStatus
    let rating: Double
    let efficiency: String
    let totalTrips: Int
    let totalHours: Int
    let activityLog: [ActivityEvent]
    
    var identifier: UUID { UUID() }
}

enum DriverStatus: String {
    case active = "ACTIVE"
    case onTrip = "ON TRIP"
    case offDuty = "OFF DUTY"
    case onDuty = "ON DUTY"
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
    let status: VehicleStatus
    let imageName: String
}

enum VehicleStatus: String {
    case inTransit = "IN TRANSIT"
    case idle = "IDLE"
    case maintenance = "MAINTENANCE"
}
