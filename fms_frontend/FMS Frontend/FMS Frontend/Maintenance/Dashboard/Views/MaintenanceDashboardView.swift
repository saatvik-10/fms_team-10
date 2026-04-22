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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Section 1: System Status KPIs ──────────────────────────
                systemStatusSection
                    .padding(.top, 8)

                // ── Section 2: Priority Feed ────────────────────────────────
                priorityFeedSection
                    .padding(.top, 28)

                // ── Section 4: Active Staff ─────────────────────────────────
                activeStaffSection
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
                // Critical Alerts Button
                NavigationLink(destination: WorkOrderManagementView(maintenanceStore: store)) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 20))
                            .foregroundColor(viewModel.criticalAlertsCount > 0 ? AppColors.error : .secondary)
                        
                        if viewModel.criticalAlertsCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
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
            viewModel.refresh(workOrders: store.workOrders, inspections: store.inspections)
        }
        .onReceive(store.$workOrders) { orders in
            viewModel.refresh(workOrders: orders, inspections: store.inspections)
        }
        .onReceive(store.$inspections) { inspections in
            viewModel.refresh(workOrders: store.workOrders, inspections: inspections)
        }
        // ── Modals ──────────────────────────────────────────────────────────
        .sheet(isPresented: $showingCreateInspection)    { CreateInspectionModal(isEmergency: false) }
        .sheet(isPresented: $showingEmergencyInspection) { CreateInspectionModal(isEmergency: true)  }
        .sheet(isPresented: $showingCreateWorkOrder)     { CreateWorkOrderModal() }
    }

    // MARK: - Section 1: System Status

    private var systemStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1 – Pending Work Orders | Compliance Score
            HStack(spacing: 12) {
                NavigationLink(destination: WorkOrderManagementView(maintenanceStore: store)) {
                    SummaryCard(
                        title: "Pending Work Orders",
                        count: "\(viewModel.pendingOrdersCount)",
                        icon:  "clock.fill",
                        color: AppColors.primary
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: TodayInspectionsView()) {
                    InspectionSummaryCard(
                        completed: viewModel.completedInspectionsToday,
                        total: viewModel.totalInspectionsToday
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Row 2 – Low Stock Parts (full-width warning banner)
            NavigationLink(destination: LowStockPartsView()) {
                LowStockCard(count: viewModel.lowStockPartsCount)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Section 2: Priority Feed

    private var priorityFeedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MaintenanceSectionHeader(title: "Priority Feed", destination: WorkOrderManagementView(maintenanceStore: store))
                .padding(.horizontal, 20)

            if viewModel.topCriticalWorkOrders.isEmpty {
                MaintenanceEmptyCard(message: "No active work orders", icon: "checkmark.circle.fill")
                    .padding(.horizontal, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.topCriticalWorkOrders) { item in
                        let match = store.workOrders.first { $0.id == item.id }
                        NavigationLink(
                            destination: Group {
                                if let order = match {
                                    WorkOrderDetailsView(workOrder: order)
                                } else {
                                    WorkOrderManagementView(maintenanceStore: store)
                                }
                            }
                        ) {
                            PriorityFeedCard(item: item)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Section 4: Active Staff

    private var activeStaffSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Active Technicians")
                .font(.title2.bold())
                .padding(.horizontal, 20)

            if viewModel.activeStaff.isEmpty {
                MaintenanceEmptyCard(
                    message: "No technicians currently active",
                    icon:    "person.fill"
                )
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.activeStaff.enumerated()), id: \.element.id) { index, staff in
                        ActiveStaffRow(staff: staff)
                        if index < viewModel.activeStaff.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
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
