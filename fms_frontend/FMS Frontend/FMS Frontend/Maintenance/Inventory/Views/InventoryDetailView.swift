//
//  InventoryDetailView.swift
//  FMS Frontend
//
//  Created by Antigravity on 26/04/24.
//

import SwiftUI

struct InventoryDetailView: View {
    let part: InventoryPart
    @EnvironmentObject var store: MaintenanceStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section {
                headerView
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            Section("Stock Status") {
                detailRow(title: "Current Stock", value: "\(part.stockQty) units", color: part.isLowStock ? .orange : .primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Reorder Threshold")
                            .font(.subheadline)
                        Spacer()
                        Text("\(part.minStock)")
                            .fontWeight(.bold)
                    }
                    
                    Stepper("Adjust Threshold", value: Binding(
                        get: { part.minStock },
                        set: { store.updateInventoryThreshold(for: part.partId, newThreshold: $0) }
                    ), in: 0...1000)
                    .labelsHidden()
                }
                
                detailRow(title: "Stock Status", value: part.isLowStock ? "LOW STOCK" : "OPTIMAL", color: part.isLowStock ? .orange : .green)
            }
            
            Section("Financials") {
                detailRow(title: "Unit Price", value: "₹\(part.unitPriceInr, default: "%.2f")")
                detailRow(title: "Total Valuation", value: "₹\(part.totalValue, default: "%.2f")", color: AppColors.primary)
            }
            
            Section("Supply & Logistics") {
                detailRow(title: "Supplier", value: part.supplier)
                detailRow(title: "Location", value: part.location)
                detailRow(title: "Vehicle Compatibility", value: part.vehicleType)
            }
            
            Section("Identification") {
                detailRow(title: "SKU / Part ID", value: part.partId)
                detailRow(title: "Category", value: part.category)
            }
        }
        .navigationTitle(part.partName)
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: categoryIcon(for: part.category))
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(spacing: 4) {
                Text(part.partName)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                Text(part.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private func detailRow(title: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        let cat = category.lowercased()
        if cat.contains("tire") { return "circle.dotted" }
        if cat.contains("engine") || cat.contains("motor") { return "engine.combustion.fill" }
        if cat.contains("brake") { return "slowmo" }
        if cat.contains("fluid") || cat.contains("oil") { return "drop.fill" }
        if cat.contains("elect") || cat.contains("battery") { return "bolt.fill" }
        return "gearshape.fill"
    }
}
