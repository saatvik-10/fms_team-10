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

struct InspectionItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let verificationCriteria: String // e.g., "Fluid level between MIN and MAX"
    var isFulfilled: Bool?           // nil = pending, true = Yes, false = No
}

struct TripInspection: Identifiable, Codable {
    var id = UUID()
    let vehicleId: String
    let driverId: String
    let timestamp: Date
    let type: InspectionType
    let vehicleType: VehicleType
    var status: InspectionStatus
    var items: [InspectionItem]
    var notes: String?
    var maintenanceStaffId: String
    
    var completionPercentage: Double {
        let checked = items.filter { $0.isFulfilled != nil }.count
        return Double(checked) / Double(items.count)
    }
    
    static func mockItems(for type: VehicleType) -> [InspectionItem] {
        var items = [
            InspectionItem(
                name: "Brake Fluid",
                verificationCriteria: "Fluid level between MIN and MAX marks. Amber/clear color.",
                isFulfilled: nil
            ),
            InspectionItem(
                name: "Engine Oil",
                verificationCriteria: "Dipstick reading within cross-hatched area. No major leaks.",
                isFulfilled: true
            ),
            InspectionItem(
                name: "Lights & Indicators",
                verificationCriteria: "All headlights, brake lights, and hazards operational.",
                isFulfilled: nil
            )
        ]
        
        if type == .truck {
            items.append(
                InspectionItem(
                    name: "Trailer Connection",
                    verificationCriteria: "Fifth wheel jaw locked. Air lines secure. Safety pin engaged.",
                    isFulfilled: false
                )
            )
        }
        
        return items
    }
}
