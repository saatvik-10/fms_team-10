//
//  MaintenanceDashboardViewModel.swift
//  FMS Frontend
//

import Combine
import SwiftUI

class MaintenanceDashboardViewModel: ObservableObject {
    @Published var pendingInspectionsCount: Int = 3
    @Published var activeWorkOrdersCount: Int = 5
    @Published var scheduledMaintenanceCount: Int = 2
    
    @Published var recentAlerts: [MaintenanceAlert] = [
        MaintenanceAlert(title: "Pre-Trip Inspection Required", message: "Vehicle V-102 is ready for inspection.", type: .inspection, time: "10 mins ago", vehicleId: "V-102", issueDescription: "Routine Pre-Trip Inspection"),
        MaintenanceAlert(title: "Urgent Maintenance", message: "Driver reported brake issues for V-205.", type: .maintenance, time: "1 hour ago", vehicleId: "V-205", issueDescription: "Brake issues reported by driver")
    ]
    
    struct MaintenanceAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let type: AlertType
        let time: String
        let vehicleId: String?
        let issueDescription: String?
        
        enum AlertType {
            case inspection, maintenance, warning
        }
    }
}
