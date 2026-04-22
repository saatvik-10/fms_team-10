//
//  InventoryCSVImportService.swift
//  FMS Frontend
//
//  Created by opencode on 21/04/26.
//

import Foundation

class InventoryCSVImportService {
    static let shared = InventoryCSVImportService()
    
    struct ImportError: Identifiable {
        let id = UUID()
        let row: Int
        let reason: String
    }
    
    func parseCSV(at url: URL) -> (parts: [InventoryPart], errors: [ImportError]) {
        var parts: [InventoryPart] = []
        var errors: [ImportError] = []
        
        let didAccessSecurityScopedResource = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            let lines = data.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            guard lines.count > 1 else {
                errors.append(ImportError(row: 0, reason: "File is empty or missing headers."))
                return (parts, errors)
            }
            
            let headers = lines[0].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            
            // Required: Name, SKU, Description, Category, No of Stock, Unit Cost
            let nameIdx = headers.firstIndex(of: "name")
            let skuIdx = headers.firstIndex(of: "sku")
            let descIdx = headers.firstIndex(of: "description")
            let catIdx = headers.firstIndex(of: "category")
            let stockIdx = headers.firstIndex(where: { $0.contains("stock") || $0.contains("no of stock") })
            let costIdx = headers.firstIndex(where: { $0.contains("cost") || $0.contains("unit cost") })

            // Optional: Usage + Vendor + Lead time
            let usageIdx = headers.firstIndex(where: { $0.contains("usage last 30 days") || $0.contains("usage") })
            let vendorNameIdx = headers.firstIndex(where: { $0.contains("vendor name") })
            let vendorPhoneIdx = headers.firstIndex(where: { $0.contains("vendor phone") })
            let vendorEmailIdx = headers.firstIndex(where: { $0.contains("vendor email") })
            let leadTimeIdx = headers.firstIndex(where: { $0.contains("average lead time days") || $0.contains("lead time") })
            
            guard let ni = nameIdx, let si = skuIdx, let di = descIdx, let ci = catIdx, let sti = stockIdx, let coi = costIdx else {
                errors.append(ImportError(row: 1, reason: "Missing required headers. Ensure Name, SKU, Description, Category, No of Stock, and Unit Cost are present."))
                return (parts, errors)
            }
            
            for (index, line) in lines.enumerated() {
                if index == 0 { continue } // Skip header row
                
                let columns = parseCSVRow(line)
                let rowNum = index + 1
                
                if columns.count <= max(ni, si, di, ci, sti, coi) {
                    errors.append(ImportError(row: rowNum, reason: "Incomplete row data."))
                    continue
                }
                
                let name = columns[ni].trimmingCharacters(in: .whitespaces)
                let sku = columns[si].trimmingCharacters(in: .whitespaces)
                let description = columns[di].trimmingCharacters(in: .whitespaces)
                let category = columns[ci].trimmingCharacters(in: .whitespaces)
                
                let stockString = columns[sti].trimmingCharacters(in: .whitespaces)
                let costString = columns[coi].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "₹", with: "").replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
                
                guard let stock = Int(stockString), stock >= 0 else {
                    errors.append(ImportError(row: rowNum, reason: "Invalid stock count: '\(stockString)'."))
                    continue
                }
                
                guard let cost = Double(costString), cost >= 0 else {
                    errors.append(ImportError(row: rowNum, reason: "Invalid unit cost: '\(costString)'."))
                    continue
                }
                
                if name.isEmpty || sku.isEmpty {
                    errors.append(ImportError(row: rowNum, reason: "Name and SKU are required."))
                    continue
                }
                
                let usageLast30Days = parseOptionalInt(at: usageIdx, from: columns) ?? 0
                let vendorName = parseOptionalText(at: vendorNameIdx, from: columns) ?? "N/A"
                let vendorPhone = parseOptionalText(at: vendorPhoneIdx, from: columns) ?? "N/A"
                let vendorEmail = parseOptionalText(at: vendorEmailIdx, from: columns) ?? "N/A"
                let averageLeadTimeDays = parseOptionalInt(at: leadTimeIdx, from: columns) ?? 0

                parts.append(
                    InventoryPart(
                        name: name,
                        sku: sku,
                        description: description,
                        category: category,
                        stockCount: stock,
                        unitCost: cost,
                        usageLast30Days: max(0, usageLast30Days),
                        vendorName: vendorName,
                        vendorPhone: vendorPhone,
                        vendorEmail: vendorEmail,
                        averageLeadTimeDays: max(0, averageLeadTimeDays)
                    )
                )
            }
            
        } catch {
            errors.append(ImportError(row: 0, reason: "Failed to read file: \(error.localizedDescription)"))
        }
        
        return (parts, errors)
    }
    
    // Simple CSV row parser that handles quotes
    private func parseCSVRow(_ row: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var inQuotes = false
        
        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                columns.append(currentColumn)
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
        }
        columns.append(currentColumn)
        return columns
    }

    private func parseOptionalInt(at index: Int?, from columns: [String]) -> Int? {
        guard let index, index < columns.count else { return nil }
        let raw = columns[index].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        return Int(raw)
    }

    private func parseOptionalText(at index: Int?, from columns: [String]) -> String? {
        guard let index, index < columns.count else { return nil }
        let text = columns[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
