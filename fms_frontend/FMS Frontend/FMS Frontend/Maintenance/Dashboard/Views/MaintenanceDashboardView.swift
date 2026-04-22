//
//  MaintenanceDashboardView.swift
//  FMS Frontend
//
//  Tab 1 – Dashboard
//  Displays aggregated KPIs, Priority Feed, Compliance Score, and Active Staff.
//

import SwiftUI

struct MaintenanceDashboardView: View {
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var store: MaintenanceStore
    @StateObject private var viewModel = MaintenanceDashboardViewModel()

    @State private var showingCreateInspection   = false
    @State private var showingEmergencyInspection = false
    @State private var showingCreateWorkOrder    = false
    @State private var showingUpdateInventory    = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Section 1: System Status KPIs ──────────────────────────
                systemStatusSection
                    .padding(.top, 8)

                // ── Section 2: Quick Actions ────────────────────────────────
                quickActionsSection
                    .padding(.top, 28)

                // ── Section 3: Maintenance Alerts ─────────────────────────────
                maintenanceAlertsSection
                    .padding(.top, 28)

                Spacer(minLength: 48)
            }
            .padding(.top, 4)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Profile Section
                NavigationLink(destination: MaintenanceProfileView(isLoggedIn: $isLoggedIn)) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        // ── Reactive updates from MaintenanceStore ──────────────────────────
        .onAppear {
            viewModel.refresh(workOrders: store.workOrders, inspections: store.inspections, lowStock: store.lowStockCount)
        }
        .onReceive(store.$workOrders) { orders in
            viewModel.refresh(workOrders: orders, inspections: store.inspections, lowStock: store.lowStockCount)
        }
        .onReceive(store.$inspections) { inspections in
            viewModel.refresh(workOrders: store.workOrders, inspections: inspections, lowStock: store.lowStockCount)
        }
        .onReceive(store.$inventoryParts) { _ in
            viewModel.refresh(workOrders: store.workOrders, inspections: store.inspections, lowStock: store.lowStockCount)
        }
        // ── Modals ──────────────────────────────────────────────────────────
        .sheet(isPresented: $showingCreateInspection)    { CreateInspectionModal(isEmergency: false) }
        .sheet(isPresented: $showingEmergencyInspection) { CreateInspectionModal(isEmergency: true)  }
        .sheet(isPresented: $showingCreateWorkOrder)     { CreateWorkOrderModal() }
        .sheet(isPresented: $showingUpdateInventory)     { 
            NavigationStack {
                InventoryView(isLoggedIn: $isLoggedIn) 
            }
        }
    }

    // MARK: - Section 1: System Status

    private var systemStatusSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Fleet Analysis")
                .font(.title2.bold())
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                NavigationLink(destination: PendingWorkOrdersListView()) {
                    FleetAnalysisCard(
                        title: "Pending Orders",
                        count: "\(viewModel.pendingOrdersCount)",
                        icon: "clock.fill",
                        color: AppColors.primary
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: LowStockPartsView()) {
                    FleetAnalysisCard(
                        title: "Restock Alerts",
                        count: "\(viewModel.lowStockPartsCount)",
                        icon: "archivebox.fill",
                        color: .orange
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Section 2: Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(.title2.bold())
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Create Work Order",
                    icon: "plus.circle.fill",
                    color: AppColors.primary,
                    action: { showingCreateWorkOrder = true }
                )
                
                QuickActionButton(
                    title: "Update Inventory",
                    icon: "shippingbox.fill",
                    color: .orange,
                    action: { showingUpdateInventory = true }
                )
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Section 2: Maintenance Alerts

    private var maintenanceAlertsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header – chevron navigates to dedicated alerts list, NOT Work Orders tab
            MaintenanceSectionHeader(title: "Maintenance Alerts", destination: MaintenanceAlertsListView())
                .padding(.horizontal, 20)

            if viewModel.topCriticalWorkOrders.isEmpty {
                MaintenanceEmptyCard(message: "No active work orders", icon: "checkmark.circle.fill")
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.topCriticalWorkOrders.prefix(3).enumerated()), id: \.element.id) { index, item in
                        let match = store.workOrders.first { $0.id == item.id }
                        NavigationLink(
                            destination: Group {
                                if let order = match {
                                    WorkOrderDetailsView(workOrder: order)
                                } else {
                                    MaintenanceAlertsListView()
                                }
                            }
                        ) {
                            MaintenanceAlertCard(item: item)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if index < min(viewModel.topCriticalWorkOrders.count, 3) - 1 {
                            Divider()
                                .padding(.leading, 70)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Preview

struct MaintenanceDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MaintenanceDashboardView(isLoggedIn: .constant(true))
                .environmentObject(MaintenanceStore())
        }
    }
}
