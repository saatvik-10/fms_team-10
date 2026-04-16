//
//  MaintenanceTabView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceTabView: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        TabView {
            // Tab 1: Dashboard
            NavigationStack {
                MaintenanceDashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            
            // Tab 2: Work Orders
            NavigationStack {
                WorkOrderManagementView()
            }
            .tabItem {
                Label("Work Orders", systemImage: "list.bullet.rectangle.portrait.fill")
            }
            
            // Tab 3: Inspections
            NavigationStack {
                TripInspectionView()
            }
            .tabItem {
                Label("Inspections", systemImage: "checkmark.shield.fill")
            }
            
            // Tab 4: Inventory
            NavigationStack {
                InventoryView()
            }
            .tabItem {
                Label("Inventory", systemImage: "box.truck.fill")
            }
            
            // Tab 5: Profile
            NavigationStack {
                MaintenanceProfileView(isLoggedIn: $isLoggedIn)
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
        }
        .accentColor(AppColors.primary)
    }
}

struct MaintenanceTabView_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceTabView(isLoggedIn: .constant(true))
    }
}
