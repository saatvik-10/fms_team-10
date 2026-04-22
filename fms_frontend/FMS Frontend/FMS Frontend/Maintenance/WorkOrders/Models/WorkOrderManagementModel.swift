//
//  WorkOrderManagementModel.swift
//  FMS Frontend
//

import Foundation

enum WorkOrderStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
}

enum WorkOrderPriority: String, Codable, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var sortingOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

struct Part: Identifiable, Codable {
    var id = UUID()
    let name: String
    let description: String
    let iconName: String // SF Symbol or mock image name
    var imageAsset: String? = nil
}

struct WorkOrder: Identifiable, Codable {
    var id = UUID()
    var orderID: String = "WO-\(Int.random(in: 1000...9999))"
    var title: String
    var vehicleName: String
    var vehicleVIN: String
    var odometer: String = "142,503 mi"
    var serviceType: String
    var priority: WorkOrderPriority
    var status: WorkOrderStatus
    var taskDetails: String
    var scheduledDate: Date
    var technicianId: String
    var technicianNotes: String = ""
    var partsNeeded: [Part] = []
    var imageURL: String? = nil
    var imageAsset: String? = nil
    var voiceTranscript: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var proofOfWorkImages: [Data] = []
    var checklist: [InspectionItem] = []
    
    static var standardChecklist: [InspectionItem] {
        [
            InspectionItem(name: "Brake System", verificationCriteria: "Pad thickness and rotor condition", isImageRequired: true),
            InspectionItem(name: "Tire Condition", verificationCriteria: "Tread depth and pressure", isImageRequired: false),
            InspectionItem(name: "Fluid Levels", verificationCriteria: "Oil, coolant, and brake fluid", isImageRequired: false),
            InspectionItem(name: "Lighting & Electrical", verificationCriteria: "Headlights, signals, and battery", isImageRequired: false),
            InspectionItem(name: "Suspension & Steering", verificationCriteria: "Joints, shocks, and alignment", isImageRequired: true)
        ]
    }

    static var mock: WorkOrder {
        WorkOrder(
            title: "Brake Pad Replacement",
            vehicleName: "Mercedes-Benz Actros (Truck)",
            vehicleVIN: "1HGCM8263JA05",
            serviceType: "Routine PM",
            priority: .high,
            status: .inProgress,
            taskDetails: "Driver reports: Squealing sounds coming from front passenger side and noticeably decreased braking efficiency under load. Inspection of rotors required for scoring or heat damage.",
            scheduledDate: Date().addingTimeInterval(86400),
            technicianId: "TECH-01",
            technicianNotes: "Rotors show significant heat discoloration. Recommending full rotor replacement alongside pads.",
            partsNeeded: [
                Part(name: "Ceramic Brake Pads", description: "Primary wear item replacement", iconName: "shippingbox.fill"),
                Part(name: "DOT 4 Fluid", description: "Hydraulic system top-off/flush", iconName: "drop.fill"),
                Part(name: "Front Rotors (2)", description: "Potential replacement for scoring", iconName: "circle.circle.fill")
            ],
            imageAsset: "brake_part",
            voiceTranscript: "Hey, it started happening around mile marker 40. Every time I hit the brakes, there's this high-pitched metal-on-metal sound. The stopping distance feels a bit longer than usual, especially when I'm fully loaded. Sending some photos of the wheel area now.",
            checklist: WorkOrder.standardChecklist
        )
    }
}
