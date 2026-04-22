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
        case all      = "All"
        case critical = "Critical"
        case high     = "High"
        case medium   = "Medium"
        case low      = "Low"
        var id: String { rawValue }
    }

    private var filteredOrders: [WorkOrder] {
        let nonCompleted = store.workOrders
            .filter { $0.status != .completed }
            .sorted { $0.priority.sortingOrder < $1.priority.sortingOrder }

        switch selectedFilter {
        case .all:      return nonCompleted
        case .critical: return nonCompleted.filter { $0.priority == .critical }
        case .high:     return nonCompleted.filter { $0.priority == .high }
        case .medium:   return nonCompleted.filter { $0.priority == .medium }
        case .low:      return nonCompleted.filter { $0.priority == .low }
        }
    }

    private func priorityColor(for priority: WorkOrderPriority) -> Color {
        switch priority {
        case .critical: return .red
        case .high:     return .orange
        case .medium:   return .blue
        case .low:      return .green
        }
    }

    private func priorityIcon(for priority: WorkOrderPriority) -> String {
        switch priority {
        case .critical: return "exclamationmark.triangle.fill"
        case .high:     return "flame.fill"
        case .medium:   return "wrench.and.screwdriver.fill"
        case .low:      return "checkmark.circle.fill"
        }
    }

    var body: some View {
        List {

            // Alerts List
            Section {
                if filteredOrders.isEmpty {
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
                    ForEach(filteredOrders) { order in
                        NavigationLink(destination: WorkOrderDetailsView(workOrder: order)) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(priorityColor(for: order.priority).opacity(0.12))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: priorityIcon(for: order.priority))
                                        .font(.system(size: 16))
                                        .foregroundColor(priorityColor(for: order.priority))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(order.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.primaryText)
                                    Text("\(order.vehicleName) • Priority: \(order.priority.rawValue.capitalized)")
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
