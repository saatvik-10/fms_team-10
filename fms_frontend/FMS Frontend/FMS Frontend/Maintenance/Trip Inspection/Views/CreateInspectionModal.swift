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
    @State private var notes = ""

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
                        FormGroup(title: "SELECT VEHICLE") {
                            Picker("Vehicle", selection: $unitName) {
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
                            let vehicleType: VehicleType = unitName.contains("Bus") ? .car : .truck
                            let newInspection = TripInspection(
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
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let vehicleType: VehicleType = unitName.contains("Bus") ? .car : .truck
                        let newInspection = TripInspection(
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
                        store.addInspection(newInspection)
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
