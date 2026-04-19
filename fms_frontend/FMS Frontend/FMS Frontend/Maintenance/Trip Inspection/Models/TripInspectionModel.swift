//
//  TripInspectionModel.swift
//  FMS Frontend
//

import Foundation

enum InspectionType: String, Codable {
    case preTrip = "Pre-Trip"
    case postTrip = "Post-Trip"
}

enum VehicleType: String, Codable {
    case car = "Car"
    case truck = "Truck"
}

enum InspectionStatus: String, Codable {
    case pending = "Pending"
    case completed = "Completed"
}

enum InspectionResult: String, Codable {
    case good = "GOOD"
    case repair = "REPAIR"
    case alert = "ALERT"
    case pending = "PENDING"
}

struct InspectionItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let verificationCriteria: String
    var result: InspectionResult = .pending
    var imageData: Data?
    var isImageRequired: Bool
    var notes: String = ""
}

struct TripInspection: Identifiable, Codable {
    var id = UUID()
    var title: String = ""
    let vehicleId: String
    let unitName: String
    let unitVIN: String
    let driverId: String
    let timestamp: Date
    let type: InspectionType
    let vehicleType: VehicleType
    var status: InspectionStatus
    var items: [InspectionItem]
    var notes: String?
    var maintenanceStaffId: String
    var isEmergency: Bool = false
    
    // Metrics for the new layout
    var odometer: String = "142,503 mi"
    var fuelLevel: String = "75%"
    var efficiency: String = "14.2 mpg"
    var engineHours: String = "4,821 hrs"
    var imageAsset: String? = nil
    var imagesData: [Data] = []
    var imageAnalyses: [String] = []
    
    var completionPercentage: Double {
        let checked = items.filter { $0.result != .pending }.count
        return Double(checked) / Double(items.count)
    }
    
    static func mockItems(for type: VehicleType) -> [InspectionItem] {
        return [
            InspectionItem(
                name: "Brakes & Steering",
                verificationCriteria: "Check brake pad thickness, steering play, and brake fluid.",
                result: .pending,
                isImageRequired: true
            ),
            InspectionItem(
                name: "Engine & Fluids",
                verificationCriteria: "Check oil, coolant levels, and any active leaks.",
                result: .pending,
                isImageRequired: false
            ),
            InspectionItem(
                name: "Lights & Signals",
                verificationCriteria: "Check headlights, indicators, hazard and brake lights.",
                result: .pending,
                isImageRequired: false
            ),
            InspectionItem(
                name: "Tyres & Body",
                verificationCriteria: "Check tread depth, tire pressure, and body damage.",
                result: .pending,
                isImageRequired: true
            )
        ]
    }
}
