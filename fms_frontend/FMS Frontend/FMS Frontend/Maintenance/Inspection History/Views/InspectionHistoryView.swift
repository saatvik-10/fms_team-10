//
//  InspectionHistoryView.swift
//  FMS Frontend
//

import SwiftUI

struct InspectionHistoryView: View {
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var store: MaintenanceStore
    @StateObject private var viewModel: InspectionHistoryViewModel
    @State private var layoutMode: LayoutMode = .folders
    
    enum LayoutMode {
        case folders
        case list
    }
    
    init(isLoggedIn: Binding<Bool>, maintenanceStore: MaintenanceStore) {
        self._isLoggedIn = isLoggedIn
        _viewModel = StateObject(wrappedValue: InspectionHistoryViewModel(store: maintenanceStore))
    }
    
    var body: some View {
        ScrollView {
            if layoutMode == .folders {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(viewModel.groupedInspections.keys.sorted(), id: \.self) { unitName in
                        NavigationLink(destination: VehicleInspectionsListView(unitName: unitName)) {
                            VStack(alignment: .leading, spacing: 16) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppColors.primary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(unitName)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                            
                                    let count = viewModel.groupedInspections[unitName]?.count ?? 0
                                    Text("\(count) inspection\(count == 1 ? "" : "s")")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    store.deleteInspections(forUnit: unitName)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.groupedInspections.keys.sorted(), id: \.self) { unitName in
                        NavigationLink(destination: VehicleInspectionsListView(unitName: unitName)) {
                            HStack(spacing: 16) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.primary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(unitName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    let count = viewModel.groupedInspections[unitName]?.count ?? 0
                                    Text("\(count) items")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.3))
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.03), radius: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    store.deleteInspections(forUnit: unitName)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Inspections")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            layoutMode = layoutMode == .folders ? .list : .folders
                        }
                    }) {
                        Image(systemName: layoutMode == .folders ? "list.bullet" : "square.grid.2x2")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.primary)
                    }

                    NavigationLink(destination: MaintenanceProfileView(isLoggedIn: $isLoggedIn)) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
    }
}
