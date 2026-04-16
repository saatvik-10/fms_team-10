//
//  WorkOrderManagementViewModel.swift
//  FMS Frontend
//

import SwiftUI
import Combine

class WorkOrderManagementViewModel: ObservableObject {
    @Published var workOrders: [WorkOrder] = [
        WorkOrder(vehicleId: "V-102", taskDescription: "Replace front brake pads", status: .inProgress, technicianId: "TECH-1", createdAt: Date().addingTimeInterval(-86400), updatedAt: Date()),
        WorkOrder(vehicleId: "V-205", taskDescription: "Check engine diagnostic codes", status: .pending, technicianId: "TECH-2", createdAt: Date().addingTimeInterval(-172800), updatedAt: Date()),
        WorkOrder(vehicleId: "V-304", taskDescription: "Oil change and tire rotation", status: .completed, technicianId: "TECH-1", createdAt: Date().addingTimeInterval(-259200), updatedAt: Date())
    ]
    
    func updateStatus(for orderId: UUID, to status: WorkOrderStatus) {
        if let index = workOrders.firstIndex(where: { $0.id == orderId }) {
            workOrders[index].status = status
            workOrders[index].updatedAt = Date()
        }
    }
    
    func addWorkOrder(vehicleId: String, description: String, technicianId: String) {
        let newOrder = WorkOrder(
            vehicleId: vehicleId,
            taskDescription: description,
            status: .pending,
            technicianId: technicianId,
            createdAt: Date(),
            updatedAt: Date()
        )
        workOrders.insert(newOrder, at: 0)
    }
}
