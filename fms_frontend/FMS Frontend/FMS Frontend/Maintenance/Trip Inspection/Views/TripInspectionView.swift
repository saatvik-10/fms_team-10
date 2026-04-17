//
//  TripInspectionView.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI

struct TripInspectionView: View {
    @StateObject private var viewModel = TripInspectionViewModel()
    
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // RESTORED: Standard iOS Segmented Control
                Picker("Status", selection: $viewModel.selectedStatus) {
                    Text("Pending (\(viewModel.inspections.filter { $0.status == .pending }.count))").tag(InspectionStatus.pending)
                    Text("Completed (\(viewModel.inspections.filter { $0.status == .completed }.count))").tag(InspectionStatus.completed)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(.secondarySystemBackground))
    
                List {
                    ForEach(viewModel.filteredInspections) { inspection in
                        ZStack {
                            NavigationLink(destination: VehicleChecklistView(inspection: inspection, viewModel: viewModel)) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            VehicleInspectionCard(inspection: inspection)
                        }
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Inspections")
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let url = viewModel.generatedReportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

struct VehicleInspectionCard: View {
    let inspection: TripInspection
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Status Pillar
            Rectangle()
                .fill(inspection.status == .completed ? AppColors.success : .orange)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    // Vehicle Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(inspection.vehicleId)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("\(inspection.type.rawValue) Checklist")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Vehicle Type Mini Icon
                    Image(systemName: inspection.vehicleType == .truck ? "truck.box" : "car.side")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.secondaryText)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                
                HStack {
                    // Driver Info with custom badge style
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                        Text(inspection.driverId)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AppColors.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(6)
                    
                    Spacer()
                    
                    // Progress integration
                    if inspection.status == .pending {
                        HStack(spacing: 8) {
                            Text("\(Int(inspection.completionPercentage * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(AppColors.primary)
                            
                            ProgressView(value: inspection.completionPercentage)
                                .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                                .frame(width: 60)
                                .scaleEffect(x: 1, y: 1.5)
                        }
                    } else {
                        Label("Finalized", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.success)
                    }
                }
            }
            .padding(16)
            
            // Native-style chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray3))
                .padding(.trailing, 16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct VehicleChecklistView: View {
    let inspection: TripInspection
    @ObservedObject var viewModel: TripInspectionViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingImagePicker = false
    @State private var selectedItemId: UUID?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Progress")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                        Text("\(Int(inspection.completionPercentage * 100))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                    ProgressView(value: inspection.completionPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                        .scaleEffect(x: 1, y: 2)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 8)
            } header: {
                Text("Verification Progress")
            }
            
            Section {
                ForEach(inspection.items) { item in
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text(item.verificationCriteria)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            if item.isImageRequired {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(item.imageData != nil ? AppColors.success : Color.red)
                                    .clipShape(Circle())
                            }
                        }
                        
                        HStack(spacing: 12) {
                            DecisionButton(title: "Pass", isSelected: item.isFulfilled == true, color: AppColors.success) {
                                viewModel.setItemStatus(for: inspection.vehicleId, itemId: item.id, status: true)
                            }
                            
                            DecisionButton(title: "Fail", isSelected: item.isFulfilled == false, color: .red) {
                                viewModel.setItemStatus(for: inspection.vehicleId, itemId: item.id, status: false)
                            }
                        }
                        
                        // Image Section
                        if item.isImageRequired || item.imageData != nil {
                            HStack(spacing: 12) {
                                if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            selectedItemId = item.id
                                            showingImagePicker = true
                                        }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let aiStatus = viewModel.aiVerificationResults[item.id] {
                                            Label(aiStatus, systemImage: aiStatus.contains("Verified") ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(aiStatus.contains("Verified") ? .green : .orange)
                                        }
                                        
                                        Button(action: {
                                            selectedItemId = item.id
                                            showingImagePicker = true
                                        }) {
                                            Text("Update Photo")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(AppColors.primary)
                                        }
                                    }
                                } else {
                                    Button(action: {
                                        selectedItemId = item.id
                                        showingImagePicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "camera.viewfinder")
                                            Text("Required Photo")
                                        }
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(AppColors.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(AppColors.primary.opacity(0.05))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(AppColors.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .listRowBackground(Color.white)
                }
            } header: {
                Text("Verification Checklist")
            }
            
            if inspection.status == .pending {
                Section {
                    VStack(spacing: 8) {
                        PrimaryButton(title: "Finalize & Generate PDF", action: {
                            viewModel.submitInspection(for: inspection.vehicleId)
                        }, isLoading: viewModel.isSubmitting)
                        
                        Text("Mandatory items and photos must be provided.")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(inspection.vehicleId)
        .sheet(isPresented: $showingImagePicker) {
            if let itemId = selectedItemId {
                ImagePicker(imageData: Binding(
                    get: { inspection.items.first(where: { $0.id == itemId })?.imageData },
                    set: { viewModel.setImage(for: inspection.vehicleId, itemId: itemId, imageData: $0) }
                ), sourceType: .photoLibrary)
            }
        }
        .alert(isPresented: $viewModel.showSuccessAlert) {
            Alert(
                title: Text("Report Finalized"),
                message: Text("The inspection record has been stored and a PDF has been added to your reports."),
                dismissButton: .default(Text("Done")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct DecisionButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? color : Color.gray.opacity(0.05))
                .foregroundColor(isSelected ? .white : AppColors.primaryText)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
