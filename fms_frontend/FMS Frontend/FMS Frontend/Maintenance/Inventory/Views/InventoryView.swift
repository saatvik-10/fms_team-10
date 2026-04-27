//
//  InventoryView.swift
//  FMS Frontend
//
//  Created by opencode on 21/04/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct InventoryView: View {
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var store: MaintenanceStore
    @State private var showingFileImporter = false
    @State private var importErrors: [InventoryCSVImportService.ImportError] = []
    @State private var showingErrorAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Dashboard Header Style
                HStack {
                    Text("Inventory")
                        .font(.system(size: 34, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                
                // ── Section 1: Inventory Analysis ─────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    Text("Inventory Analysis")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.primaryText)
                        .padding(.horizontal, 20)
                    
                    prominentValuationCard
                        .padding(.horizontal, 20)
                }
                
                // ── Section 2: Parts Catalog ──────────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Global Inventory")
                            .font(.title2.bold())
                            .foregroundColor(AppColors.primaryText)
                        Spacer()
                        NavigationLink(destination: FullInventoryListView()) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(.systemGray3))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 0) {
                        let lowStockItems = store.inventoryParts.filter({ $0.isLowStock })
                        let itemsToDisplay = lowStockItems.isEmpty ? mockAlerts : Array(lowStockItems.prefix(5))
                        
                        ForEach(Array(itemsToDisplay.enumerated()), id: \.element.id) { index, part in
                            NavigationLink(destination: InventoryDetailView(part: part)) {
                                InventoryAlertRow(part: part)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if index < itemsToDisplay.count - 1 {
                                Divider()
                                    .padding(.leading, 70)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 48)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showingFileImporter = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                NavigationLink(destination: MaintenanceProfileView(isLoggedIn: $isLoggedIn)) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 22))
                }
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.commaSeparatedText, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let (parts, errors) = InventoryCSVImportService.shared.parseCSV(at: url)
                if !parts.isEmpty {
                    store.importInventory(parts)
                }
                if !errors.isEmpty {
                    self.importErrors = errors
                    self.showingErrorAlert = true
                }
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
        .alert("Import Status", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if importErrors.count > 0 {
                Text("Imported \(store.inventoryParts.count) parts. Encountered \(importErrors.count) issues.")
            } else {
                Text("Inventory imported successfully.")
            }
        }
    }
    
    private var prominentValuationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.inventoryParts.isEmpty {
                // CSV Requirements Box
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppColors.primary)
                        Text("CSV Import Requirements")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    Text("To upload your inventory, ensure your CSV file contains these headers:")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        headerRequirementRow(title: "Required", fields: "Name, SKU, Category, Stock, Cost")
                        headerRequirementRow(title: "Optional", fields: "Supplier, Vehicle Type, Location, Min Stock")
                    }
                    .padding(.top, 4)
                    
                    Button(action: { showingFileImporter = true }) {
                        Text("Upload CSV Now")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.primary)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .background(AppColors.primary.opacity(0.05))
                .cornerRadius(20)
            } else {
                // Valuation on one line
                HStack(spacing: 12) {
                    Text("Total Valuation:")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(store.totalInventoryValue))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(store.inventoryParts.isEmpty ? 0 : 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
        )
    }

    private func headerRequirementRow(title: String, fields: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(AppColors.primary.opacity(0.7))
            Text(fields)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 10_000_000 { // 1 Crore = 100 Lakhs
            return String(format: "₹%.2f C", value / 10_000_000)
        } else if value >= 100_000 { // 1 Lakh
            return String(format: "₹%.2f L", value / 100_000)
        } else {
            return String(format: "₹%.2f", value)
        }
    }
    
    private var mockAlerts: [InventoryPart] {
        [
            InventoryPart(partName: "Brake Pad Set", partId: "BR-001", category: "Brakes", stockQty: 2, minStock: 10, unitPriceInr: 4500, supplier: "Bosch", vehicleType: "Truck", location: "A1"),
            InventoryPart(partName: "Oil Filter", partId: "FL-902", category: "Fluids", stockQty: 5, minStock: 20, unitPriceInr: 850, supplier: "Mann", vehicleType: "Bus", location: "B2"),
            InventoryPart(partName: "Headlight Assembly", partId: "EL-553", category: "Electrical", stockQty: 1, minStock: 5, unitPriceInr: 12000, supplier: "Hella", vehicleType: "Truck", location: "C3")
        ]
    }
}

struct InventoryAlertRow: View {
    let part: InventoryPart
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(part.isLowStock ? Color.orange.opacity(0.12) : AppColors.primary.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 18))
                    .foregroundColor(part.isLowStock ? .orange : AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(part.partName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                
                Text("\(part.partId) • Stock: \(part.stockQty)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(.systemGray4))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}

struct InventoryRow: View {
    let part: InventoryPart
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(part.isLowStock ? Color.orange.opacity(0.05) : AppColors.primary.opacity(0.05))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(part.isLowStock ? .orange : AppColors.primary)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(part.partName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(part.partId)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(part.stockQty)")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(part.isLowStock ? .orange : AppColors.primaryText)
        }
        .padding(.vertical, 4)
    }
}
