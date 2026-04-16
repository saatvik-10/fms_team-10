//
//  MaintenanceDashboardView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceDashboardView: View {
    @StateObject private var viewModel = MaintenanceDashboardViewModel()
    
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Region (Integrated with Tab)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fleet Health")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        Text("Real-time maintenance status and alerts")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Summary Stats: Enterprise Look
                    HStack(spacing: 16) {
                        SummaryCard(title: "Inspections", count: "\(viewModel.pendingInspectionsCount)", icon: "checkmark.shield.fill", color: AppColors.primary)
                        SummaryCard(title: "Work Orders", count: "\(viewModel.activeWorkOrdersCount)", icon: "wrench.and.screwdriver.fill", color: .orange)
                    }
                    .padding(.horizontal)
                    
                    // Alerts Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Critical Alerts")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            Text("View All")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.recentAlerts) { alert in
                                AlertCard(alert: alert)
                            }
                        }
                    }
                    
                    // Operational Shortcuts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Operations")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: TripInspectionView()) {
                                QuickActionRow(title: "New Pre-Trip Inspection", icon: "plus.circle.fill", isLast: false)
                            }
                            Divider().padding(.leading, 54)
                            NavigationLink(destination: MaintenanceSchedulingView()) {
                                QuickActionRow(title: "Schedule Repair", icon: "calendar.badge.plus", isLast: false)
                            }
                            Divider().padding(.leading, 54)
                            NavigationLink(destination: WorkOrderManagementView()) {
                                QuickActionRow(title: "Open Work Orders", icon: "list.bullet.rectangle.portrait", isLast: true)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// MARK: - Subviews Re-styled for Enterprise

struct SummaryCard: View {
    let title: String
    let count: String
    let icon: String
    let color: Color
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(color)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(count)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct AlertCard: View {
    let alert: MaintenanceDashboardViewModel.MaintenanceAlert
    
    var body: some View {
        CardView {
            HStack(spacing: 16) {
                Circle()
                    .fill(alert.type == .inspection ? AppColors.primary : .orange)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    Text(alert.message)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(alert.time)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(.horizontal)
    }
}

struct QuickActionRow: View {
    let title: String
    let icon: String
    let isLast: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppColors.secondaryText.opacity(0.5))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }
}

struct MaintenanceDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MaintenanceDashboardView()
        }
    }
}
