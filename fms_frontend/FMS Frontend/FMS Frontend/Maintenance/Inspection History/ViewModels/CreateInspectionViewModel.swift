//
//  CreateInspectionViewModel.swift
//  Created by Gargee Mohairr
//

import SwiftUI

class CreateInspectionViewModel: ObservableObject {
    @Published var unitName = "Mercedes-Benz Actros (Truck)"
    @Published var inspectionType: InspectionType = .preTrip
    @Published var title = ""
    @Published var notes = ""
    @Published var selectedImages: [UIImage] = []
    @Published var showingImagePicker = false
    @Published var showingCamera = false
    @Published var showingSourceSelect = false
    @Published var showingVehiclePicker = false
    @Published var vehicleSearchText = ""

    let units = [
        "Mercedes-Benz Actros (Truck)", "Volvo FH16 (Truck)", "MAN TGX (Truck)", "Scania R450 (Truck)",
        "Toyota Coaster (Bus)", "Tata Starbus (Bus)", "BharatBenz 1617 (Bus)", "Ashok Leyland Lynx (Bus)",
        "Ford Transit (Van)", "Mercedes-Benz Sprinter (Van)", "Toyota HiAce (Van)", "Toyota Land Cruiser (SUV)",
        "Ford Ranger (Pickup)", "Isuzu D-Max (Pickup)"
    ]

    func createInspection(store: MaintenanceStore, isEmergency: Bool, dismiss: @escaping () -> Void) {
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
            status: .progress,
            items: TripInspection.mockItems(for: vehicleType),
            notes: notes,
            maintenanceStaffId: "STAFF-01",
            isEmergency: isEmergency
        )
        
        newInspection.imagesData = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
        newInspection.imageAnalyses = Array(repeating: "Analysis in progress...", count: selectedImages.count)
        
        store.addInspection(newInspection)
        
        let capturedImages = selectedImages
        let inspectionId = newInspection.id
        for (index, image) in capturedImages.enumerated() {
            AIAnalysisService.analyze(image: image) { result in
                store.updateInspectionAnalysis(id: inspectionId, index: index, analysis: result)
            }
        }
        
        print("[SUCCESS] [SUCCESS] Inspection created: \(newInspection.id)")
        dismiss()
    }
}
