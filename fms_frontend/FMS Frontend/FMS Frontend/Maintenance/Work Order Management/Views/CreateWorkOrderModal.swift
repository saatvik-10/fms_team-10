//
//  CreateWorkOrderModal.swift
//  FMS Frontend
//

import SwiftUI

struct CreateWorkOrderModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore

    @State private var taskTitle = ""
    @State private var vehicleName = "Mercedes-Benz Actros (Truck)"
    @State private var serviceType = "Routine PM"
    @State private var priority: WorkOrderPriority = .medium
    @State private var taskDetails = ""
    @State private var scheduledDate = Date()

    let vehicles = [
        "Mercedes-Benz Actros (Truck)",
        "Volvo FH16 (Truck)",
        "MAN TGX (Truck)",
        "Scania R450 (Truck)",
        "Toyota Coaster (Bus)",
        "Tata Starbus (Bus)",
        "BharatBenz 1617 (Bus)",
        "Ashok Leyland Lynx (Bus)",
        "Ford Transit (Van)",
        "Mercedes-Benz Sprinter (Van)",
        "Toyota HiAce (Van)",
        "Toyota Land Cruiser (SUV)",
        "Ford Ranger (Pickup)",
        "Isuzu D-Max (Pickup)"
    ]

    let serviceTypes = ["Routine PM", "Repair", "Inspection", "Emergency"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F9FB").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Form Fields
                        FormGroup(title: "TASK TITLE") {
                            TextField("e.g. Emergency Brake Inspection", text: $taskTitle)
                        }

                        FormGroup(title: "VEHICLE SELECTION") {
                            Picker("Vehicle", selection: $vehicleName) {
                                ForEach(vehicles, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                        }

                        FormGroup(title: "SERVICE TYPE") {
                            Picker("Type", selection: $serviceType) {
                                ForEach(serviceTypes, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                        }

                        FormGroup(title: "WORK ORDER PRIORITY") {
                            Picker("Priority", selection: $priority) {
                                Text("Low").tag(WorkOrderPriority.low)
                                Text("Medium").tag(WorkOrderPriority.medium)
                                Text("High").tag(WorkOrderPriority.high)
                                Text("Critical").tag(WorkOrderPriority.critical)
                            }
                            .pickerStyle(.segmented)
                        }

                        FormGroup(title: "TASK DETAILS") {
                            TextEditor(text: $taskDetails)
                                .frame(height: 100)
                                .font(.system(size: 14))
                        }

                        FormGroup(title: "SCHEDULED DATE & TIME") {
                            DatePicker("", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Work Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let newOrder = WorkOrder(
                            title: taskTitle.isEmpty ? "New Task" : taskTitle,
                            vehicleName: vehicleName,
                            vehicleVIN: "VIN-\(Int.random(in: 1000...9999))",
                            serviceType: serviceType,
                            priority: priority,
                            status: .pending,
                            taskDetails: taskDetails,
                            scheduledDate: scheduledDate,
                            technicianId: "TECH-01"
                        )
                        store.addWorkOrder(newOrder)
                        dismiss()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
    }
}

struct FormGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            content
                .padding()
                .background(Color(hex: "F8F9FB"))
                .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}
