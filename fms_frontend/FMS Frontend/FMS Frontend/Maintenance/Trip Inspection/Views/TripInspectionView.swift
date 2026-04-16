//
//  TripInspectionView.swift
//  FMS Frontend
//

import SwiftUI

struct TripInspectionView: View {
    @StateObject private var viewModel = TripInspectionViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented Picker for Status
            Picker("Inspection Status", selection: $viewModel.selectedStatus) {
                Text("Pending").tag(InspectionStatus.pending)
                Text("Completed").tag(InspectionStatus.completed)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color.white)
            
            List {
                ForEach(viewModel.filteredInspections) { inspection in
                    NavigationLink(destination: VehicleChecklistView(inspection: inspection, viewModel: viewModel)) {
                        VehicleInspectionCard(inspection: inspection)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .background(AppColors.screenBackground)
        }
        .navigationTitle("Inspections")
    }
}

struct VehicleInspectionCard: View {
    let inspection: TripInspection
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    // Vehicle Icon based on Type
                    Image(systemName: inspection.vehicleType == .truck ? "truck.box.fill" : "car.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(colors: [AppColors.primary, AppColors.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(inspection.vehicleId)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("\(inspection.type.rawValue) Verification")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    StatusBadge(text: inspection.status.rawValue, color: inspection.status == .completed ? AppColors.success : .orange)
                }
                
                // Content: Driver and Status
                HStack {
                    Label("Driver ID: \(inspection.driverId)", systemImage: "person.circle")
                    Spacer()
                    if inspection.status == .pending {
                        Text("\(Int(inspection.completionPercentage * 100))% Done")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(AppColors.secondaryText)
                
                // Progress Indicator
                if inspection.status == .pending {
                    ProgressView(value: inspection.completionPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

struct VehicleChecklistView: View {
    let inspection: TripInspection
    @ObservedObject var viewModel: TripInspectionViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Overall Verification")
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
                Text("REPORT PROGRESS")
            }
            
            Section {
                ForEach(inspection.items) { item in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text(item.verificationCriteria)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 12) {
                            DecisionButton(title: "Fulfilled", isSelected: item.isFulfilled == true, color: AppColors.success) {
                                viewModel.setItemStatus(for: inspection.vehicleId, itemId: item.id, status: true)
                            }
                            
                            DecisionButton(title: "Not Fulfilled", isSelected: item.isFulfilled == false, color: .red) {
                                viewModel.setItemStatus(for: inspection.vehicleId, itemId: item.id, status: false)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(Color.white)
                }
            } header: {
                Text("VEHICLE CRITERIA")
            }
            
            if inspection.status == .pending {
                Section {
                    PrimaryButton(title: "Finalize Report", action: {
                        viewModel.submitInspection(for: inspection.vehicleId)
                    }, isLoading: viewModel.isSubmitting)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(inspection.vehicleId)
        .alert(isPresented: $viewModel.showSuccessAlert) {
            Alert(
                title: Text("Report Finalized"),
                message: Text("The comprehensive vehicle report has been successfully submitted."),
                dismissButton: .default(Text("OK")) {
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
                .background(isSelected ? color : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : AppColors.primaryText)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct TripInspectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TripInspectionView()
        }
    }
}
