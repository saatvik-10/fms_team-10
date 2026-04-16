//
//  WorkOrderManagementView.swift
//  FMS Frontend
//

import SwiftUI

struct WorkOrderManagementView: View {
    @StateObject private var viewModel = WorkOrderManagementViewModel()
    
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            List {
                ForEach(viewModel.workOrders) { order in
                    EnterpriseWorkOrderRow(order: order) { newStatus in
                        withAnimation(.spring()) {
                            viewModel.updateStatus(for: order.id, to: newStatus)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Work Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { /* New Work Order */ }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(AppColors.primary)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}

struct EnterpriseWorkOrderRow: View {
    let order: WorkOrder
    let onUpdate: (WorkOrderStatus) -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 20) {
                // Header: Vehicle and Status
                HStack(alignment: .center) {
                    Label(order.vehicleId, systemImage: "car.side.fill")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                    
                    Spacer()
                    
                    StatusBadge(text: order.status.rawValue, color: statusColor(order.status))
                }
                
                // Description: Professional Focus
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.taskDescription)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Opened \(order.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Divider()
                
                // Native Actions
                HStack(spacing: 12) {
                    if order.status == .pending {
                        ActionButton(title: "Start Progress", icon: "play.fill", color: AppColors.primary, isSelected: false) {
                            onUpdate(.inProgress)
                        }
                    } else if order.status == .inProgress {
                        ActionButton(title: "In Progress", icon: "hourglass", color: .blue, isSelected: true) {
                            // Already in progress
                        }
                        .disabled(true)
                    }
                    
                    ActionButton(title: "Mark Done", icon: "checkmark.seal.fill", color: AppColors.success, isSelected: order.status == .completed) {
                        onUpdate(.completed)
                    }
                }
            }
        }
    }
    
    func statusColor(_ status: WorkOrderStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return AppColors.success
        }
    }
}

struct WorkOrderManagementView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WorkOrderManagementView()
        }
    }
}
