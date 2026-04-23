//
//  InspectionHistoryViewModel.swift
//  FMS Frontend
//

import SwiftUI
import Combine

class InspectionHistoryViewModel: ObservableObject {
    private var store: MaintenanceStore
    @Published var groupedInspections: [String: [TripInspection]] = [:]
    @Published var searchText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(store: MaintenanceStore) {
        self.store = store
        
        store.$inspections
            .sink { [weak self] inspections in
                self?.groupInspections(inspections)
            }
            .store(in: &cancellables)
            
        $searchText
            .sink { [weak self] _ in
                self?.groupInspections(self?.store.inspections ?? [])
            }
            .store(in: &cancellables)
    }
    
    private func groupInspections(_ inspections: [TripInspection]) {
        var filtered = inspections
        if !searchText.isEmpty {
            filtered = inspections.filter { 
                $0.unitName.localizedCaseInsensitiveContains(searchText) ||
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        self.groupedInspections = Dictionary(grouping: filtered, by: { $0.unitName })
    }
}
