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
    
    var completionPercentage: Double {
        let checked = items.filter { $0.result != .pending }.count
        return Double(checked) / Double(items.count)
    }
    
    static func mockItems(for type: VehicleType) -> [InspectionItem] {
        var items = [
            InspectionItem(
                name: "Braking System",
                verificationCriteria: "Pad thickness > 4mm. No leaks in air/hydraulic lines.",
                result: .good,
                isImageRequired: true
            ),
            InspectionItem(
                name: "Tire Integrity",
                verificationCriteria: "Tread depth > 4/32\". No sidewall bulges or deep cuts.",
                result: .pending,
                isImageRequired: true
            ),
            InspectionItem(
                name: "Engine & Fluid Levels",
                verificationCriteria: "Oil, coolant, and washer fluid at MAX. No active leaks.",
                result: .good,
                isImageRequired: true
            ),
            InspectionItem(
                name: "Lighting & Signals",
                verificationCriteria: "Headlights, hazards, and brake lights fully functional.",
                result: .good,
                isImageRequired: false
            ),
            InspectionItem(
                name: "Steering & Suspension",
                verificationCriteria: "No excessive play in wheel. Shock absorbers dry.",
                result: .pending,
                isImageRequired: false
            ),
            InspectionItem(
                name: "Safety Equipment",
                verificationCriteria: "Fire extinguisher charged. Triangles and vest present.",
                result: .good,
                isImageRequired: true
            )
        ]
        
        return items
    }
}
