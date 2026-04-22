//
//  MaintenanceDashboardViewModel.swift
//  FMS Frontend
//

import Combine
import SwiftUI

class MaintenanceDashboardViewModel: ObservableObject {

    // MARK: - System Status KPIs
    @Published var criticalAlertsCount: Int = 0
    @Published var pendingOrdersCount: Int  = 0
    @Published var lowStockPartsCount: Int  = 0

    // MARK: - Priority Feed (top 3 non-completed work orders by priority)
    @Published var topCriticalWorkOrders: [PriorityFeedItem] = []

    // MARK: - Compliance Score
    @Published var complianceScore: Int         = 0
    @Published var completedInspectionsToday: Int = 0
    @Published var totalInspectionsToday: Int   = 0

    // MARK: - Active Staff (technicians on In Progress tasks)
    @Published var activeStaff: [ActiveStaffItem] = []

    // MARK: - Public Refresh Entry Point
    /// Called by the View via `onReceive` whenever `MaintenanceStore` publishes changes.
    func refresh(workOrders: [WorkOrder], inspections: [TripInspection], lowStock: Int = 0) {
        computeSystemStatus(workOrders: workOrders, inspections: inspections)
        computePriorityFeed(workOrders: workOrders)
        computeComplianceScore(inspections: inspections)
        computeActiveStaff(workOrders: workOrders)
        lowStockPartsCount = lowStock
    }

    // MARK: - Private Computations

    private func computeSystemStatus(workOrders: [WorkOrder], inspections: [TripInspection]) {
        let criticalWOs         = workOrders.filter   { $0.priority == .critical && $0.status != .completed }.count
        let emergencyPending    = inspections.filter  { $0.isEmergency && $0.status == .pending }.count
        criticalAlertsCount     = criticalWOs + emergencyPending
        pendingOrdersCount      = workOrders.filter { $0.status == .pending }.count
    }

    private func computePriorityFeed(workOrders: [WorkOrder]) {
        let sorted = workOrders
            .filter { $0.status != .completed }
            .sorted { $0.priority.sortingOrder < $1.priority.sortingOrder }
        topCriticalWorkOrders = sorted.prefix(3).map {
            PriorityFeedItem(id: $0.id, title: $0.title, vehicleName: $0.vehicleName, priority: $0.priority)
        }
    }

    private func computeComplianceScore(inspections: [TripInspection]) {
        let calendar       = Calendar.current
        let todayItems     = inspections.filter { calendar.isDateInToday($0.timestamp) }
        let sourceItems    = todayItems.isEmpty ? inspections : todayItems   // fallback to all if none today

        let total          = sourceItems.count
        let completed      = sourceItems.filter { $0.status == .completed }.count

        totalInspectionsToday     = total
        completedInspectionsToday = completed
        complianceScore           = total == 0 ? 100 : Int((Double(completed) / Double(total)) * 100)
    }

    private func computeActiveStaff(workOrders: [WorkOrder]) {
        activeStaff = workOrders
            .filter { $0.status == .inProgress }
            .map { ActiveStaffItem(technicianId: $0.technicianId, taskTitle: $0.title, vehicleName: $0.vehicleName) }
    }
}
