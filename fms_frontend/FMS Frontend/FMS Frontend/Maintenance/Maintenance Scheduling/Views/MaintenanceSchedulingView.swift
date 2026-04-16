//
//  MaintenanceSchedulingView.swift
//  FMS Frontend
//

import SwiftUI

struct MaintenanceSchedulingView: View {
    @StateObject private var viewModel = MaintenanceSchedulingViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            // New Schedule Section
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "truck.box.fill")
                            .foregroundColor(AppColors.primary)
                        TextField("Vehicle ID (e.g. V-101)", text: $viewModel.selectedVehicleId)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Issue Description")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)
                        TextEditor(text: $viewModel.issueDescription)
                            .frame(height: 100)
                            .padding(8)
                            .background(AppColors.secondaryBackground.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Divider()
                    
                    HStack {
                        Label("Priority", systemImage: "flag.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Picker("Priority", selection: $viewModel.selectedPriority) {
                            ForEach(MaintenancePriority.allCases, id: \.self) { priority in
                                Text(priority.rawValue).tag(priority)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Divider()
                    
                    DatePicker("Scheduled Date", selection: $viewModel.scheduledDate, displayedComponents: [.date, .hourAndMinute])
                        .font(.system(size: 14, weight: .semibold))
                    
                    PrimaryButton(title: "Confirm Schedule", action: {
                        viewModel.scheduleMaintenance()
                    })
                    .padding(.top, 10)
                }
                .padding(.vertical, 8)
            } header: {
                Text("NEW APPOINTMENT")
            }
            .listRowBackground(Color.white)
            
            // Active Schedules History
            Section {
                if viewModel.schedules.isEmpty {
                    Text("No active schedules")
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.schedules) { schedule in
                        ScheduleRow(schedule: schedule)
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            } header: {
                Text("ACTIVE SCHEDULES")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Scheduling")
        .background(AppColors.screenBackground)
    }
}

struct ScheduleRow: View {
    let schedule: MaintenanceSchedule
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(schedule.vehicleId)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Spacer()
                    StatusBadge(text: schedule.priority.rawValue, color: priorityColor(schedule.priority))
                }
                
                Text(schedule.reportedIssue)
                    .font(.body)
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "calendar")
                    Text(schedule.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                    Spacer()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.primary)
            }
        }
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
