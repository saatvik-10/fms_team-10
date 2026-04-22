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

            Button(action: loadSampleData) {
                Text("Load Sample Data")
                    .font(.subheadline.bold())
                    .foregroundColor(AppColors.primary)
                    .padding(.top, 8)
            }
        }
    }
    
    private func loadSampleData() {
        let sampleCSV = """
Name,SKU,Description,Category,No Of Stock,Unit cost,Usage Last 30 Days,Vendor Name,Vendor Phone,Vendor Email,Average Lead Time Days
Wireless Mouse,ELE-5863,Professional grade wireless mouse for retail.,Electronics,22,321.23,25,TechNova Solutions,+1-555-010-2345,sales@technova.com,10
Mechanical Keyboard,ELE-7792,Professional grade mechanical keyboard for retail.,Electronics,70,80.84,71,TechNova Solutions,+1-555-010-2345,sales@technova.com,9
USB-C Hub,ELE-8859,Professional grade usb-c hub for retail.,Electronics,184,393.78,62,TechNova Solutions,+1-555-010-2345,sales@technova.com,15
Noise Cancelling Headphones,ELE-4731,Professional grade noise cancelling headphones for retail.,Electronics,221,253.51,16,TechNova Solutions,+1-555-010-2345,sales@technova.com,3
Webcam 1080p,ELE-1863,Professional grade webcam 1080p for retail.,Electronics,195,24.01,16,TechNova Solutions,+1-555-010-2345,sales@technova.com,9
Ergonomic Chair,OFF-8873,Professional grade ergonomic chair for retail.,Office Supplies,88,395.74,58,Global Office Supplies,+1-555-022-8899,orders@globaloffice.com,9
Standing Desk,OFF-7716,Professional grade standing desk for retail.,Office Supplies,186,364.91,37,Global Office Supplies,+1-555-022-8899,orders@globaloffice.com,12
Notebook Set,OFF-4249,Professional grade notebook set for retail.,Office Supplies,243,67.9,48,Global Office Supplies,+1-555-022-8899,orders@globaloffice.com,14
Gel Pens (12 pack),OFF-7581,Professional grade gel pens (12 pack) for retail.,Office Supplies,183,157.99,21,Global Office Supplies,+1-555-022-8899,orders@globaloffice.com,8
Desk Organizer,OFF-3474,Professional grade desk organizer for retail.,Office Supplies,213,398.59,59,Global Office Supplies,+1-555-022-8899,orders@globaloffice.com,12
Air Fryer,KIT-6593,Professional grade air fryer for retail.,Kitchenware,21,107.99,49,Culina Gear Ltd.,+44-20-7946-0123,contact@culinagear.co.uk,14
Electric Kettle,KIT-9125,Professional grade electric kettle for retail.,Kitchenware,131,276.13,85,Culina Gear Ltd.,+44-20-7946-0123,contact@culinagear.co.uk,11
Chef's Knife,KIT-9527,Professional grade chef's knife for retail.,Kitchenware,99,123.14,50,Culina Gear Ltd.,+44-20-7946-0123,contact@culinagear.co.uk,13
Cast Iron Skillet,KIT-1149,Professional grade cast iron skillet for retail.,Kitchenware,144,256.21,100,Culina Gear Ltd.,+44-20-7946-0123,contact@culinagear.co.uk,8
Blender,KIT-8299,Professional grade blender for retail.,Kitchenware,39,487.13,95,Culina Gear Ltd.,+44-20-7946-0123,contact@culinagear.co.uk,7
Yoga Mat,FIT-8647,Professional grade yoga mat for retail.,Fitness,244,254.81,17,Peak Performance Fitness,+1-555-045-6712,wholesale@peakfit.com,4
Dumbbell Set,FIT-3264,Professional grade dumbbell set for retail.,Fitness,149,224.01,57,Peak Performance Fitness,+1-555-045-6712,wholesale@peakfit.com,3
Resistance Bands,FIT-4820,Professional grade resistance bands for retail.,Fitness,165,203.89,68,Peak Performance Fitness,+1-555-045-6712,wholesale@peakfit.com,15
Foam Roller,FIT-4023,Professional grade foam roller for retail.,Fitness,237,33.45,87,Peak Performance Fitness,+1-555-045-6712,wholesale@peakfit.com,12
Jump Rope,FIT-4213,Professional grade jump rope for retail.,Fitness,197,305.3,68,Peak Performance Fitness,+1-555-045-6712,wholesale@peakfit.com,7
Bookshelf,FUR-7074,Professional grade bookshelf for retail.,Furniture,58,168.24,78,Urban Living Furniture,+1-555-099-4433,support@urbanliving.com,4
Side Table,FUR-3253,Professional grade side table for retail.,Furniture,95,381.43,70,Urban Living Furniture,+1-555-099-4433,support@urbanliving.com,11
Floor Lamp,FUR-6228,Professional grade floor lamp for retail.,Furniture,221,129.8,31,Urban Living Furniture,+1-555-099-4433,support@urbanliving.com,9
Bean Bag,FUR-4379,Professional grade bean bag for retail.,Furniture,115,175.79,48,Urban Living Furniture,+1-555-099-4433,support@urbanliving.com,5
Ottoman,FUR-2128,Professional grade ottoman for retail.,Furniture,196,121.26,62,Urban Living Furniture,+1-555-099-4433,support@urbanliving.com,7
"""
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("sample_inventory.csv")
        try? sampleCSV.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let (parts, errors) = InventoryCSVImportService.shared.parseCSV(at: tempURL)
        if !parts.isEmpty {
            store.importInventory(parts)
        }
        if !errors.isEmpty {
            self.importErrors = errors
            self.showingErrorAlert = true
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
                        Text(part.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.primaryText)

                        HStack(spacing: 8) {
                            Text(part.sku)
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
                        Text("Stock: \(part.stockCount)")
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
                        get: { part.reorderThreshold },
                        set: { store.updateInventoryThreshold(for: part.sku, newThreshold: $0) }
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
                        Text("USAGE STATISTICS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)
                        Text("Used in last 30 days: \(part.usageLast30Days) units")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.primaryText)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("SUPPLY INFO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)

                        Text("Vendor: \(part.vendorName)")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.primaryText)
                        Text("Phone: \(part.vendorPhone)")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.primaryText)
                        Text("Email: \(part.vendorEmail)")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.primaryText)
                        Text("Lead Time: \(part.averageLeadTimeDays) days")
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
