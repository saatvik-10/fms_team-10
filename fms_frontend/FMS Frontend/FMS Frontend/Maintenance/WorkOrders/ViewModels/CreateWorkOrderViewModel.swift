//
//  CreateWorkOrderViewModel.swift
//  Created by Akhilesh Mykalwar
//

import SwiftUI

class CreateWorkOrderViewModel: ObservableObject {
    @Published var taskTitle = ""
    @Published var selectedVehicle: WorkOrderVehicleItem?
    @Published var serviceType = "Routine PM"
    @Published var priority: WorkOrderPriority = .medium
    @Published var taskDetails = ""
    @Published var scheduledDate = Date()
    @Published var showingVehiclePicker = false
    @Published var showingScheduleValidationAlert = false
    @Published var driverMediaImages: [Data] = []
    @Published var vehicles: [WorkOrderVehicleItem] = []
    @Published var isLoadingVehicles = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    let serviceTypes = ["Routine PM", "Repair", "Inspection", "Emergency"]

    @MainActor
    func loadVehicles() async {
        if isLoadingVehicles { return }
        isLoadingVehicles = true
        defer { isLoadingVehicles = false }

        do {
            let response = try await MaintenanceAPI.shared.getWorkOrderVehicles()
            vehicles = response.vehicles
            if selectedVehicle == nil {
                selectedVehicle = vehicles.first
            }
        } catch {
            do {
                let response = try await VehicleAPI.shared.getVehicles()
                vehicles = response.vehicles.map { WorkOrderVehicleItem(vehicle: $0) }
                if selectedVehicle == nil {
                    selectedVehicle = vehicles.first
                }
            } catch {
                errorMessage = error.localizedDescription
                print("[ERROR] [ERROR] Failed to load vehicles: \(error)")
            }
        }
    }

    @MainActor
    func createWorkOrder(store: MaintenanceStore, dismiss: @escaping () -> Void) async {
        guard let selectedVehicle else {
            errorMessage = "Please select a vehicle."
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: scheduledDate)
        guard startOfDay >= Calendar.current.startOfDay(for: Date()) else {
            scheduledDate = Date()
            showingScheduleValidationAlert = true
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let request = CreateWorkOrderRequest(
            vehicleId: selectedVehicle.id,
            title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New Task" : taskTitle,
            serviceType: serviceType,
            priority: priority.apiValue,
            date: ISO8601DateFormatter().string(from: startOfDay),
            taskDetails: taskDetails,
            mediaImages: driverMediaImages.map { $0.base64EncodedString() }
        )

        do {
            let response = try await MaintenanceAPI.shared.createWorkOrder(request)
            let newOrder = WorkOrder(
                apiItem: response.workOrder,
                localMediaImages: driverMediaImages
            )
            store.addWorkOrder(newOrder)
            print("[SUCCESS] [SUCCESS] Work Order created: \(newOrder.orderID)")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            print("[ERROR] [ERROR] Failed to create work order: \(error)")
        }
    }
}
