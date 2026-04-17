//
//  CreateWorkOrderModal.swift
//  FMS Frontend
//

import SwiftUI

struct CreateWorkOrderModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    
    @State private var taskTitle = ""
    @State private var vehicleName = "Unit 842-Alpha"
    @State private var serviceType = "Routine PM"
    @State private var priority: WorkOrderPriority = .medium
    @State private var taskDetails = ""
    @State private var scheduledDate = Date()
    
    let vehicles = ["Unit 842-Alpha", "Unit 319-Echo", "Unit 115-Delta", "Unit 990-Zeta"]
    let serviceTypes = ["Routine PM", "Repair", "Inspection", "Emergency"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F9FB").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Top Info Card
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "person.2.badge.gearshape.fill")
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Technical Request")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Assigning a new service ticket to the fleet queue.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        
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
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        FormGroup(title: "TASK DETAILS") {
                            TextEditor(text: $taskDetails)
                                .frame(height: 100)
                                .font(.system(size: 14))
                        }
                        
                        FormGroup(title: "SCHEDULED START") {
                            DatePicker("", selection: $scheduledDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
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
                    Button("Save") {
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
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.primary)
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
