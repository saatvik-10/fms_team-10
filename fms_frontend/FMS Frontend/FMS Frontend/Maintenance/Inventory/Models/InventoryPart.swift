//
//  InventoryPart.swift
//  FMS Frontend
//
//  Created by opencode on 21/04/26.
//

import Foundation

struct InventoryPart: Identifiable, Codable {
    let id: UUID
    let name: String
    let sku: String
    let description: String
    let category: String
    let stockCount: Int
    let unitCost: Double
    var reorderThreshold: Int
    let usageLast30Days: Int
    let vendorName: String
    let vendorPhone: String
    let vendorEmail: String
    let averageLeadTimeDays: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        sku: String,
        description: String,
        category: String,
        stockCount: Int,
        unitCost: Double,
        reorderThreshold: Int = 10,
        usageLast30Days: Int = 0,
        vendorName: String = "N/A",
        vendorPhone: String = "N/A",
        vendorEmail: String = "N/A",
        averageLeadTimeDays: Int = 0
    ) {
        self.id = id
        self.name = name
        self.sku = sku
        self.description = description
        self.category = category
        self.stockCount = stockCount
        self.unitCost = unitCost
        self.reorderThreshold = reorderThreshold
        self.usageLast30Days = usageLast30Days
        self.vendorName = vendorName
        self.vendorPhone = vendorPhone
        self.vendorEmail = vendorEmail
        self.averageLeadTimeDays = averageLeadTimeDays
    }
    
    var totalValue: Double {
        return Double(stockCount) * unitCost
    }
    
    var isLowStock: Bool {
        return stockCount <= reorderThreshold
    }
}
