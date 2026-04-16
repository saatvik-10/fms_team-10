//
//  InventoryViewModel.swift
//  FMS Frontend
//

import SwiftUI
import Combine

class InventoryViewModel: ObservableObject {
    @Published var items: [InventoryItem] = InventoryItem.mockItems
    @Published var searchText: String = ""
    @Published var selectedCategory: InventoryCategory? = nil
    
    var filteredItems: [InventoryItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            return matchesSearch && matchesCategory
        }
        .sorted { $0.isLowStock && !$1.isLowStock } // Show low stock first
    }
    
    var lowStockCount: Int {
        items.filter { $0.isLowStock }.count
    }
    
    func updateQuantity(for itemId: UUID, by amount: Int) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            let newQuantity = max(0, items[index].quantity + amount)
            items[index].quantity = newQuantity
        }
    }
}
