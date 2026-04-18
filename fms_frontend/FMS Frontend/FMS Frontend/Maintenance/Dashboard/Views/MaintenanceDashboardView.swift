//
//  MaintenanceDashboardView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceDashboardView: View {
    @EnvironmentObject var store: MaintenanceStore
    @State private var showingCreateInspection = false
    @State private var showingEmergencyInspection = false
    @State private var showingCreateWorkOrder = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Work Orders Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Work Orders")
                            .font(.title2.bold())

                        Spacer()

                        NavigationLink(destination: WorkOrderManagementView()) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(.systemGray3))
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 16) {
                        let sortedOrders = store.workOrders.sorted { $0.priority.sortingOrder < $1.priority.sortingOrder }
                        ForEach(sortedOrders.prefix(5)) { order in
                            NavigationLink(destination: WorkOrderDetailsView(workOrder: order)) {
                                WorkOrderTaskCard(order: order)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation {
                                        store.deleteWorkOrder(order)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 30)
            }
            .padding(.top)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Maintenance")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: MaintenanceProfileView(isLoggedIn: .constant(true))) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showingCreateInspection) {
            CreateInspectionModal(isEmergency: false)
        }
        .sheet(isPresented: $showingEmergencyInspection) {
            CreateInspectionModal(isEmergency: true)
        }
        .sheet(isPresented: $showingCreateWorkOrder) {
            CreateWorkOrderModal()
        }
    }
}

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
