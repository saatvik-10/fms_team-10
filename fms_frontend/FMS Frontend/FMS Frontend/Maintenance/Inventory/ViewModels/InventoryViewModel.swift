//
//  InventoryViewModel.swift
//  FMS Frontend
//

import SwiftUI
import Combine

class InventoryViewModel: ObservableObject {
    private var store: MaintenanceStore
    @Published var filteredInventory: [InventoryItem] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: String? = nil
    
    var categories: [String] {
        Array(Set(store.inventory.map { $0.category })).sorted()
    }
    
    var totalValue: Double {
        store.inventory.reduce(0) { $0 + ($1.unitCost * Double($1.currentQuantity)) }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(store: MaintenanceStore) {
        self.store = store
        
        store.$inventory
            .sink { [weak self] _ in
                self?.filterInventory()
            }
            .store(in: &cancellables)
            
        Publishers.CombineLatest($searchText, $selectedCategory)
            .sink { [weak self] _ in
                self?.filterInventory()
            }
            .store(in: &cancellables)
    }
    
    func filterInventory() {
        var items = store.inventory
        
        if !searchText.isEmpty {
            items = items.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.sku.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        self.filteredInventory = items.sorted { $0.name < $1.name }
    }
}
