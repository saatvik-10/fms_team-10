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
    
    // Dashboard Metrics
    var lowStockCount: Int {
        inventoryParts.filter { $0.isLowStock }.count
    }
    
    var totalInventoryValue: Double {
        inventoryParts.reduce(0) { $0 + $1.totalValue }
    }
    
    var complianceScore: Double {
        let completed = inspections.filter { $0.status == .completed }.count
        return inspections.isEmpty ? 100.0 : (Double(completed) / Double(inspections.count)) * 100.0
    }
    
    init() {
        loadMockData()
        loadInventory()
        if inventoryParts.isEmpty {
            loadInitialInventory()
        }
        refreshWorkOrderStatuses()
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
    
    func loadInitialInventory() {
        if let url = Bundle.main.url(forResource: "fleet_inventory_dataset", withExtension: "csv") {
            let (parts, errors) = InventoryCSVImportService.shared.parseCSV(at: url)
            if !parts.isEmpty {
                var processedParts = parts
                // Ensure some items are low stock for demonstration if none are naturally low
                if processedParts.filter({ $0.isLowStock }).isEmpty && processedParts.count > 5 {
                    processedParts[2].minStock = processedParts[2].stockQty + 5
                    processedParts[5].minStock = processedParts[5].stockQty + 5
                }
                self.inventoryParts = processedParts
                saveInventory()
            }
            if !errors.isEmpty {
                print("Encountered \(errors.count) errors loading initial inventory from CSV.")
            }
        }
    }
    
    func updateInventoryThreshold(for partId: String, newThreshold: Int) {
        if let index = inventoryParts.firstIndex(where: { $0.partId == partId }) {
            inventoryParts[index].minStock = newThreshold
            saveInventory()
        }
    }
    
    func importInventory(_ newParts: [InventoryPart]) {
        var mergedParts = newParts
        for i in 0..<mergedParts.count {
            if let existing = inventoryParts.firstIndex(where: { $0.partId == mergedParts[i].partId }) {
                mergedParts[i].minStock = inventoryParts[existing].minStock
            }
        }
        self.inventoryParts = mergedParts
        saveInventory()
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
                imageAsset: "engine_part",
                checklist: WorkOrder.standardChecklist
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
                imageAsset: "tire_part",
                checklist: WorkOrder.standardChecklist
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
                status: .completed,
                priority: .critical,
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
                status: .completed,
                priority: .high,
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
                status: .completed,
                priority: .medium,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "Arjun-S",
                imageAsset: "truck_main",
                imagesData: [UIImage(named: "engine_part")?.jpegData(compressionQuality: 0.5) ?? UIColor.systemRed.image().jpegData(compressionQuality: 0.1)!],
                imageAnalyses: ["Analysis: Manifold signature uniform."]
            ),
            TripInspection(
                title: "Hydraulic System Audit",
                vehicleId: "V-902",
                unitName: "JCB 3DX",
                unitVIN: "JCB123456789",
                driverId: "DRV-Suresh",
                timestamp: Date(),
                type: .maintenance,
                vehicleType: .truck,
                status: .pending,
                priority: .high,
                items: [
                    InspectionItem(name: "Brake System", verificationCriteria: "Pad thickness and rotor condition", result: .good, isImageRequired: true),
                    InspectionItem(name: "Tire Condition", verificationCriteria: "Tread depth and pressure", result: .pending, isImageRequired: true),
                    InspectionItem(name: "Fluid Levels", verificationCriteria: "Oil, coolant, and brake fluid", result: .pending, isImageRequired: false)
                ],
                maintenanceStaffId: "Arjun-M",
                imageAsset: "engine_part"
            ),
            TripInspection(
                title: "Chassis Integrity Check",
                vehicleId: "V-903",
                unitName: "JCB 3DX",
                unitVIN: "JCB123456789",
                driverId: "DRV-Suresh",
                timestamp: Date().addingTimeInterval(3600),
                type: .maintenance,
                vehicleType: .truck,
                status: .pending,
                priority: .medium,
                items: TripInspection.mockItems(for: .truck),
                maintenanceStaffId: "Arjun-M"
            )
        ]
    }
    
    func addWorkOrder(_ order: WorkOrder) {
        var normalizedOrder = order
        normalizedOrder.status = autoStatus(for: normalizedOrder)
        workOrders.insert(normalizedOrder, at: 0)
        reconcileInventoryForWorkOrderChange(oldParts: [], newParts: order.consumedParts)
    }
    
    func updateWorkOrder(_ order: WorkOrder) {
        if let index = workOrders.firstIndex(where: { $0.id == order.id }) {
            let oldOrder = workOrders[index]
            let oldStatus = workOrders[index].status
            var normalizedOrder = order
            normalizedOrder.status = autoStatus(for: normalizedOrder)
            workOrders[index] = normalizedOrder
            reconcileInventoryForWorkOrderChange(oldParts: oldOrder.consumedParts, newParts: normalizedOrder.consumedParts)
            
            // If status changed to completed, generate an inspection record for the log
            if oldStatus != .completed && normalizedOrder.status == .completed {
                generateInspectionFromWorkOrder(normalizedOrder)
            }
        }
    }

    func refreshWorkOrderStatuses(referenceDate: Date = Date()) {
        var didChange = false
        for index in workOrders.indices {
            let current = workOrders[index]
            let nextStatus: WorkOrderStatus
            if current.status == .completed {
                nextStatus = .completed
            } else {
                nextStatus = current.scheduledDate <= referenceDate ? .inProgress : .pending
            }

            if current.status != nextStatus {
                workOrders[index].status = nextStatus
                didChange = true
            }
        }

        if didChange {
            objectWillChange.send()
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
            priority: order.priority,
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
        reconcileInventoryForWorkOrderChange(oldParts: order.consumedParts, newParts: [])
        workOrders.removeAll { $0.id == order.id }
    }

    private func reconcileInventoryForWorkOrderChange(oldParts: [WorkOrderPartUsage], newParts: [WorkOrderPartUsage]) {
        var deltaByPartId: [String: Int] = [:]

        for part in oldParts where part.quantity > 0 {
            deltaByPartId[part.inventoryPartId, default: 0] += part.quantity
        }

        for part in newParts where part.quantity > 0 {
            deltaByPartId[part.inventoryPartId, default: 0] -= part.quantity
        }

        guard !deltaByPartId.isEmpty else { return }

        var didUpdateInventory = false
        for (partId, delta) in deltaByPartId where delta != 0 {
            guard let idx = inventoryParts.firstIndex(where: { $0.partId == partId }) else { continue }
            inventoryParts[idx].stockQty = max(0, inventoryParts[idx].stockQty + delta)
            didUpdateInventory = true
        }

        if didUpdateInventory {
            saveInventory()
        }
    }

    private func autoStatus(for order: WorkOrder, referenceDate: Date = Date()) -> WorkOrderStatus {
        if order.status == .completed {
            return .completed
        }
        return order.scheduledDate <= referenceDate ? .inProgress : .pending
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
