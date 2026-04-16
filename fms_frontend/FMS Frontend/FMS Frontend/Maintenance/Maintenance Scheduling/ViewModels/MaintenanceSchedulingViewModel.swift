//
//  MaintenanceSchedulingViewModel.swift
//  FMS Frontend
//

import SwiftUI
import Combine

class MaintenanceSchedulingViewModel: ObservableObject {
    @Published var schedules: [MaintenanceSchedule] = [
        MaintenanceSchedule(vehicleId: "V-123", reportedIssue: "Engine light on", driverId: "D-05", priority: .high, scheduledDate: Date(), status: "Pending"),
        MaintenanceSchedule(vehicleId: "V-990", reportedIssue: "Tire replacement", driverId: "D-12", priority: .medium, scheduledDate: Date().addingTimeInterval(3600), status: "Pending")
    ]
    
    @Published var selectedVehicleId = ""
    @Published var issueDescription = ""
    @Published var selectedPriority: MaintenancePriority = .medium
    @Published var scheduledDate = Date()
    
    init(vehicleId: String? = nil, description: String? = nil) {
        if let vehicleId = vehicleId {
            self.selectedVehicleId = vehicleId
        }
        if let description = description {
            self.issueDescription = description
        }
    }
    
    func scheduleMaintenance() {
        let newSchedule = MaintenanceSchedule(
            vehicleId: selectedVehicleId,
            reportedIssue: issueDescription,
            driverId: "M-CONTROLLER",
            priority: selectedPriority,
            scheduledDate: scheduledDate,
            status: "Scheduled"
        )
        schedules.append(newSchedule)
        // Reset form
        selectedVehicleId = ""
        issueDescription = ""
    }
}
