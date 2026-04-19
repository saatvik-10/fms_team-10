//
//  WorkOrderManagementView.swift
//  FMS Frontend
//

import SwiftUI

// MARK: - Filter Model
struct WorkOrderFilter {
    var vehicleType: String = "All"
    var vehicleModel: String = "All"
    var severity: String = "All"
    var progress: String = "All"
}

// MARK: - Main View
struct WorkOrderManagementView: View {
    @EnvironmentObject var store: MaintenanceStore
    @State private var showingCreateModal = false
    @State private var showingFilter = false
    @State private var filter = WorkOrderFilter()

    private var filteredOrders: [WorkOrder] {
        store.workOrders.filter { order in
            let matchesSeverity = filter.severity == "All" || order.priority.rawValue == filter.severity
            let matchesProgress = filter.progress == "All" || order.status.rawValue == filter.progress
            let matchesModel = filter.vehicleModel == "All" || order.vehicleName.contains(filter.vehicleModel)
            return matchesSeverity && matchesProgress && matchesModel
        }
        .sorted { $0.priority.sortingOrder < $1.priority.sortingOrder }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(filteredOrders) { order in
                    NavigationLink(destination: WorkOrderDetailsView(workOrder: order)) {
                        WorkOrderTaskCard(order: order)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                store.deleteWorkOrder(order)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                if filteredOrders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("No Work Orders")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Adjust your filters or add a new work order.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Work Orders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    Button(action: { showingFilter = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                    }
                    Button(action: { showingCreateModal = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateModal) {
            CreateWorkOrderModal()
        }
        .sheet(isPresented: $showingFilter) {
            WorkOrderFilterSheet(filter: $filter)
        }
    }
}

// MARK: - Filter Sheet
struct WorkOrderFilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var filter: WorkOrderFilter

    let vehicleTypes  = ["All", "Truck", "Bus", "Van", "SUV", "Pickup"]
    let vehicleModels = ["All", "Mercedes-Benz Actros", "Volvo FH16", "MAN TGX",
                         "Toyota Coaster", "Tata Starbus", "Ford Transit",
                         "Mercedes-Benz Sprinter", "Toyota HiAce", "Toyota Land Cruiser", "Ford Ranger"]
    let severities    = ["All", "Critical", "High", "Medium", "Low"]
    let progressList  = ["All", "Pending", "In Progress", "Completed"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle Type") {
                    Picker("Type", selection: $filter.vehicleType) {
                        ForEach(vehicleTypes, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }

                Section("Vehicle Model") {
                    Picker("Model", selection: $filter.vehicleModel) {
                        ForEach(vehicleModels, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }

                Section("Severity") {
                    Picker("Severity", selection: $filter.severity) {
                        ForEach(severities, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Progress") {
                    Picker("Progress", selection: $filter.progress) {
                        ForEach(progressList, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button("Reset Filters", role: .destructive) {
                        filter = WorkOrderFilter()
                    }
                }
            }
            .navigationTitle("Filter Work Orders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "checkmark")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
    }
}
