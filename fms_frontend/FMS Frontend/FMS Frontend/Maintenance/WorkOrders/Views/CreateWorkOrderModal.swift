//
//  CreateWorkOrderModal.swift
//  Created by Aryan Dev
//

import SwiftUI

struct CreateWorkOrderModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    @StateObject private var viewModel = CreateWorkOrderViewModel()

    private var selectedVehicleName: String {
        viewModel.selectedVehicle?.pickerName ?? "Select vehicle"
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    assetIdentitySection
                    classificationSection
                    timingSection
                    taskDetailsSection
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Work Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await viewModel.createWorkOrder(store: store, dismiss: { dismiss() }) }
                    }) {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    .disabled(viewModel.isSubmitting || viewModel.selectedVehicle == nil)
                }
            }
            .alert("Invalid Schedule", isPresented: $viewModel.showingScheduleValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Scheduled date cannot be before today.")
            }
            .alert("Work Order Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unable to create work order.")
            }
            .sheet(isPresented: $viewModel.showingVehiclePicker) {
                VehiclePickerView(
                    selectedVehicle: $viewModel.selectedVehicle,
                    vehicles: $viewModel.vehicles,
                    isLoadingVehicles: $viewModel.isLoadingVehicles,
                    loadVehicles: { await viewModel.loadVehicles() }
                )
            }
            .task {
                await viewModel.loadVehicles()
            }
        }
    }

    private var assetIdentitySection: some View {
        VStack(spacing: 12) {
            FormGroup(title: "VEHICLE SELECTION") {
                Button(action: { viewModel.showingVehiclePicker = true }) {
                    HStack {
                        if viewModel.isLoadingVehicles {
                            ProgressView()
                        } else {
                            Text(selectedVehicleName)
                                .foregroundColor(viewModel.selectedVehicle == nil ? .secondary : .primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
                }
            }

            FormGroup(title: "TASK TITLE") {
                TextField("e.g. Emergency Brake Inspection", text: $viewModel.taskTitle)
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
            }
        }
    }

    private var classificationSection: some View {
        VStack(spacing: 12) {
            FormGroup(title: "SERVICE TYPE") {
                Picker("Type", selection: $viewModel.serviceType) {
                    ForEach(viewModel.serviceTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
            }

            FormGroup(title: "WORK ORDER PRIORITY") {
                Picker("Priority", selection: $viewModel.priority) {
                    Text("Low").tag(WorkOrderPriority.low)
                    Text("Medium").tag(WorkOrderPriority.medium)
                    Text("High").tag(WorkOrderPriority.high)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var timingSection: some View {
        VStack(spacing: 12) {
            FormGroup(title: "SCHEDULED DATE") {
                DatePicker("", selection: $viewModel.scheduledDate, in: Date()..., displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var taskDetailsSection: some View {
        FormGroup(title: "TASK DETAILS") {
            TextEditor(text: $viewModel.taskDetails)
                .frame(height: 100)
                .font(.system(size: 14))
                .padding(4)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
        }
    }
}
