//
//  CreateInspectionModal.swift
//  FMS Frontend
//

import SwiftUI

struct CreateInspectionModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    var isEmergency: Bool
    
    @State private var unitName = "Unit 842-Alpha"
    @State private var inspectionType: InspectionType = .preTrip
    @State private var notes = ""
    
    let units = ["Unit 842-Alpha", "Unit 319-Echo", "Unit 115-Delta", "Unit 990-Zeta"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F9FB").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Box
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isEmergency ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Image(systemName: isEmergency ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                                    .foregroundColor(isEmergency ? .red : .blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isEmergency ? "Emergency Inspection" : "Routine Inspection")
                                    .font(.system(size: 16, weight: .bold))
                                Text(isEmergency ? "Prioritizing critical safety checks." : "Standard vehicle health verification.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        
                        // Fields
                        FormGroup(title: "SELECT UNIT") {
                            Picker("Unit", selection: $unitName) {
                                ForEach(units, id: \.self) { Text($0) }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        FormGroup(title: "INSPECTION TYPE") {
                            Picker("Type", selection: $inspectionType) {
                                ForEach([InspectionType.preTrip, InspectionType.postTrip], id: \.self) { 
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        FormGroup(title: "ADDITIONAL NOTES") {
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .font(.system(size: 14))
                        }
                        
                        PrimaryButton(title: "Start Inspection") {
                            let newInspection = TripInspection(
                                vehicleId: "V-\(Int.random(in: 100...999))",
                                unitName: unitName,
                                unitVIN: "VIN-\(Int.random(in: 1000...9999))",
                                driverId: "DRV-CURRENT",
                                timestamp: Date(),
                                type: inspectionType,
                                vehicleType: .truck,
                                status: .pending,
                                items: TripInspection.mockItems(for: .truck),
                                notes: notes,
                                maintenanceStaffId: "STAFF-01",
                                isEmergency: isEmergency
                            )
                            store.addInspection(newInspection)
                            dismiss()
                        }
                        .padding(.top, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(isEmergency ? "Emergency Request" : "New Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
