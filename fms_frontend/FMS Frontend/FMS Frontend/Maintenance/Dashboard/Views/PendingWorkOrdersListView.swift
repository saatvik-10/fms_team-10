//
//  PendingWorkOrdersListView.swift
//  FMS Frontend
//
//  Dashboard-only detail screen listing all pending work orders.
//  Filter via bar button item (action sheet).
//

import SwiftUI

struct PendingWorkOrdersListView: View {
    @EnvironmentObject var store: MaintenanceStore
    @State private var showingFilter = false
    @State private var selectedFilter: PriorityFilter = .all

    enum PriorityFilter: String, CaseIterable, Identifiable {
        case all      = "All"
        case high     = "High"
        case medium   = "Medium"
        case low      = "Low"
        var id: String { rawValue }
    }

    private var filteredOrders: [WorkOrder] {
        let pending = store.workOrders
            .filter { $0.status != .completed }
            .sorted { $0.priority.sortingOrder < $1.priority.sortingOrder }

        switch selectedFilter {
        case .all:    return pending
        case .high:   return pending.filter { $0.priority == .high }
        case .medium: return pending.filter { $0.priority == .medium }
        case .low:    return pending.filter { $0.priority == .low }
        }
    }

    private func priorityColor(for priority: WorkOrderPriority) -> Color {
        switch priority {
        case .high:   return .orange
        case .medium: return .blue
        case .low:    return .green
        }
    }

    var body: some View {
        List {
            if filteredOrders.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green.opacity(0.5))
                        Text("No pending work orders")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
            } else {
                ForEach(filteredOrders) { order in
                    NavigationLink(destination: WorkOrderDetailsView(workOrder: order)) {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(priorityColor(for: order.priority))
                                .frame(width: 4, height: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(order.title)
                                    .font(.system(size: 16, weight: .semibold))
                                Text("\(order.vehicleName) • \(order.priority.rawValue.capitalized)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(order.status.rawValue.capitalized)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Pending Orders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(PriorityFilter.allCases) { filter in
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
