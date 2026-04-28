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
    @Published var completedWorkOrders: [WorkOrder] = []
    @Published var inspections: [TripInspection] = []
    @Published var inventoryParts: [InventoryPart] = []
    @Published var currentProfile: UserProfile? = nil
    @Published var isLoadingProfile = false
    @Published var profileError: String?
    
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
        self.workOrders = []
        self.completedWorkOrders = []
        self.inspections = []
    }
    
    func addWorkOrder(_ order: WorkOrder) {
        var normalizedOrder = order
        normalizedOrder.status = autoStatus(for: normalizedOrder)
        if let backendId = normalizedOrder.backendId,
           let index = workOrders.firstIndex(where: { $0.backendId == backendId }) {
            workOrders[index] = normalizedOrder
        } else {
            workOrders.insert(normalizedOrder, at: 0)
        }
        reconcileInventoryForWorkOrderChange(oldParts: [], newParts: order.consumedParts)
    }

    @MainActor
    func refreshWorkOrders() async throws {
        // Fetch PROGRESS work orders
        let progressResponse = try await MaintenanceAPI.shared.getWorkOrders(status: "PROGRESS")
        let apiOrders = progressResponse.workOrders.map { WorkOrder(apiItem: $0) }
        
        // Fetch COMPLETED work orders
        let completedResponse = try await MaintenanceAPI.shared.getWorkOrders(status: "COMPLETED")
        let completedApiOrders = completedResponse.workOrders.map { WorkOrder(apiItem: $0) }
        
        let localOnlyOrders = workOrders.filter { $0.backendId == nil }
        workOrders = apiOrders + localOnlyOrders
        completedWorkOrders = completedApiOrders
        refreshWorkOrderStatuses()
    }
    
    func updateWorkOrder(_ order: WorkOrder) {
        if let index = workOrders.firstIndex(where: { $0.id == order.id }) {
            let oldOrder = workOrders[index]
            let oldStatus = workOrders[index].status
            var normalizedOrder = order
            normalizedOrder.status = autoStatus(for: normalizedOrder)
            workOrders[index] = normalizedOrder
            reconcileInventoryForWorkOrderChange(oldParts: oldOrder.consumedParts, newParts: normalizedOrder.consumedParts)
            
            // If status changed to completed, append to completedWorkOrders
            if oldStatus != .completed && normalizedOrder.status == .completed {
                completedWorkOrders.insert(normalizedOrder, at: 0)
                Task {
                    try? await refreshInspections()
                }
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
                nextStatus = .progress
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
    
    @MainActor
    func refreshInspections() async throws {
        let response = try await MaintenanceAPI.shared.getInspections()
        self.inspections = response.inspections.map { TripInspection(apiItem: $0) }
    }
    
    func addInspection(_ inspection: TripInspection) {
        inspections.insert(inspection, at: 0)
        // Add POST API call here if needed
    }
    
    func updateInspection(_ inspection: TripInspection) {
        if let index = inspections.firstIndex(where: { $0.id == inspection.id }) {
            inspections[index] = inspection
            
            if let backendId = inspection.backendId {
                Task {
                    let request = UpdateInspectionRequest(
                        notes: inspection.technicianNotes,
                        items: inspection.items,
                        reportUrl: nil
                    )
                    _ = try? await MaintenanceAPI.shared.updateInspection(id: backendId, request: request)
                }
            }
        }
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
        return .progress
    }

    func deleteInspection(_ inspection: TripInspection) {
        inspections.removeAll { $0.id == inspection.id }
    }



    func updateInspectionAnalysis(id: UUID, index: Int, analysis: String) {
        if let idx = inspections.firstIndex(where: { $0.id == id }) {
            if index < inspections[idx].imageAnalyses.count {
                inspections[idx].imageAnalyses[index] = analysis
            }
        }
    }
    
    // MARK: - Profile
    func loadProfile() async {
        isLoadingProfile = true
        profileError = nil
        
        do {
            let response = try await AuthAPI.shared.getProfile()
            await MainActor.run {
                self.currentProfile = UserProfile(
                    id: response.profile.id,
                    name: response.profile.name,
                    username: response.profile.username,
                    phone: response.profile.phone,
                    email: response.profile.email,
                    role: response.profile.role,
                    createdAt: response.profile.createdAt,
                    updatedAt: response.profile.updatedAt,
                    address: response.profile.address,
                    licenceNumber: response.profile.licenceNumber,
                    expiryDate: response.profile.expiryDate,
                    classes: response.profile.classes
                )
                self.isLoadingProfile = false
            }
        } catch {
            await MainActor.run {
                self.profileError = "Failed to load profile"
                self.isLoadingProfile = false
            }
        }
    }
    
    func logout() {
        AuthAPI.shared.logout()
        currentProfile = nil
    }
}
