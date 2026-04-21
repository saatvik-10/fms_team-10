//
//  VehicleInspectionsListView.swift
//  FMS Frontend
//
//  Created by Antigravity on 17/04/26.
//

import SwiftUI

struct VehicleInspectionsListView: View {
    let unitName: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    
    private var inspections: [TripInspection] {
        store.inspections.filter { $0.unitName == unitName }
    }
    
    @State private var filter: InspectionFilter = .all
    
    enum InspectionFilter: String, CaseIterable {
        case all = "All"
        case preTrip = "Pre-Trip"
        case postTrip = "Post-Trip"
        case maintenance = "Maintenance"
    }

    private var filteredInspections: [TripInspection] {
        inspections.filter { inspection in
            switch filter {
            case .all: return true
            case .preTrip: return inspection.type == .preTrip
            case .postTrip: return inspection.type == .postTrip
            case .maintenance: return inspection.type == .maintenance
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {

            List {
                if filteredInspections.isEmpty {
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "No \(filter.rawValue) Audits",
                        message: "There are no inspection records matching this criteria."
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.top, 60)
                } else {
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
            }
            .listStyle(.plain)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(unitName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Filter", selection: $filter) {
                        ForEach(InspectionFilter.allCases, id: \.self) { Text($0.rawValue) }
                    }
                } label: {
                    Image(systemName: filter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        let sorted = filteredInspections.sorted(by: { $0.timestamp > $1.timestamp })
        for index in offsets {
            let inspectionToDelete = sorted[index]
            withAnimation {
                store.deleteInspection(inspectionToDelete)
            }
        }
    }
}
