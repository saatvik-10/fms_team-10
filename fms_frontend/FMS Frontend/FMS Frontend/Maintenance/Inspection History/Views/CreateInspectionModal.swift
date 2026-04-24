//
//  CreateInspectionModal.swift
//  FMS Frontend
//

import SwiftUI

struct CreateInspectionModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    var isEmergency: Bool

    @State private var unitName = "Mercedes-Benz Actros (Truck)"
    @State private var inspectionType: InspectionType = .preTrip
    @State private var title = ""
    @State private var notes = ""
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingSourceSelect = false
    @State private var showingVehiclePicker = false
    @State private var vehicleSearchText = ""

    let units = [
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

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F9FB").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Fields
                        FormGroup(title: "INSPECTION TITLE") {
                            TextField("Enter title (e.g. Trip to California)", text: $title)
                                .font(.system(size: 16))
                        }

                        FormGroup(title: "SELECT VEHICLE") {
                            Button(action: { showingVehiclePicker = true }) {
                                HStack {
                                    Text(unitName)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        FormGroup(title: "INSPECTION TYPE") {
                            Picker("Type", selection: $inspectionType) {
                                ForEach([InspectionType.preTrip, InspectionType.postTrip], id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        FormGroup(title: "PHOTOS") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<selectedImages.count, id: \.self) { index in
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(12)
                                            .overlay(
                                                Button(action: { selectedImages.remove(at: index) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.5))
                                                        .clipShape(Circle())
                                                }
                                                .padding(4),
                                                alignment: .topTrailing
                                            )
                                    }
                                    
                                    Button(action: { showingSourceSelect = true }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 20, weight: .semibold))
                                            Text("Add")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .frame(width: 80, height: 80)
                                        .background(Color(.systemGray6))
                                        .foregroundColor(AppColors.primary)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppColors.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                        )
                                    }
                                }
                            }
                        }

                        FormGroup(title: "ADDITIONAL NOTES") {
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .font(.system(size: 14))
                        }
                    }
                    .padding()
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(isEmergency ? "Emergency Request" : "New Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Add Photo", isPresented: $showingSourceSelect) {
                Button("Camera") { showingCamera = true }
                Button("Photo Library") { showingImagePicker = true }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingVehiclePicker) {
                NavigationStack {
                    List {
                        ForEach(units.filter { vehicleSearchText.isEmpty || $0.localizedCaseInsensitiveContains(vehicleSearchText) }, id: \.self) { vehicle in
                            Button(action: {
                                unitName = vehicle
                                showingVehiclePicker = false
                            }) {
                                HStack {
                                    Text(vehicle)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if unitName == vehicle {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppColors.primary)
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $vehicleSearchText, prompt: "Search vehicles")
                    .navigationTitle("Select Vehicle")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") { showingVehiclePicker = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotoPicker(images: $selectedImages)
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker(image: Binding(
                    get: { nil },
                    set: { if let img = $0 { selectedImages.append(img) } }
                ))
            }
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
                        let vehicleType: VehicleType = unitName.contains("Bus") ? .car : .truck
                        var newInspection = TripInspection(
                            title: title.isEmpty ? inspectionType.rawValue : title,
                            vehicleId: "V-\(Int.random(in: 100...999))",
                            unitName: unitName,
                            unitVIN: "VIN-\(Int.random(in: 1000...9999))",
                            driverId: "DRV-CURRENT",
                            timestamp: Date(),
                            type: inspectionType,
                            vehicleType: vehicleType,
                            status: .pending,
                            items: TripInspection.mockItems(for: vehicleType),
                            notes: notes,
                            maintenanceStaffId: "STAFF-01",
                            isEmergency: isEmergency
                        )
                        
                        // Convert images to data and set placeholders
                        newInspection.imagesData = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
                        newInspection.imageAnalyses = Array(repeating: "Analysis in progress...", count: selectedImages.count)
                        
                        store.addInspection(newInspection)
                        
                        // Trigger Mock AI Analysis
                        let capturedImages = selectedImages
                        let inspectionId = newInspection.id
                        for (index, image) in capturedImages.enumerated() {
                            AIAnalysisService.analyze(image: image) { result in
                                store.updateInspectionAnalysis(id: inspectionId, index: index, analysis: result)
                            }
                        }
                        
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
        }
    }
}
