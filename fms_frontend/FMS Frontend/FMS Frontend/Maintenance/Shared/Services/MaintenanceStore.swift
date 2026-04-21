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
    @Published var inventory: [InventoryItem] = []
    
    // Dashboard Metrics
    var lowStockCount: Int {
        inventory.filter { $0.currentQuantity <= $0.minThreshold }.count
    }
    
    var complianceScore: Double {
        let completed = inspections.filter { $0.status == .completed }.count
        return inspections.isEmpty ? 100.0 : (Double(completed) / Double(inspections.count)) * 100.0
    }
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        self.workOrders = [
            WorkOrder(
                title: "Hydraulic Leak Repair",
                vehicleName: "JCB 3DX",
                vehicleVIN: "JCB123456789",
                serviceType: "Emergency",
                priority: .critical,
                status: .pending,
                taskDetails: "Major hydraulic fluid leak detected in the main boom cylinder.",
                scheduledDate: Date(),
                technicianId: "Arjun-M",
                technicianNotes: "Need to replace seals.",
                partsNeeded: [
                    Part(name: "Hydraulic Seal Kit", description: "Standard seal kit", iconName: "wrench.and.screwdriver.fill")
                ],
                imageAsset: "engine_part"
            ),
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
                title: "Emergency Brake Failure",
                vehicleId: "V-901",
                unitName: "Eicher Pro 6037",
                unitVIN: "9VWCP1192BM99",
                driverId: "DRV-Suresh",
                timestamp: Date(),
                type: .preTrip,
                vehicleType: .truck,
                status: .pending,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "Arjun-S",
                isEmergency: true,
                imageAsset: "brake_part"
            ),
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
        
        self.inventory = [
            InventoryItem(
                name: "Ceramic Brake Pads",
                sku: "BP-CER-001",
                description: "Heavy-duty ceramic pads for Actros/Prima.",
                category: "Brakes",
                currentQuantity: 12,
                minThreshold: 5,
                location: "A1-S2-B1",
                unitCost: 150.0,
                vendorInfo: "Global Parts Corp",
                leadTimeDays: 3,
                imageAsset: "brake_part"
            ),
            InventoryItem(
                name: "Hydraulic Seal Kit",
                sku: "SK-HYD-099",
                description: "Seal kit for boom cylinders.",
                category: "Hydraulics",
                currentQuantity: 2,
                minThreshold: 3,
                location: "B2-S1-B4",
                unitCost: 45.0,
                vendorInfo: "HydraForce",
                leadTimeDays: 5,
                imageAsset: "engine_part"
            ),
            InventoryItem(
                name: "DOT 4 Fluid",
                sku: "FL-DOT4-01",
                description: "High-boiling point brake fluid.",
                category: "Fluids",
                currentQuantity: 25,
                minThreshold: 10,
                location: "C1-S3-B2",
                unitCost: 12.0,
                vendorInfo: "Shell Lubricants",
                leadTimeDays: 2,
                imageAsset: "drop.fill"
            )
        ]
    }
    
    func addWorkOrder(_ order: WorkOrder) {
        workOrders.insert(order, at: 0)
    }
    
    func updateWorkOrder(_ order: WorkOrder) {
        if let index = workOrders.firstIndex(where: { $0.id == order.id }) {
            let oldStatus = workOrders[index].status
            workOrders[index] = order
            
            // If status changed to completed, generate an inspection record for the log
            if oldStatus != .completed && order.status == .completed {
                generateInspectionFromWorkOrder(order)
            }
        }
    }
    
    private func generateInspectionFromWorkOrder(_ order: WorkOrder) {
        // Use the Work Order's checklist for the inspection record
        let checklistItems = !order.checklist.isEmpty ? order.checklist : order.partsNeeded.map { 
            InspectionItem(name: $0.name, verificationCriteria: $0.description, result: .good, isImageRequired: false)
        }
        
        let inspection = TripInspection(
            title: order.title,
            vehicleId: "V-HIST",
            unitName: order.vehicleName,
            unitVIN: order.vehicleVIN,
            driverId: "SYSTEM",
            timestamp: Date(),
            type: .maintenance,
            vehicleType: order.vehicleName.contains("Bus") ? .car : .truck,
            status: .completed,
            items: checklistItems,
            notes: "Maintenance completed by \(order.technicianId). Notes: \(order.technicianNotes)",
            maintenanceStaffId: order.technicianId
        )
        addInspection(inspection)
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
