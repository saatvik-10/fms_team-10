//
//  TripInspectionViewModel.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI
import Combine
import Vision

class TripInspectionViewModel: ObservableObject {
    // Published properties so SwiftUI updates the view
    @Published var inspections: [TripInspection] = [
        TripInspection(vehicleId: "V-TRUCK-01", unitName: "Unit 842-Alpha", unitVIN: "1HGCM8263JA05", driverId: "D-92", timestamp: Date(), type: .preTrip, vehicleType: .truck, status: .pending, items: TripInspection.mockItems(for: .truck), maintenanceStaffId: "M-1"),
        TripInspection(vehicleId: "V-CAR-05", unitName: "Unit 319-Echo", unitVIN: "3VWCP1192BM10", driverId: "D-11", timestamp: Date(), type: .preTrip, vehicleType: .car, status: .pending, items: TripInspection.mockItems(for: .car), maintenanceStaffId: "M-1"),
        TripInspection(vehicleId: "V-TRUCK-02", unitName: "Unit 115-Delta", unitVIN: "JTMBU4230L901", driverId: "D-44", timestamp: Date(), type: .postTrip, vehicleType: .truck, status: .completed, items: TripInspection.mockItems(for: .truck), maintenanceStaffId: "M-1")
    ]
    
    @Published var selectedStatus: InspectionStatus = .pending
    @Published var isSubmitting: Bool = false
    @Published var showSuccessAlert: Bool = false
    @Published var aiVerificationResults: [UUID: String] = [:]
    
    @Published var generatedReportURL: URL?
    @Published var showingShareSheet: Bool = false
    
    var filteredInspections: [TripInspection] {
        inspections.filter { $0.status == selectedStatus }
    }
    
    func setItemResult(for vehicleId: String, itemId: UUID, result: InspectionResult) {
        if let vIndex = inspections.firstIndex(where: { $0.vehicleId == vehicleId }),
           let iIndex = inspections[vIndex].items.firstIndex(where: { $0.id == itemId }) {
            inspections[vIndex].items[iIndex].result = result
        }
    }
    
    func setImage(for vehicleId: String, itemId: UUID, imageData: Data?) {
        if let vIndex = inspections.firstIndex(where: { $0.vehicleId == vehicleId }),
           let iIndex = inspections[vIndex].items.firstIndex(where: { $0.id == itemId }) {
            inspections[vIndex].items[iIndex].imageData = imageData
            
            if let data = imageData {
                performAIVerification(for: itemId, data: data)
            }
        }
    }
    
    private func performAIVerification(for itemId: UUID, data: Data) {
        guard let image = UIImage(data: data), let ciImage = CIImage(image: image) else { return }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation] else { return }
            
            let topClassifications = results.prefix(10)
            let isVehicleRelated = topClassifications.contains { 
                let id = $0.identifier.lowercased()
                return id.contains("car") || id.contains("truck") || id.contains("tire") || id.contains("wheel") || id.contains("mechanical")
            }
            
            DispatchQueue.main.async {
                self?.aiVerificationResults[itemId] = isVehicleRelated ? "AI Verified: Component found" : "AI Warning: Item unrecognized"
            }
        }
        
        do {
            try handler.perform([request])
        } catch {
            print("Vision request failed: \(error)")
        }
    }
    
    func submitInspection(for vehicleId: String) {
        if let index = inspections.firstIndex(where: { $0.vehicleId == vehicleId }) {
            let inspection = inspections[index]
            
            // Validation
            let allChecked = inspection.items.allSatisfy { $0.result != .pending }
            let mandatoryImagesPresent = inspection.items.filter { $0.isImageRequired }.allSatisfy { $0.imageData != nil }
            
            if !allChecked || !mandatoryImagesPresent {
                print("Validation failed: items=\(allChecked), images=\(mandatoryImagesPresent)")
                return
            }
            
            isSubmitting = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                // 1. Mark as completed
                self.inspections[index].status = .completed
                
                // 2. Generate PDF
                if let tempURL = PDFService.shared.generateInspectionReport(inspection: self.inspections[index]) {
                    // 3. Move to permanent Documents directory
                    let fileManager = FileManager.default
                    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let permanentURL = documentsURL.appendingPathComponent(tempURL.lastPathComponent)
                    
                    try? fileManager.moveItem(at: tempURL, to: permanentURL)
                    
                    self.generatedReportURL = permanentURL
                    self.showingShareSheet = true
                }
                
                self.isSubmitting = false
                self.showSuccessAlert = true
            }
        }
    }
}
