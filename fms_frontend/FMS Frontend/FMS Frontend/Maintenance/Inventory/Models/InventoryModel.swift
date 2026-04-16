//
//  InventoryModel.swift
//  FMS Frontend
//

import Foundation

enum InventoryCategory: String, Codable, CaseIterable {
    case spareParts = "Spare Parts"
    case fluids = "Fluids"
    case tools = "Tools"
    case tires = "Tires"
}

struct InventoryItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    var quantity: Int
    let unit: String // e.g., Liters, Units, Sets
    let category: InventoryCategory
    let reorderLevel: Int
    let lastRestockDate: Date
    
    var isLowStock: Bool {
        quantity <= reorderLevel
    }
}

// Extension for Mock Data
extension InventoryItem {
    static var mockItems: [InventoryItem] {
        [
            InventoryItem(name: "DOT 4 Brake Fluid", quantity: 5, unit: "L", category: .fluids, reorderLevel: 10, lastRestockDate: Date().addingTimeInterval(-86400 * 30)),
            InventoryItem(name: "OW-20 Synthetic Oil", quantity: 45, unit: "L", category: .fluids, reorderLevel: 20, lastRestockDate: Date().addingTimeInterval(-86400 * 5)),
            InventoryItem(name: "Brake Pads (Front)", quantity: 12, unit: "Sets", category: .spareParts, reorderLevel: 5, lastRestockDate: Date().addingTimeInterval(-86400 * 15)),
            InventoryItem(name: "Oil Filter (Universal)", quantity: 25, unit: "Units", category: .spareParts, reorderLevel: 10, lastRestockDate: Date().addingTimeInterval(-86400 * 2)),
            InventoryItem(name: "All-Season Tires", quantity: 4, unit: "Units", category: .tires, reorderLevel: 8, lastRestockDate: Date().addingTimeInterval(-86400 * 60)),
            InventoryItem(name: "Hydraulic Jack", quantity: 2, unit: "Units", category: .tools, reorderLevel: 1, lastRestockDate: Date().addingTimeInterval(-86400 * 100))
        ]
    }
}
