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
    @State private var expandedPartIDs: Set<UUID> = []
    
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            if store.inventoryParts.isEmpty {
                emptyState
            } else {
                inventoryContent
            }
        }
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    if !store.inventoryParts.isEmpty {
                        Button(action: { showingFileImporter = true }) {
                            Image(systemName: "plus.app")
                                .font(.title3)
                        }
                    }
                    NavigationLink(destination: MaintenanceProfileView(isLoggedIn: $isLoggedIn)) {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
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
                Text("Imported \(store.inventoryParts.count) parts. Encountered \(importErrors.count) issues. Check your CSV format.")
            } else {
                Text("Inventory imported successfully.")
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primary.opacity(0.15))
            
            VStack(spacing: 12) {
                Text("No Inventory Data")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Upload a CSV file containing your parts catalog, stock levels, and costs to get started.")
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("REQUIRED CSV HEADERS:")
                    .font(.caption.bold())
                    .foregroundColor(AppColors.secondaryText)
                
                Text("Name, SKU, Description, Category, No of Stock, Unit Cost")
                    .font(.caption.monospaced())
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
            
            Button(action: { showingFileImporter = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Import CSV Inventory")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(AppColors.primary)
                .cornerRadius(16)
                .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 16)
        }
    }
    
    private var inventoryContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Cards
                HStack(spacing: 16) {
                    SummaryCard(
                        title: "Total Parts",
                        count: "\(store.inventoryParts.count)",
                        icon: "list.bullet.clipboard",
                        color: AppColors.primary
                    )
                    
                    SummaryCard(
                        title: "Low Stock",
                        count: "\(store.lowStockCount)",
                        icon: "exclamationmark.triangle.fill",
                        color: store.lowStockCount > 0 ? .orange : .green
                    )
                }
                .padding(.horizontal, 20)
                
                // Valuation Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .foregroundColor(AppColors.success)
                        Text("Total Inventory Valuation")
                            .font(.subheadline.bold())
                            .foregroundColor(AppColors.secondaryText)
                        Spacer()
                    }
                    
                    Text("₹\(store.totalInventoryValue, specifier: "%.2f")")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 20)
                
                // Parts List
                VStack(alignment: .leading, spacing: 16) {
                    Text("Parts Catalog")
                        .font(.title3.bold())
                        .foregroundColor(AppColors.primaryText)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        ForEach(store.inventoryParts) { part in
                            InventoryPartCard(
                                part: part,
                                isExpanded: expandedPartIDs.contains(part.id),
                                onToggleExpand: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if expandedPartIDs.contains(part.id) {
                                            expandedPartIDs.remove(part.id)
                                        } else {
                                            expandedPartIDs.insert(part.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
    }
}

struct InventoryPartCard: View {
    let part: InventoryPart
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    @EnvironmentObject var store: MaintenanceStore
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggleExpand) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.primary.opacity(0.08))
                            .frame(width: 44, height: 44)

                        Image(systemName: categoryIcon(for: part.category))
                            .foregroundColor(AppColors.primary)
                            .font(.system(size: 18))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(part.partName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.primaryText)

                        HStack(spacing: 8) {
                            Text(part.partId)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)

                            Text(part.category.uppercased())
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Stock: \(part.stockQty)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(part.isLowStock ? .orange : AppColors.primaryText)

                        if part.isLowStock {
                            Text("LOW STOCK")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider().padding(.horizontal, 16)
            
            // Threshold Input & Valuation
            HStack(spacing: 0) {
                // Input Box for Reorder Threshold
                VStack(alignment: .leading, spacing: 6) {
                    Text("REORDER THRESHOLD")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppColors.secondaryText)
                    
                    TextField("0", value: Binding(
                        get: { part.minStock },
                        set: { store.updateInventoryThreshold(for: part.partId, newThreshold: $0) }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
                    .frame(width: 80)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider().frame(height: 35).padding(.horizontal, 8)
                
                // Per Part Valuation
                VStack(alignment: .trailing, spacing: 4) {
                    Text("TOTAL VALUE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppColors.secondaryText)
                    Text("₹\(part.totalValue, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6).opacity(0.2))

            if isExpanded {
                Divider().padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LOCATION INFO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)
                        Text("Stored at: \(part.location)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.primaryText)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("SUPPLY & COMPATIBILITY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)

                        Text("Supplier: \(part.supplier)")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.primaryText)
                        Text("Vehicle Type: \(part.vehicleType)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    private func categoryIcon(for category: String) -> String {
        let cat = category.lowercased()
        if cat.contains("tire") { return "circle.dotted" }
        if cat.contains("engine") || cat.contains("motor") { return "engine.combustion.fill" }
        if cat.contains("brake") { return "slowmo" }
        if cat.contains("fluid") || cat.contains("oil") { return "drop.fill" }
        if cat.contains("elect") || cat.contains("battery") { return "bolt.fill" }
        return "gearshape.fill"
    }
}
