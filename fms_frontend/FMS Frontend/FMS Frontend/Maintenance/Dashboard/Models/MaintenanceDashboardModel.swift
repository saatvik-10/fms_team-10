//
//  MaintenanceDashboardModel.swift
//  FMS Frontend
//

import Foundation

// MARK: - Dashboard Hub Config
struct MaintenanceDashboardModel {
    static let hubTitle = "Maintenance Hub"
}

// MARK: - Priority Feed Item
/// A high-priority work order shown in the Priority Feed section.
struct PriorityFeedItem: Identifiable {
    let id: UUID
    let title: String
    let vehicleName: String
    let priority: WorkOrderPriority
}

// MARK: - Low Stock Part
/// A part whose inventory is at or below the minimum threshold.
struct LowStockPart: Identifiable {
    let id          = UUID()
    let name        : String
    let partNumber  : String
    let currentStock: Int
    let minimumStock: Int
    let unit        : String     // e.g. "units", "liters", "rolls"

    var stockPercent: Double {
        guard minimumStock > 0 else { return 0 }
        return Double(currentStock) / Double(minimumStock)
    }

    enum StockLevel { case outOfStock, critical, low }

    var stockLevel: StockLevel {
        if currentStock == 0            { return .outOfStock }
        if stockPercent <= 0.3          { return .critical   }
        return .low
    }

    var statusLabel: String {
        switch stockLevel {
        case .outOfStock: return "OUT OF STOCK"
        case .critical:   return "CRITICAL"
        case .low:        return "LOW STOCK"
        }
    }
}

// MARK: - Active Staff Item
/// Represents a technician currently assigned to an In Progress task.
struct ActiveStaffItem: Identifiable {
    let id = UUID()
    let technicianId: String
    let taskTitle: String
    let vehicleName: String
}
