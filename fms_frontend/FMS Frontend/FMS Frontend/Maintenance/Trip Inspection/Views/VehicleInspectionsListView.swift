//
//  VehicleInspectionsListView.swift
//  FMS Frontend
//
//  Created by Antigravity on 17/04/26.
//

import SwiftUI

struct VehicleInspectionsListView: View {
    let unitName: String
    let inspections: [TripInspection]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    
    @State private var filter: InspectionFilter = .all
    
    enum InspectionFilter: String, CaseIterable {
        case all = "All"
        case preTrip = "Pre-Trip"
        case postTrip = "Post-Trip"
    }

    private var filteredInspections: [TripInspection] {
        inspections.filter { inspection in
            switch filter {
            case .all: return true
            case .preTrip: return inspection.type == .preTrip
            case .postTrip: return inspection.type == .postTrip
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $filter) {
                ForEach(InspectionFilter.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))

            List {
                ForEach(filteredInspections.sorted(by: { $0.timestamp > $1.timestamp })) { inspection in
                    ZStack {
                        NavigationLink(destination: DetailedInspectionView(inspection: inspection)) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        InspectionTaskCard(inspection: inspection, showUnitName: false)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                store.deleteInspection(inspection)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(.plain)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(unitName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func deleteItems(at offsets: IndexSet) {
        let sorted = inspections.sorted(by: { $0.timestamp > $1.timestamp })
        for index in offsets {
            let inspectionToDelete = sorted[index]
            withAnimation {
                store.deleteInspection(inspectionToDelete)
            }
        }
    }
}
