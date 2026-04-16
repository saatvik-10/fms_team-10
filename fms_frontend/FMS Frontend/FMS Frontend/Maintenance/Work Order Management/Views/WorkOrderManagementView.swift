//
//  WorkOrderManagementView.swift
//  FMS Frontend
//

import SwiftUI

struct WorkOrderManagementView: View {
    @StateObject private var viewModel = WorkOrderManagementViewModel()
    @State private var isShowingNewOrderSheet = false
    @State private var newVehicleId = ""
    @State private var newTaskDescription = ""
    @State private var newTechnicianId = ""
    
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Work Orders")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        Text("Manage and track maintenance tasks")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Work Orders List
                    VStack(spacing: 16) {
                        ForEach(viewModel.workOrders) { order in
                            EnterpriseWorkOrderRow(order: order) { newStatus in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.updateStatus(for: order.id, to: newStatus)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .safeAreaInset(edge: .bottom) {
                Button(action: { isShowingNewOrderSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Work Order")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .background(AppColors.screenBackground.opacity(0.8))
            }
            .sheet(isPresented: $isShowingNewOrderSheet) {
                NewWorkOrderSheet(
                    isShowing: $isShowingNewOrderSheet,
                    vehicleId: $newVehicleId,
                    description: $newTaskDescription,
                    technicianId: $newTechnicianId,
                    onCreate: {
                        viewModel.addWorkOrder(vehicleId: newVehicleId, description: newTaskDescription, technicianId: newTechnicianId)
                        newVehicleId = ""
                        newTaskDescription = ""
                        newTechnicianId = ""
                    }
                )
            }
        }
    }
}

struct NewWorkOrderSheet: View {
    @Binding var isShowing: Bool
    @Binding var vehicleId: String
    @Binding var description: String
    @Binding var technicianId: String
    var onCreate: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("VEHICLE DETAILS")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .tracking(1.0)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 0) {
                                CustomTextField(placeholder: "Vehicle ID (e.g. V-102)", text: $vehicleId, icon: "car.side.fill")
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TASK INFORMATION")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .tracking(1.0)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 0) {
                                CustomTextField(placeholder: "Description of work", text: $description, icon: "wrench.and.screwdriver.fill")
                                Divider().padding(.leading, 44)
                                CustomTextField(placeholder: "Technician ID", text: $technicianId, icon: "person.badge.shield.checkmark.fill")
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                        }
                        
                        PrimaryButton(title: "Create Work Order") {
                            onCreate()
                            isShowing = false
                        }
                        .disabled(vehicleId.isEmpty || description.isEmpty)
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isShowing = false }
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary.opacity(0.7))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
        }
        .padding(16)
    }
}

struct EnterpriseWorkOrderRow: View {
    let order: WorkOrder
    let onUpdate: (WorkOrderStatus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header: Vehicle and Status
            HStack {
                HStack(spacing: 12) {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "car.side.fill")
                                .foregroundColor(AppColors.primary)
                                .font(.system(size: 16, weight: .bold))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.vehicleId)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        Text("Opened \(order.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                Spacer()
                
                StatusBadge(text: order.status.rawValue, color: statusColor(order.status))
            }
            
            // Description
            Text(order.taskDescription)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            // Native Actions
            HStack(spacing: 12) {
                if order.status == .pending {
                    ActionButton(title: "Start Progress", icon: "play.fill", color: AppColors.primary, isSelected: false) {
                        onUpdate(.inProgress)
                    }
                    ActionButton(title: "Complete", icon: "checkmark.seal.fill", color: AppColors.success, isSelected: false) {
                        onUpdate(.completed)
                    }
                } else if order.status == .inProgress {
                    ActionButton(title: "In Progress", icon: "hourglass", color: .blue, isSelected: true) {
                        // Already in progress
                    }
                    .disabled(true)
                    
                    ActionButton(title: "Mark Done", icon: "checkmark.seal.fill", color: AppColors.success, isSelected: false) {
                        onUpdate(.completed)
                    }
                } else if order.status == .completed {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                            .font(.system(size: 18, weight: .bold))
                        Text("Completed")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppColors.success)
                        
                        Spacer()
                        
                        Button(action: { onUpdate(.pending) }) {
                            Text("Reopen Task")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
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
