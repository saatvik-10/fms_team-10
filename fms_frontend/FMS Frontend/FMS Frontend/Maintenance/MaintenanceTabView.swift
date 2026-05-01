//
//  MaintenanceTabView.swift
//  Created by Saatvik Madan
//

import SwiftUI
import Combine

struct MaintenanceTabView: View {
    @Binding var isLoggedIn: Bool
    @StateObject var store = MaintenanceStore()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard
            NavigationStack {
                MaintenanceDashboardView(isLoggedIn: $isLoggedIn, selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            .tag(0)

            // Tab 2: Work Orders
            NavigationStack {
                WorkOrderManagementView(maintenanceStore: store, isLoggedIn: $isLoggedIn)
            }
            .tabItem {
                Label("Work Orders", systemImage: "wrench.and.screwdriver.fill")
            }
            .tag(1)

            // Tab 3: Inventory
            NavigationStack {
                InventoryView(isLoggedIn: $isLoggedIn)
            }
            .tabItem {
                Label("Inventory", systemImage: "box.truck.fill")
            }
            .tag(2)

            // Tab 4: Inspections
            NavigationStack {
                InspectionHistoryView(isLoggedIn: $isLoggedIn, maintenanceStore: store)
            }
            .tabItem {
                Label("Inspections", systemImage: "clipboard.fill")
            }
            .tag(3)
            
            // --- CHAT INTEGRATION ---
            NavigationStack {
                ChatListView()
            }
            .tabItem {
                Label("Messages", systemImage: "message.fill")
            }
            .tag(4)
            // ------------------------
        }
        .environmentObject(store)
        .tint(AppColors.primary)
        .accentColor(AppColors.primary)
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            store.refreshWorkOrderStatuses()
        }
    }
}
