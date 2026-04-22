//
//  WorkOrdersViewModel.swift
//  FMS Frontend
//

import SwiftUI
import Combine

class WorkOrdersViewModel: ObservableObject {
    private var store: MaintenanceStore
    @Published var filteredWorkOrders: [WorkOrder] = []
    @Published var searchText: String = ""
    @Published var selectedStatus: WorkOrderStatus? = .pending
    @Published var selectedPriority: WorkOrderPriority? = nil
    @Published var selectedServiceType: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init(store: MaintenanceStore) {
        self.store = store
        
        // Sink to store changes
        store.$workOrders
            .sink { [weak self] _ in
                self?.filterOrders()
            }
            .store(in: &cancellables)
            
        // Sink to search/filter changes
        Publishers.CombineLatest4($searchText, $selectedStatus, $selectedPriority, $selectedServiceType)
            .sink { [weak self] _ in
                self?.filterOrders()
            }
            .store(in: &cancellables)
    }
    
    func filterOrders() {
        var orders = store.workOrders
        
        if !searchText.isEmpty {
            orders = orders.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) || 
                $0.vehicleName.localizedCaseInsensitiveContains(searchText) ||
                $0.orderID.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let status = selectedStatus {
            orders = orders.filter { $0.status == status }
        }
        
        if let priority = selectedPriority {
            orders = orders.filter { $0.priority == priority }
        }
        
        if let type = selectedServiceType {
            orders = orders.filter { $0.serviceType == type }
        }
        
        // Sorting: Critical first, then by date
        self.filteredWorkOrders = orders.sorted {
            if $0.priority == .critical && $1.priority != .critical { return true }
            if $0.priority != .critical && $1.priority == .critical { return false }
            return $0.scheduledDate > $1.scheduledDate
        }
    }
    
    func deleteOrder(_ order: WorkOrder) {
        store.deleteWorkOrder(order)
    }
}
