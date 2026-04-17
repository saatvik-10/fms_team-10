//
//  MaintenanceStore.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI
import Combine

class MaintenanceStore: ObservableObject {
    @Published var workOrders: [WorkOrder] = []
    @Published var inspections: [TripInspection] = []
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        self.workOrders = [
            WorkOrder.mock,
            WorkOrder(
                title: "Tire Pressure Calibration",
                vehicleName: "Unit 319-Echo",
                vehicleVIN: "3VWCP1192BM00",
                serviceType: "Routine PM",
                priority: .medium,
                status: .pending,
                taskDetails: "Standard calibration for multi-axle trailer.",
                scheduledDate: Date().addingTimeInterval(172800),
                technicianId: "TECH-02",
                partsNeeded: [
                    Part(name: "Air Valve Caps", description: "Replacement for missing valve covers", iconName: "gearshape.fill")
                ]
            ),
            WorkOrder(
                title: "Engine Diagnostic",
                vehicleName: "Unit 115-Delta",
                vehicleVIN: "JTMBU4230L901",
                serviceType: "Repair",
                priority: .critical,
                status: .completed,
                taskDetails: "Check engine light active. P0420 code detected.",
                scheduledDate: Date().addingTimeInterval(-86400),
                technicianId: "TECH-01"
            )
        ]
        
        self.inspections = [
            TripInspection(
                vehicleId: "V-842",
                unitName: "Unit 842-Alpha",
                unitVIN: "1HGCM8263JA05",
                driverId: "DRV-101",
                timestamp: Date(),
                type: .preTrip,
                vehicleType: .truck,
                status: .pending,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "STAFF-01"
            ),
            TripInspection(
                vehicleId: "V-319",
                unitName: "Unit 319-Echo",
                unitVIN: "3VWCP1192BM12",
                driverId: "DRV-102",
                timestamp: Date(),
                type: .postTrip,
                vehicleType: .truck,
                status: .completed,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "STAFF-01"
            ),
            TripInspection(
                vehicleId: "V-115",
                unitName: "Unit 115-Delta",
                unitVIN: "JTMBU4230L901",
                driverId: "DRV-103",
                timestamp: Date(),
                type: .preTrip,
                vehicleType: .truck,
                status: .pending,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "STAFF-01"
            ),
            TripInspection(
                vehicleId: "V-990",
                unitName: "Unit 990-Zeta",
                unitVIN: "5FNRL3H42GB91",
                driverId: "DRV-104",
                timestamp: Date(),
                type: .preTrip,
                vehicleType: .truck,
                status: .completed,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "STAFF-01"
            )
        ]
    }
    
    func addWorkOrder(_ order: WorkOrder) {
        workOrders.insert(order, at: 0)
    }
    
    func updateWorkOrder(_ order: WorkOrder) {
        if let index = workOrders.firstIndex(where: { $0.id == order.id }) {
            workOrders[index] = order
        }
    }
    
    func addInspection(_ inspection: TripInspection) {
        inspections.insert(inspection, at: 0)
    }
    
    func deleteInspections(forUnit unitName: String) {
        inspections.removeAll { $0.unitName == unitName }
    }
}
