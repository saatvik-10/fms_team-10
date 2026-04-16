//
//  WorkOrderManagementModel.swift
//  FMS Frontend
//

import Foundation

enum WorkOrderStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
}

struct WorkOrder: Identifiable, Codable {
    var id = UUID()
    let vehicleId: String
    let taskDescription: String
    var status: WorkOrderStatus
    let technicianId: String
    let createdAt: Date
    var updatedAt: Date
    
    static var mock: WorkOrder {
        WorkOrder(
            vehicleId: "V-5678",
            taskDescription: "Replace brake pads and check fluid levels",
            status: .inProgress,
            technicianId: "TECH-01",
            createdAt: Date().addingTimeInterval(-172800),
            updatedAt: Date()
        )
    }
}
