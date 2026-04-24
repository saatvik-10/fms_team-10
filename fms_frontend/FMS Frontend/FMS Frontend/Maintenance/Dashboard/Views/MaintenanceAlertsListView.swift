//
//  MaintenanceAlertsListView.swift
//  FMS Frontend
//
//  Dashboard-only detail screen for all Maintenance Alerts.
//  NOT a tab-level screen – accessible only via Dashboard chevron.
//

import SwiftUI

struct MaintenanceAlertsListView: View {
    @EnvironmentObject var store: MaintenanceStore

    @State private var selectedFilter: AlertFilter = .all

    enum AlertFilter: String, CaseIterable, Identifiable {
        case all       = "All"
        case workOrders = "Work Orders"
        case inventory = "Inventory"
        var id: String { rawValue }
    }

    private var allAlerts: [DashboardAlertItem] {
        let workOrderAlerts = store.workOrders
            .filter { $0.status != .completed }
            .map { order in
                DashboardAlertItem(
                    id: "wo-\(order.id.uuidString)",
                    source: .workOrder,
                    title: order.title,
                    subtitle: "\(order.vehicleName) • Priority: \(order.priority.rawValue.capitalized)",
                    sortOrder: order.priority.sortingOrder,
                    workOrderId: order.id,
                    inventoryPartId: nil
                )
            }

        let inventoryAlerts = store.inventoryParts
            .filter { $0.isLowStock }
            .map { part in
                DashboardAlertItem(
                    id: "inv-\(part.partId)",
                    source: .inventory,
                    title: part.partName,
                    subtitle: "\(part.partId) • Stock: \(part.stockQty)/\(part.minStock)",
                    sortOrder: 0,
                    workOrderId: nil,
                    inventoryPartId: part.partId
                )
            }

        return (workOrderAlerts + inventoryAlerts)
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    private var filteredAlerts: [DashboardAlertItem] {
        switch selectedFilter {
        case .all:
            return allAlerts
        case .workOrders:
            return allAlerts.filter { $0.source == .workOrder }
        case .inventory:
            return allAlerts.filter { $0.source == .inventory }
        }
    }

    private let alertIconName = "exclamationmark.triangle.fill"
    private let alertIconColor: Color = .red

    var body: some View {
        List {

            // Alerts List
            Section {
                if filteredAlerts.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.green.opacity(0.5))
                            Text("No alerts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                } else {
                    ForEach(filteredAlerts) { alert in
                        let matchingWorkOrder = alert.workOrderId.flatMap { workOrderId in
                            store.workOrders.first { $0.id == workOrderId }
                        }
                        let matchingInventoryPart = alert.inventoryPartId.flatMap { partId in
                            store.inventoryParts.first { $0.partId == partId }
                        }
                        NavigationLink(destination: Group {
                            if let order = matchingWorkOrder {
                                WorkOrderDetailsView(workOrder: order)
                            } else if let part = matchingInventoryPart {
                                InventoryDetailView(part: part)
                            } else {
                                EmptyView()
                            }
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(alertIconColor.opacity(0.12))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: alertIconName)
                                        .font(.system(size: 16))
                                        .foregroundColor(alertIconColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(alert.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.primaryText)
                                    Text(alert.subtitle)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Maintenance Alert")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(AlertFilter.allCases) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 18))
                        .foregroundColor(selectedFilter != .all ? AppColors.primary : .secondary)
                }
            }
        }
    }
}
