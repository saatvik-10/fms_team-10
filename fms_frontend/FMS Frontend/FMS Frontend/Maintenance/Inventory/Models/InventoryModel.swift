//
//  InventoryModel.swift
//  FMS Frontend
//

import Foundation

struct InventoryItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let sku: String
    let description: String
    let category: String
    var currentQuantity: Int
    var minThreshold: Int
    var location: String // Aisle-Shelf-Bin
    var unitCost: Double
    var vendorInfo: String
    var leadTimeDays: Int
    var imageAsset: String?
}

struct UsageStatistic: Identifiable {
    var id = UUID()
    let partName: String
    let totalUsed: Int
    let period: String // e.g., "Last 30 Days"
}
