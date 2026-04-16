//
//  TripInspectionViewModel.swift
//  FMS Frontend
//

import SwiftUI
import Combine

class TripInspectionViewModel: ObservableObject {
    // Published properties so SwiftUI updates the view
    @Published var inspections: [TripInspection] = [
        TripInspection(vehicleId: "V-TRUCK-01", driverId: "D-92", timestamp: Date(), type: .preTrip, vehicleType: .truck, status: .pending, items: TripInspection.mockItems(for: .truck), maintenanceStaffId: "M-1"),
        TripInspection(vehicleId: "V-CAR-05", driverId: "D-11", timestamp: Date(), type: .preTrip, vehicleType: .car, status: .pending, items: TripInspection.mockItems(for: .car), maintenanceStaffId: "M-1"),
        TripInspection(vehicleId: "V-TRUCK-02", driverId: "D-44", timestamp: Date(), type: .postTrip, vehicleType: .truck, status: .completed, items: TripInspection.mockItems(for: .truck), maintenanceStaffId: "M-1")
    ]
    
    @Published var selectedStatus: InspectionStatus = .pending
    @Published var isSubmitting: Bool = false
    @Published var showSuccessAlert: Bool = false
    
    var filteredInspections: [TripInspection] {
        inspections.filter { $0.status == selectedStatus }
    }
    
    func setItemStatus(for vehicleId: String, itemId: UUID, status: Bool?) {
        if let vIndex = inspections.firstIndex(where: { $0.vehicleId == vehicleId }),
           let iIndex = inspections[vIndex].items.firstIndex(where: { $0.id == itemId }) {
            inspections[vIndex].items[iIndex].isFulfilled = status
        }
    }
    
    func submitInspection(for vehicleId: String) {
        if let index = inspections.firstIndex(where: { $0.vehicleId == vehicleId }) {
            isSubmitting = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.inspections[index].status = .completed
                self.isSubmitting = false
                self.showSuccessAlert = true
            }
        }
    }
}
