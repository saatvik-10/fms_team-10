//
//  LowStockPartsView.swift
//  FMS Frontend
//
//  Dashboard-only detail screen listing all low stock / restock alert parts.
//  Filter via bar button item (Menu).
//

import SwiftUI

struct LowStockPartsView: View {
    @EnvironmentObject var store: MaintenanceStore
    @State private var selectedFilter: StockFilter = .lowOnly

    enum StockFilter: String, CaseIterable, Identifiable {
        case lowOnly  = "Low Stock Only"
        case all      = "All Parts"
        var id: String { rawValue }
    }

    private var filteredParts: [InventoryPart] {
        switch selectedFilter {
        case .lowOnly: return store.inventoryParts.filter { $0.isLowStock }
        case .all:     return store.inventoryParts
        }
    }

    var body: some View {
        List {
            if filteredParts.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green.opacity(0.5))
                        Text("All parts are sufficiently stocked.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
            } else {
                ForEach(filteredParts) { part in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(part.name)
                                .font(.headline)
                            Text(part.sku)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Stock: \(part.stockCount)")
                                .font(.subheadline.bold())
                                .foregroundColor(part.isLowStock ? .orange : AppColors.primaryText)
                            Text("Min: \(part.reorderThreshold)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Restock Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(StockFilter.allCases) { filter in
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
                        .foregroundColor(selectedFilter != .lowOnly ? AppColors.primary : .secondary)
                }
            }
        }
    }
}
