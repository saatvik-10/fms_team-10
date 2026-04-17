//
//  WorkOrderManagementViewModel.swift
//  FMS Frontend
//

import SwiftUI
import Combine

class WorkOrderManagementViewModel: ObservableObject {
    @Published var workOrders: [WorkOrder] = [
        WorkOrder(title: "Replace front brake pads", vehicleName: "Unit 842-Alpha", vehicleVIN: "1HGCM8263JA05", serviceType: "Repair", priority: .high, status: .inProgress, taskDetails: "Replace front brake pads", scheduledDate: Date().addingTimeInterval(-86400), technicianId: "TECH-1"),
        WorkOrder(title: "Check engine diagnostic codes", vehicleName: "Unit 319-Echo", vehicleVIN: "3VWCP1192BM10", serviceType: "Inspection", priority: .medium, status: .pending, taskDetails: "Check engine diagnostic codes", scheduledDate: Date().addingTimeInterval(-172800), technicianId: "TECH-2"),
        WorkOrder(title: "Oil change and tire rotation", vehicleName: "Unit 115-Delta", vehicleVIN: "JTMBU4230L901", serviceType: "Routine PM", priority: .low, status: .completed, taskDetails: "Oil change and tire rotation", scheduledDate: Date().addingTimeInterval(-259200), technicianId: "TECH-1")
    ]
    
    func updateStatus(for orderId: UUID, to status: WorkOrderStatus) {
        if let index = workOrders.firstIndex(where: { $0.id == orderId }) {
            workOrders[index].status = status
            workOrders[index].updatedAt = Date()
        }
    }
    
    func addWorkOrder(vehicleId: String, description: String, technicianId: String) {
        let newOrder = WorkOrder(
            title: description,
            vehicleName: vehicleId,
            vehicleVIN: "VIN-UNKNOWN",
            serviceType: "General",
            priority: .medium,
            status: .pending,
            taskDetails: description,
            scheduledDate: Date(),
            technicianId: technicianId
        )
        workOrders.insert(newOrder, at: 0)
    }
}
