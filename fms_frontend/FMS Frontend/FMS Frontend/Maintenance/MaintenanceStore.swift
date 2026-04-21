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
    @Published var inventoryParts: [InventoryPart] = []
    
    init() {
        loadMockData()
        loadInventory()
    }
    
    // MARK: - Persistence
    private let inventoryKey = "fms_inventory_data"
    
    func saveInventory() {
        if let encoded = try? JSONEncoder().encode(inventoryParts) {
            UserDefaults.standard.set(encoded, forKey: inventoryKey)
        }
    }
    
    func loadInventory() {
        if let data = UserDefaults.standard.data(forKey: inventoryKey),
           let decoded = try? JSONDecoder().decode([InventoryPart].self, from: data) {
            self.inventoryParts = decoded
        }
    }
    
    func updateInventoryThreshold(for sku: String, newThreshold: Int) {
        if let index = inventoryParts.firstIndex(where: { $0.sku == sku }) {
            inventoryParts[index].reorderThreshold = newThreshold
            saveInventory()
        }
    }
    
    func importInventory(_ newParts: [InventoryPart]) {
        // Keep existing thresholds if SKU matches
        var mergedParts = newParts
        for i in 0..<mergedParts.count {
            if let existing = inventoryParts.firstIndex(where: { $0.sku == mergedParts[i].sku }) {
                mergedParts[i].reorderThreshold = inventoryParts[existing].reorderThreshold
            }
        }
        self.inventoryParts = mergedParts
        saveInventory()
    }

    var lowStockCount: Int {
        inventoryParts.filter { $0.isLowStock }.count
    }
    
    var totalInventoryValue: Double {
        inventoryParts.reduce(0) { $0 + $1.totalValue }
    }
    
    func loadMockData() {
        self.workOrders = [
            WorkOrder.mock,
            WorkOrder(
                title: "Tire Pressure Calibration",
                vehicleName: "Volvo FH16 (Truck)",
                vehicleVIN: "3VWCP1192BM00",
                serviceType: "Routine PM",
                priority: .medium,
                status: .pending,
                taskDetails: "Driver reports slight pulling to the left. Standard calibration for multi-axle trailer required.",
                scheduledDate: Date().addingTimeInterval(172800),
                technicianId: "TECH-02",
                technicianNotes: "Verified all 18 tires. Outer rear axle on passenger side was 5 PSI low.",
                partsNeeded: [
                    Part(name: "Air Valve Caps", description: "Replacement for missing valve covers", iconName: "gearshape.fill", imageAsset: "tire_part")
                ],
                imageAsset: "tire_part"
            ),
            WorkOrder(
                title: "Engine Diagnostic",
                vehicleName: "MAN TGX (Truck)",
                vehicleVIN: "JTMBU4230L901",
                serviceType: "Repair",
                priority: .critical,
                status: .completed,
                taskDetails: "Check engine light active. P0420 code detected. Possible catalytic converter issue.",
                scheduledDate: Date().addingTimeInterval(-86400),
                technicianId: "TECH-01",
                technicianNotes: "Replaced O2 sensor. Cleared codes and performed 20-mile test drive. No reoccurrence.",
                imageAsset: "engine_part"
            )
        ]
        
        self.inspections = [
            TripInspection(
                title: "Pre-Trip Audit",
                vehicleId: "V-842",
                unitName: "Mercedes-Benz Actros (Truck)",
                unitVIN: "1HGCM8263JA05",
                driverId: "DRV-101",
                timestamp: Date(),
                type: .preTrip,
                vehicleType: .truck,
                status: .pending,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "STAFF-01",
                imageAsset: "truck_main",
                imagesData: [UIImage(named: "truck_main")?.jpegData(compressionQuality: 0.5) ?? UIColor.systemBlue.image().jpegData(compressionQuality: 0.1)!],
                imageAnalyses: ["Analysis: Front chassis and cab exterior appear within operational standards. No structural stress detected in the primary load-bearing points."]
            ),
            TripInspection(
                title: "Post-Trip Verification",
                vehicleId: "V-319",
                unitName: "Volvo FH16 (Truck)",
                unitVIN: "3VWCP1192BM12",
                driverId: "DRV-102",
                timestamp: Date(),
                type: .postTrip,
                vehicleType: .truck,
                status: .completed,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "STAFF-01",
                imageAsset: "truck_main",
                imagesData: [UIImage(named: "tire_part")?.jpegData(compressionQuality: 0.5) ?? UIColor.systemOrange.image().jpegData(compressionQuality: 0.1)!],
                imageAnalyses: ["Analysis: Tire tread depth remains optimal. Minor particulate buildup detected in the outer groove, but no sharp object penetration observed."]
            ),
            TripInspection(
                title: "Daily Pre-Trip",
                vehicleId: "V-115",
                unitName: "MAN TGX (Truck)",
                unitVIN: "JTMBU4230L901",
                driverId: "DRV-103",
                timestamp: Date(),
                type: .preTrip,
                vehicleType: .truck,
                status: .pending,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "STAFF-01",
                imageAsset: "truck_main",
                imagesData: [UIImage(named: "engine_part")?.jpegData(compressionQuality: 0.5) ?? UIColor.systemRed.image().jpegData(compressionQuality: 0.1)!],
                imageAnalyses: ["Analysis: Engine manifold thermal signature appears uniform. No fluid seepage detected around the secondary gasket seal."]
            ),
            TripInspection(
                title: "Standard Post-Trip",
                vehicleId: "V-990",
                unitName: "Toyota Coaster (Bus)",
                unitVIN: "5FNRL3H42GB91",
                driverId: "DRV-104",
                timestamp: Date(),
                type: .postTrip,
                vehicleType: .car,
                status: .completed,
                items: TripInspection.mockItems(for: .car),
                maintenanceStaffId: "STAFF-01",
                imageAsset: "truck_main",
                imagesData: [UIImage(named: "brake_part")?.jpegData(compressionQuality: 0.5) ?? UIColor.systemGreen.image().jpegData(compressionQuality: 0.1)!],
                imageAnalyses: ["Analysis: Brake disc surface shows normal friction heat patterns. No scoring or micro-fractures detected in the high-stress contact zone."]
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
