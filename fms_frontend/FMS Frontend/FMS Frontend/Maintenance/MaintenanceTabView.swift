//
//  MaintenanceTabView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceTabView: View {
    @Binding var isLoggedIn: Bool
    @StateObject var store = MaintenanceStore()

    var body: some View {
        TabView {
            // Tab 1: Dashboard
            NavigationStack {
                MaintenanceDashboardView(isLoggedIn: $isLoggedIn)
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }

            // Tab 2: Work Orders
            NavigationStack {
                WorkOrderManagementView(maintenanceStore: store)
            }
            .tabItem {
                Label("Work Orders", systemImage: "wrench.and.screwdriver.fill")
            }

            // Tab 3: Inventory
            NavigationStack {
                InventoryManagementView()
            }
            .tabItem {
                Label("Inventory", systemImage: "box.truck.fill")
            }

            // Tab 4: Inspections
            NavigationStack {
                InspectionHistoryView(maintenanceStore: store)
            }
            .tabItem {
                Label("Inspections", systemImage: "clipboard.fill")
            }
        }
        .environmentObject(store)
        .accentColor(AppColors.primary)
    }
}
