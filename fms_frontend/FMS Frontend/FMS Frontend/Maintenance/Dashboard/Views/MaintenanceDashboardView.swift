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
                    .padding(.horizontal, 20)
                    
                    // Alerts Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Critical Alerts")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Spacer()
                            Text("View All")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppColors.primary)
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.recentAlerts) { alert in
                                NavigationLink {
                                    if alert.type == .maintenance {
                                        MaintenanceSchedulingView(vehicleId: alert.vehicleId, description: alert.issueDescription)
                                    } else if alert.type == .inspection {
                                        TripInspectionView()
                                    } else {
                                        Text("Alert Details: \(alert.title)")
                                    }
                                } label: {
                                    AlertCard(alert: alert)
                                }
                                .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(color)
                    )
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(count)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.secondaryText)
                    .tracking(1.0)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct AlertCard: View {
    let alert: MaintenanceDashboardViewModel.MaintenanceAlert
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill((alert.type == .inspection ? AppColors.primary : .orange).opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: alert.type == .inspection ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(alert.type == .inspection ? AppColors.primary : .orange)
                        .font(.system(size: 18, weight: .bold))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                Text(alert.message)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(alert.time)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.secondaryText)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.secondaryText.opacity(0.3))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
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
