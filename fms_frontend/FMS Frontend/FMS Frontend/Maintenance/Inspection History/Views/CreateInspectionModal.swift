//
//  CreateInspectionModal.swift
//  Created by Akhilesh Mykalwar
//

import SwiftUI

struct CreateInspectionModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    @StateObject private var viewModel = CreateInspectionViewModel()
    var isEmergency: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F9FB").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormGroup(title: "INSPECTION TITLE") {
                            TextField("Enter title (e.g. Trip to California)", text: $viewModel.title)
                                .font(.system(size: 16))
                        }

                        FormGroup(title: "SELECT VEHICLE") {
                            Button(action: { viewModel.showingVehiclePicker = true }) {
                                HStack {
                                    Text(viewModel.unitName)
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
                            Picker("Type", selection: $viewModel.inspectionType) {
                                ForEach([InspectionType.preTrip, InspectionType.postTrip], id: \.self) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        FormGroup(title: "PHOTOS") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<viewModel.selectedImages.count, id: \.self) { index in
                                        Image(uiImage: viewModel.selectedImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(12)
                                            .overlay(
                                                Button(action: { viewModel.selectedImages.remove(at: index) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.5))
                                                        .clipShape(Circle())
                                                }
                                                .padding(4),
                                                alignment: .topTrailing
                                            )
                                    }
                                    
                                    Button(action: { viewModel.showingSourceSelect = true }) {
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
                            TextEditor(text: $viewModel.notes)
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
            .confirmationDialog("Add Photo", isPresented: $viewModel.showingSourceSelect) {
                Button("Camera") { viewModel.showingCamera = true }
                Button("Photo Library") { viewModel.showingImagePicker = true }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $viewModel.showingVehiclePicker) {
                NavigationStack {
                    List {
                        ForEach(viewModel.units.filter { viewModel.vehicleSearchText.isEmpty || $0.localizedCaseInsensitiveContains(viewModel.vehicleSearchText) }, id: \.self) { vehicle in
                            Button(action: {
                                viewModel.unitName = vehicle
                                viewModel.showingVehiclePicker = false
                            }) {
                                HStack {
                                    Text(vehicle)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if viewModel.unitName == vehicle {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppColors.primary)
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $viewModel.vehicleSearchText, prompt: "Search vehicles")
                    .navigationTitle("Select Vehicle")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") { viewModel.showingVehiclePicker = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.showingImagePicker) {
                PhotoPicker(images: $viewModel.selectedImages)
            }
            .sheet(isPresented: $viewModel.showingCamera) {
                CameraPicker(image: Binding(
                    get: { nil },
                    set: { if let img = $0 { viewModel.selectedImages.append(img) } }
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
                        viewModel.createInspection(store: store, isEmergency: isEmergency, dismiss: { dismiss() })
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
