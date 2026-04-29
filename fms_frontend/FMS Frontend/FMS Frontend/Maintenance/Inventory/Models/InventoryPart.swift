//
//  InventoryPart.swift
//  FMS Frontend
//
//  Created by opencode on 21/04/26.
//

import Foundation

struct InventoryPart: Identifiable, Codable {
    let id: UUID
    let partName: String
    let partId: String
    let category: String
    var stockQty: Int
    var minStock: Int
    let unitPriceInr: Double
    let supplier: String
    let vehicleType: String
    let location: String
    
    init(
        id: UUID = UUID(),
        partName: String,
        partId: String,
        category: String,
        stockQty: Int,
        minStock: Int = 10,
        unitPriceInr: Double,
        supplier: String = "N/A",
        vehicleType: String = "N/A",
        location: String = "N/A"
    ) {
        self.id = id
        self.partName = partName
        self.partId = partId
        self.category = category
        self.stockQty = stockQty
        self.minStock = minStock
        self.unitPriceInr = unitPriceInr
        self.supplier = supplier
        self.vehicleType = vehicleType
        self.location = location
    }
    
    var totalValue: Double {
        return Double(stockQty) * unitPriceInr
    }
    
    var isLowStock: Bool {
        return stockQty <= minStock
    }
}
