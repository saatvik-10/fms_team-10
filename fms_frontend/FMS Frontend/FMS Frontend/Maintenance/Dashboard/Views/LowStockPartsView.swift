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

    private var filteredParts: [InventoryPart] {
        store.inventoryParts.filter { $0.isLowStock }
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
                            Text(part.partName)
                                .font(.headline)
                                .foregroundColor(AppColors.primaryText)
                            Text(part.partId)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(part.stockQty)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(part.isLowStock ? .orange : AppColors.primaryText)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Restock Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
