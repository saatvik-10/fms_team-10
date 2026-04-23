//
//  FullInventoryListView.swift
//  FMS Frontend
//
//  Created by Antigravity on 26/04/24.
//

import SwiftUI

struct FullInventoryListView: View {
    @EnvironmentObject var store: MaintenanceStore
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    var categories: [String] {
        Array(Set(store.inventoryParts.map { $0.category })).sorted()
    }
    
    var filteredParts: [InventoryPart] {
        store.inventoryParts.filter { part in
            let matchesSearch = searchText.isEmpty || 
                               part.partName.localizedCaseInsensitiveContains(searchText) || 
                               part.partId.localizedCaseInsensitiveContains(searchText) ||
                               part.category.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || part.category == selectedCategory
            
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        List {
            if filteredParts.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("No items match your search")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(filteredParts) { part in
                        NavigationLink(destination: InventoryDetailView(part: part)) {
                            InventoryRow(part: part)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Global Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search SKUs or category")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { selectedCategory = nil }) {
                        Label("All Categories", systemImage: selectedCategory == nil ? "checkmark" : "")
                    }
                    
                    Divider()
                    
                    ForEach(categories, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Label(category, systemImage: selectedCategory == category ? "checkmark" : "")
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}
