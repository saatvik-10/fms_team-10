//
//  MaintenanceSchedulingModel.swift
//  FMS Frontend
//

import Foundation

enum MaintenancePriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

struct MaintenanceSchedule: Identifiable, Codable {
    var id = UUID()
    let vehicleId: String
    let reportedIssue: String
    let driverId: String
    let priority: MaintenancePriority
    var scheduledDate: Date
    var status: String // e.g., "Pending", "Scheduled"
    
    static var mock: MaintenanceSchedule {
        MaintenanceSchedule(
            vehicleId: "V-1234",
            reportedIssue: "Brake squeaking on high speed",
            driverId: "D-901",
            priority: .high,
            scheduledDate: Date().addingTimeInterval(86400),
            status: "Pending"
        )
    }
}
