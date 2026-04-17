//
//  TripInspectionView.swift
//  FMS Frontend
//

import SwiftUI

struct TripInspectionView: View {
    @EnvironmentObject var store: MaintenanceStore
    @State private var showingCreateModal = false
    @State private var isGridView = true

    // Group inspections by vehicle unit
    private var vehicleGroups: [String: [TripInspection]] {
        Dictionary(grouping: store.inspections, by: { $0.unitName })
    }

    private var sortedUnitNames: [String] {
        vehicleGroups.keys.sorted()
    }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        Group {
            if isGridView {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(sortedUnitNames, id: \.self) { unitName in
                            let inspections = vehicleGroups[unitName] ?? []
                            NavigationLink(
                                destination: VehicleInspectionsListView(
                                    unitName: unitName,
                                    inspections: inspections
                                )
                            ) {
                                VehicleFolderTile(unitName: unitName, count: inspections.count)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu { folderContextMenu(for: unitName) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            } else {
                List {
                    ForEach(sortedUnitNames, id: \.self) { unitName in
                        let inspections = vehicleGroups[unitName] ?? []
                        NavigationLink(
                            destination: VehicleInspectionsListView(
                                unitName: unitName,
                                inspections: inspections
                            )
                        ) {
                            VehicleFolderListRow(unitName: unitName, count: inspections.count)
                        }
                        .contextMenu { folderContextMenu(for: unitName) }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                store.deleteInspections(forUnit: unitName)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Inspections")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    Button(action: { isGridView.toggle() }) {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                            .font(.system(size: 20))
                    }
                    Button(action: { showingCreateModal = true }) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 20))
                    }
                    NavigationLink(destination: MaintenanceProfileView(isLoggedIn: .constant(true))) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateModal) {
            CreateInspectionModal(isEmergency: false)
        }
    }
    
    @ViewBuilder
    private func folderContextMenu(for unitName: String) -> some View {
        Button {
            // Edit placeholder action
        } label: {
            Label("Edit Folder", systemImage: "pencil")
        }
        Button(role: .destructive) {
            store.deleteInspections(forUnit: unitName)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Grid Tile
struct VehicleFolderTile: View {
    let unitName: String
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Folder icon
            Image(systemName: "folder.fill")
                .font(.system(size: 40))
                .foregroundColor(AppColors.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            // Unit name
            Text(unitName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Count badge
            Text("\(count) inspection\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}

// MARK: - List Row
struct VehicleFolderListRow: View {
    let unitName: String
    let count: Int

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "folder.fill")
                .font(.system(size: 28))
                .foregroundColor(AppColors.primary)
                
            VStack(alignment: .leading, spacing: 4) {
                Text(unitName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(count) inspection\(count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
