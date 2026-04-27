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
    @State private var showingVehiclePicker = false
    @State private var showingScheduleValidationAlert = false
    @State private var driverMediaImages: [Data] = []
    @State private var showingDriverMediaPicker = false

    let vehicles = ["Mercedes-Benz Actros (Truck)", "Volvo FH16 (Truck)", "MAN TGX (Truck)", "Scania R450 (Truck)", "Toyota Coaster (Bus)", "Eicher Pro 6037", "Ashok Leyland Captain", "BharatBenz 3523R", "Tata Prima"]
    let serviceTypes = ["Routine PM", "Repair", "Inspection", "Emergency"]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    assetIdentitySection
                    classificationSection
                    timingSection
                    taskDetailsSection
                    driverMediaSection
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
                        let now = Date()
                        guard scheduledDate >= now else {
                            scheduledDate = now
                            showingScheduleValidationAlert = true
                            return
                        }

                        let newOrder = WorkOrder(
                            title: taskTitle.isEmpty ? "New Task" : taskTitle,
                            vehicleName: vehicleName,
                            vehicleVIN: "VIN-\(Int.random(in: 1000...9999))",
                            serviceType: serviceType,
                            priority: priority,
                            status: .pending,
                            taskDetails: taskDetails,
                            scheduledDate: scheduledDate,
                            technicianId: "Unassigned",
                            driverMediaImages: driverMediaImages,
                            checklist: TripInspection.mockItems(for: vehicleName.contains("Bus") ? .car : .truck)
                        )
                        store.addWorkOrder(newOrder)
                        dismiss()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .alert("Invalid Schedule", isPresented: $showingScheduleValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Scheduled date and time cannot be before the current time.")
            }
            .sheet(isPresented: $showingVehiclePicker) {
                VehiclePickerView(selectedVehicle: $vehicleName, vehicles: vehicles)
            }
            .sheet(isPresented: $showingDriverMediaPicker) {
                PhotoPicker(images: Binding(
                    get: { [] },
                    set: { images in
                        driverMediaImages.append(contentsOf: images.compactMap { $0.jpegData(compressionQuality: 0.7) })
                    }
                ))
            }
        }
    }

    private var assetIdentitySection: some View {
        VStack(spacing: 12) {
            FormGroup(title: "VEHICLE SELECTION") {
                Button(action: { showingVehiclePicker = true }) {
                    HStack {
                        Text(vehicleName)
                            .foregroundColor(.primary)
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
                TextField("e.g. Emergency Brake Inspection", text: $taskTitle)
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
            }
        }
    }

    private var classificationSection: some View {
        VStack(spacing: 12) {
            FormGroup(title: "SERVICE TYPE") {
                Picker("Type", selection: $serviceType) {
                    ForEach(serviceTypes, id: \.self) { type in
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
                Picker("Priority", selection: $priority) {
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
            FormGroup(title: "SCHEDULED DATE & TIME") {
                DatePicker("", selection: $scheduledDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var taskDetailsSection: some View {
        FormGroup(title: "TASK DETAILS") {
            TextEditor(text: $taskDetails)
                .frame(height: 100)
                .font(.system(size: 14))
                .padding(4)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
        }
    }

    private var driverMediaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FormGroup(title: "DRIVER MEDIA") {
                VStack(alignment: .leading, spacing: 12) {
                    if driverMediaImages.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Text("No driver media attached.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        driverMediaPreviewStrip
                    }

                    Button(action: { showingDriverMediaPicker = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.subheadline)
                            Text("Add Driver Media")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
    }

    private var driverMediaPreviewStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(driverMediaImages.enumerated()), id: \.offset) { item in
                    driverMediaThumbnail(data: item.element, index: item.offset)
                }
            }
        }
    }

    private func driverMediaThumbnail(data: Data, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            driverMediaImageView(data: data)

            Button(action: {
                withAnimation {
                    removeDriverMedia(at: index)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
            .offset(x: 4, y: -4)
        }
    }

    @ViewBuilder
    private func driverMediaImageView(data: Data) -> some View {
        if let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .cornerRadius(10)
                .clipped()
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray5))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.secondary)
                }
        }
    }

    private func removeDriverMedia(at index: Int) {
        guard driverMediaImages.indices.contains(index) else { return }
        driverMediaImages.remove(at: index)
    }
}

struct VehiclePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedVehicle: String
    let vehicles: [String]
    @State private var searchText = ""
    
    var filteredVehicles: [String] {
        if searchText.isEmpty {
            return vehicles
        } else {
            return vehicles.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredVehicles, id: \.self) { vehicle in
                    Button(action: {
                        selectedVehicle = vehicle
                        dismiss()
                    }) {
                        HStack {
                            Text(vehicle)
                                .foregroundColor(.primary)
                            Spacer()
                            if vehicle == selectedVehicle {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search vehicle name or unit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
