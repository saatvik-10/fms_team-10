//
//  MaintenanceSchedulingView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceSchedulingView: View {
    @StateObject private var viewModel: MaintenanceSchedulingViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(vehicleId: String? = nil, description: String? = nil) {
        _viewModel = StateObject(wrappedValue: MaintenanceSchedulingViewModel(vehicleId: vehicleId, description: description))
    }
    
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // New Schedule Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SCHEDULE MAINTENANCE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .padding(.leading, 4)
                        
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Image(systemName: "car.side.fill")
                                    .foregroundColor(AppColors.primary.opacity(0.7))
                                    .frame(width: 24)
                                TextField("Vehicle ID (e.g. V-101)", text: $viewModel.selectedVehicleId)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .padding(16)
                            
                            Divider().padding(.leading, 52)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Issue Description", systemImage: "text.alignleft")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppColors.primary.opacity(0.7))
                                
                                TextEditor(text: $viewModel.issueDescription)
                                    .frame(height: 100)
                                    .padding(12)
                                    .background(AppColors.screenBackground)
                                    .cornerRadius(12)
                            }
                            .padding(16)
                            
                            Divider().padding(.leading, 16)
                            
                            HStack {
                                Label("Priority", systemImage: "flag.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppColors.primary.opacity(0.7))
                                Spacer()
                                Picker("Priority", selection: $viewModel.selectedPriority) {
                                    ForEach(MaintenancePriority.allCases, id: \.self) { priority in
                                        Text(priority.rawValue).tag(priority)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(AppColors.primary)
                            }
                            .padding(16)
                            
                            Divider().padding(.leading, 16)
                            
                            DatePicker(selection: $viewModel.scheduledDate, displayedComponents: [.date, .hourAndMinute]) {
                                Label("Scheduled Date", systemImage: "calendar")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppColors.primary.opacity(0.7))
                            }
                            .padding(16)
                        }
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        
                        PrimaryButton(title: "Confirm Schedule") {
                            viewModel.scheduleMaintenance()
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.top, 8)
                    }
                    
                    // Active Schedules History
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACTIVE SCHEDULES")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                            .padding(.leading, 4)
                        
                        if viewModel.schedules.isEmpty {
                            Text("No active schedules")
                                .font(.system(size: 15))
                                .foregroundColor(AppColors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.schedules) { schedule in
                                    ScheduleRow(schedule: schedule)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Scheduling")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ScheduleRow: View {
    let schedule: MaintenanceSchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(AppColors.primary)
                                .font(.system(size: 16, weight: .bold))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(schedule.vehicleId)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        Text(schedule.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                Spacer()
                
                StatusBadge(text: schedule.priority.rawValue, color: priorityColor(schedule.priority))
            }
            
            Text(schedule.reportedIssue)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primaryText)
                .lineLimit(2)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    func priorityColor(_ priority: MaintenancePriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct MaintenanceSchedulingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MaintenanceSchedulingView()
        }
    }
}
