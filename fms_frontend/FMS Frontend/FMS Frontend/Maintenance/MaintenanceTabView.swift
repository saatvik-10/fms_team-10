//
//  MaintenanceTabView.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI

struct MaintenanceTabView: View {
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        TabView {
            // Tab 1: Work Orders
            NavigationStack {
                WorkOrderManagementView()
            }
            .tabItem {
                Label("Work Orders", systemImage: "list.bullet.rectangle.portrait.fill")
            }
            
            // Tab 2: Inspections
            NavigationStack {
                TripInspectionView()
            }
            .tabItem {
                Label("Inspections", systemImage: "checkmark.shield.fill")
            }
            
            // Tab 3: Reports
            NavigationStack {
                MaintenanceReportsView()
            }
            .tabItem {
                Label("Reports", systemImage: "doc.text.fill")
            }
            
            // Tab 4: Chat
            NavigationStack {
                ChatView()
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
            }
        }
        .accentColor(AppColors.primary)
    }
}
