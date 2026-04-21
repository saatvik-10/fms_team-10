//
//  InventoryManagementView.swift
//  FMS Frontend
//

import SwiftUI

struct InventoryManagementView: View {
    @EnvironmentObject var store: MaintenanceStore
    @State private var searchText = ""
    
    var filteredItems: [InventoryItem] {
        if searchText.isEmpty { return store.inventory }
        return store.inventory.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.category.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search inventory SKU, name...", text: $searchText)
                    .font(.system(size: 16))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 16)
            .background(Color(.systemGroupedBackground))

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredItems) { item in
                        HStack(spacing: 16) {
                            // Icon/Asset
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(item.currentQuantity <= item.minThreshold ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Image(systemName: item.imageAsset ?? "shippingbox.fill")
                                    .foregroundColor(item.currentQuantity <= item.minThreshold ? .red : .blue)
                                    .font(.system(size: 20))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.system(size: 16, weight: .bold))
                                Text("SKU: \(item.sku) • \(item.category)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(item.currentQuantity)")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(item.currentQuantity <= item.minThreshold ? .red : .primary)
                                Text("units")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        .overlay(
                            item.currentQuantity <= item.minThreshold ?
                            RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.3), lineWidth: 1) : nil
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.inline)
    }
}
