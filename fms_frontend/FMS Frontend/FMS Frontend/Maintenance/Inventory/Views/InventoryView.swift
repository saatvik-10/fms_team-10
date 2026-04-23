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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Valuation")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.primary.opacity(0.8))
                        .textCase(.uppercase)
                    
                    Text(String(format: "₹%.2f", store.totalInventoryValue / 100000))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                }
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
        )
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
