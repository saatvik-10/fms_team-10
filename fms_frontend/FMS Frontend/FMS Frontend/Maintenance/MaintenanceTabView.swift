//
//  MaintenanceTabView.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI

struct MaintenanceTabView: View {
    @Binding var isLoggedIn: Bool
    @StateObject var store = MaintenanceStore()
    
    var body: some View {
        TabView {
            // Tab 1: Dashboard
            NavigationStack {
                MaintenanceDashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            
            // Tab 3: Inspections
            NavigationStack {
                TripInspectionView()
            }
            .tabItem {
                Label("Inspections", systemImage: "clipboard.fill")
            }
        }
        .environmentObject(store)
        .accentColor(AppColors.primary)
    }
}
