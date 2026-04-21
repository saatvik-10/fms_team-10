//
//  WorkOrderManagementView.swift
//  FMS Frontend
//

import SwiftUI

struct WorkOrderManagementView: View {
    @EnvironmentObject var store: MaintenanceStore
    @StateObject private var viewModel: WorkOrdersViewModel
    @State private var showingCreateModal = false
    
    init(maintenanceStore: MaintenanceStore) {
        _viewModel = StateObject(wrappedValue: WorkOrdersViewModel(store: maintenanceStore))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Status", selection: $viewModel.selectedStatus) {
                Text("Pending").tag(WorkOrderStatus.pending as WorkOrderStatus?)
                Text("In Progress").tag(WorkOrderStatus.inProgress as WorkOrderStatus?)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 16)
            .background(Color(.systemGroupedBackground))
            
            // Work Orders List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.filteredWorkOrders) { order in
                        NavigationLink(destination: WorkOrderDetailsView(workOrder: order)) {
                            WorkOrderTaskCard(order: order)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    viewModel.deleteOrder(order)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    if viewModel.filteredWorkOrders.isEmpty {
                        EmptyStateView(
                            icon: "wrench.and.screwdriver",
                            title: "No \(viewModel.selectedStatus?.rawValue ?? "") Orders",
                            message: "Try searching for a vehicle or adjusting filters."
                        )
                        .padding(.top, 60)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Work Orders")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "Search by Task, Vehicle, or ID")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Menu {
                        Section("Priority") {
                            Button("All Priorities") { viewModel.selectedPriority = nil }
                            ForEach(WorkOrderPriority.allCases, id: \.self) { priority in
                                Button(priority.rawValue) { viewModel.selectedPriority = priority }
                            }
                        }
                        
                        Section("Service Type") {
                            Button("All Types") { viewModel.selectedServiceType = nil }
                            let types = Array(Set(store.workOrders.map { $0.serviceType })).sorted()
                            ForEach(types, id: \.self) { type in
                                Button(type) { viewModel.selectedServiceType = type }
                            }
                        }
                    } label: {
                        Image(systemName: (viewModel.selectedPriority != nil || viewModel.selectedServiceType != nil) ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.primary)
                    }

                    Button(action: { showingCreateModal = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateModal) {
            CreateWorkOrderModal()
        }
    }
}
