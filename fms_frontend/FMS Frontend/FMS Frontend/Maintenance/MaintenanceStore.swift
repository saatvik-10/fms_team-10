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
                title: "Tire Calibration",
                vehicleName: "Tata Prima",
                vehicleVIN: "3VWCP1192BM00",
                serviceType: "Routine",
                priority: .medium,
                status: .pending,
                taskDetails: "Standard calibration required.",
                scheduledDate: Date().addingTimeInterval(172800),
                technicianId: "Arjun-M",
                technicianNotes: "Verified all tires.",
                partsNeeded: [
                    Part(name: "Air Valve Caps", description: "Replacement", iconName: "gearshape.fill", imageAsset: "tire_part")
                ],
                imageAsset: "tire_part"
            )
        ]
        
        self.inspections = [
            TripInspection(
                title: "Pre-Trip Audit",
                vehicleId: "V-842",
                unitName: "Ashok Leyland Captain",
                unitVIN: "1HGCM8263JA05",
                driverId: "DRV-Rahul",
                timestamp: Date(),
                type: .preTrip,
                vehicleType: .truck,
                status: .pending,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "Arjun-S",
                imageAsset: "truck_main",
                imagesData: [UIImage(named: "truck_main")?.jpegData(compressionQuality: 0.5) ?? UIColor.systemBlue.image().jpegData(compressionQuality: 0.1)!],
                imageAnalyses: ["Analysis: Within operational standards."]
            ),
            TripInspection(
                title: "Daily Pre-Trip",
                vehicleId: "V-115",
                unitName: "BharatBenz 3523R",
                unitVIN: "JTMBU4230L901",
                driverId: "DRV-Amit",
                timestamp: Date(),
                type: .preTrip,
                vehicleType: .truck,
                status: .pending,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "Arjun-S",
                imageAsset: "truck_main",
                imagesData: [UIImage(named: "engine_part")?.jpegData(compressionQuality: 0.5) ?? UIColor.systemRed.image().jpegData(compressionQuality: 0.1)!],
                imageAnalyses: ["Analysis: Manifold signature uniform."]
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

    func deleteWorkOrder(_ order: WorkOrder) {
        workOrders.removeAll { $0.id == order.id }
    }

    func deleteInspection(_ inspection: TripInspection) {
        inspections.removeAll { $0.id == inspection.id }
    }

    func updateInspection(_ inspection: TripInspection) {
        if let index = inspections.firstIndex(where: { $0.id == inspection.id }) {
            inspections[index] = inspection
        }
    }

    func updateInspectionAnalysis(id: UUID, index: Int, analysis: String) {
        if let idx = inspections.firstIndex(where: { $0.id == id }) {
            if index < inspections[idx].imageAnalyses.count {
                inspections[idx].imageAnalyses[index] = analysis
            }
        }
    }
}
