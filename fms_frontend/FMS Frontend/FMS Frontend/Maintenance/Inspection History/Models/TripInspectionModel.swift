//
//  TripInspectionModel.swift
//  FMS Frontend
//

import Foundation

enum InspectionType: String, Codable {
    case preTrip = "Pre-Trip"
    case postTrip = "Post-Trip"
    case maintenance = "Maintenance Audit"
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
        switch type {
        case .truck:
            return [
                InspectionItem(name: "Braking System", verificationCriteria: "Check pad thickness (>3mm), rotor scoring, and air pressure build-up.", result: .pending, isImageRequired: true),
                InspectionItem(name: "Steering & Suspension", verificationCriteria: "Check power steering fluid, kingpins, and leaf spring integrity.", result: .pending, isImageRequired: false),
                InspectionItem(name: "Engine & Drivetrain", verificationCriteria: "Inspect for oil leaks, coolant levels, and belt tension.", result: .pending, isImageRequired: true),
                InspectionItem(name: "Wheels & Tyres", verificationCriteria: "Check tread depth (>1.6mm), PSI levels, and wheel nut torque.", result: .pending, isImageRequired: true),
                InspectionItem(name: "Lights & Electrical", verificationCriteria: "Verify all external lights, dashboard indicators, and battery terminals.", result: .pending, isImageRequired: false),
                InspectionItem(name: "Chassis & Coupling", verificationCriteria: "Inspect 5th wheel plate lubrication and chassis cross-members.", result: .pending, isImageRequired: false)
            ]
        case .car: // Using for Buses/Lighter vehicles
            return [
                InspectionItem(name: "Passenger Safety", verificationCriteria: "Check seatbelts, emergency exits, and interior lighting.", result: .pending, isImageRequired: true),
                InspectionItem(name: "Braking & ABS", verificationCriteria: "Verify pedal feel, fluid level, and ABS warning lights.", result: .pending, isImageRequired: false),
                InspectionItem(name: "Tyre Condition", verificationCriteria: "Check for sidewall damage and uniform wear patterns.", result: .pending, isImageRequired: true),
                InspectionItem(name: "Fluid Levels", verificationCriteria: "Check engine oil, coolant, and washer fluid.", result: .pending, isImageRequired: false),
                InspectionItem(name: "HVAC System", verificationCriteria: "Test air conditioning flow and heater core operation.", result: .pending, isImageRequired: false),
                InspectionItem(name: "External Signals", verificationCriteria: "Check indicators, brake lights, and reverse alarm.", result: .pending, isImageRequired: false)
            ]
        }
    }
}
