//
//  CreateWorkOrderModal.swift
//  FMS Frontend
//

import SwiftUI

struct CreateWorkOrderModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore

    @State private var taskTitle = ""
    @State private var selectedVehicle: WorkOrderVehicleItem?
    @State private var serviceType = "Routine PM"
    @State private var priority: WorkOrderPriority = .medium
    @State private var taskDetails = ""
    @State private var scheduledDate = Date()
    @State private var showingVehiclePicker = false
    @State private var showingScheduleValidationAlert = false
    @State private var driverMediaImages: [Data] = []
    @State private var showingDriverMediaPicker = false
    @State private var vehicles: [WorkOrderVehicleItem] = []
    @State private var isLoadingVehicles = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    let serviceTypes = ["Routine PM", "Repair", "Inspection", "Emergency"]
    private var selectedVehicleName: String {
        selectedVehicle?.pickerName ?? "Select vehicle"
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    assetIdentitySection
                    classificationSection
                    timingSection
                    taskDetailsSection
                    // driverMediaSection
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
                        Task { await createWorkOrder() }
                    }) {
                        if isSubmitting {
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
                    .disabled(isSubmitting || selectedVehicle == nil)
                }
            }
            .alert("Invalid Schedule", isPresented: $showingScheduleValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Scheduled date cannot be before today.")
            }
            .alert("Work Order Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unable to create work order.")
            }
            .sheet(isPresented: $showingVehiclePicker) {
                VehiclePickerView(
                    selectedVehicle: $selectedVehicle,
                    vehicles: $vehicles,
                    isLoadingVehicles: $isLoadingVehicles,
                    loadVehicles: loadVehicles
                )
            }
            // .sheet(isPresented: $showingDriverMediaPicker) {
            //     PhotoPicker(images: Binding(
            //         get: { [] },
            //         set: { images in
            //             driverMediaImages.append(contentsOf: images.compactMap { $0.jpegData(compressionQuality: 0.7) })
            //         }
            //     ))
            // }
            .task {
                await loadVehicles()
            }
        }
    }

    private var assetIdentitySection: some View {
        VStack(spacing: 12) {
            FormGroup(title: "VEHICLE SELECTION") {
                Button(action: { showingVehiclePicker = true }) {
                    HStack {
                        if isLoadingVehicles {
                            ProgressView()
                        } else {
                            Text(selectedVehicleName)
                                .foregroundColor(selectedVehicle == nil ? .secondary : .primary)
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
            FormGroup(title: "SCHEDULED DATE") {
                DatePicker("", selection: $scheduledDate, in: Date()..., displayedComponents: [.date])
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

    // private var driverMediaSection: some View {
    //     VStack(alignment: .leading, spacing: 12) {
    //         FormGroup(title: "MEDIA") {
    //             VStack(alignment: .leading, spacing: 12) {
    //                 if driverMediaImages.isEmpty {
    //                     HStack(spacing: 10) {
    //                         Text("No media attached.")
    //                             .font(.subheadline)
    //                             .foregroundColor(.secondary)
    //                     }
    //                     .padding(.vertical, 8)
    //                 } else {
    //                     // driverMediaPreviewStrip
    //                 }

    //                 Button(action: { showingDriverMediaPicker = true }) {
    //                     HStack(spacing: 8) {
    //                         Image(systemName: "camera.fill")
    //                             .font(.subheadline)
    //                         Text("Add Media")
    //                             .font(.subheadline.weight(.semibold))
    //                     }
    //                     .foregroundColor(AppColors.primary)
    //                 }
    //             }
    //         }
    //     }
    // }

    // private var driverMediaPreviewStrip: some View {
    //     ScrollView(.horizontal, showsIndicators: false) {
    //         HStack(spacing: 10) {
    //             ForEach(Array(driverMediaImages.enumerated()), id: \.offset) { item in
    //                 driverMediaThumbnail(data: item.element, index: item.offset)
    //             }
    //         }
    //     }
    // }

    // private func driverMediaThumbnail(data: Data, index: Int) -> some View {
    //     ZStack(alignment: .topTrailing) {
    //        driverMediaImageView(data: data)

    //         Button(action: {
    //             withAnimation {
    //                 removeDriverMedia(at: index)
    //             }
    //         }) {
    //             Image(systemName: "xmark.circle.fill")
    //                 .font(.system(size: 18))
    //                 .foregroundColor(.white)
    //                 .shadow(color: .black.opacity(0.5), radius: 2)
    //         }
    //         .offset(x: 4, y: -4)
    //     }
    // }

    @ViewBuilder
    // private func driverMediaImageView(data: Data) -> some View {
    //     if let uiImage = UIImage(data: data) {
    //         Image(uiImage: uiImage)
    //             .resizable()
    //             .aspectRatio(contentMode: .fill)
    //             .frame(width: 80, height: 80)
    //             .cornerRadius(10)
    //             .clipped()
    //     } else {
    //         RoundedRectangle(cornerRadius: 10)
    //             .fill(Color(.systemGray5))
    //             .frame(width: 80, height: 80)
    //             .overlay {
    //                 Image(systemName: "exclamationmark.triangle")
    //                     .foregroundColor(.secondary)
    //             }
    //     }
    // }

    private func removeDriverMedia(at index: Int) {
        guard driverMediaImages.indices.contains(index) else { return }
        driverMediaImages.remove(at: index)
    }

    @MainActor
    private func loadVehicles() async {
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
            }
        }
    }

    @MainActor
    private func createWorkOrder() async {
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
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct VehiclePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedVehicle: WorkOrderVehicleItem?
    @Binding var vehicles: [WorkOrderVehicleItem]
    @Binding var isLoadingVehicles: Bool
    let loadVehicles: () async -> Void
    @State private var searchText = ""
    
    var filteredVehicles: [WorkOrderVehicleItem] {
        if searchText.isEmpty {
            return vehicles
        } else {
            return vehicles.filter {
                $0.pickerName.localizedCaseInsensitiveContains(searchText) ||
                $0.registrationNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if isLoadingVehicles {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, 24)
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                } else if filteredVehicles.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "truck.box")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                        Text("No vehicles found")
                            .font(.headline)
                        Text("Pull to refresh or check that vehicles were added by this maintenance account's fleet manager.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredVehicles) { vehicle in
                        Button(action: {
                            selectedVehicle = vehicle
                            dismiss()
                        }) {
                            HStack {
                                Text(vehicle.pickerName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if vehicle.id == selectedVehicle?.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                        }
                    }
                }
            }
            .refreshable {
                await loadVehicles()
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search vehicle name or unit")
            .task {
                if vehicles.isEmpty {
                    await loadVehicles()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
