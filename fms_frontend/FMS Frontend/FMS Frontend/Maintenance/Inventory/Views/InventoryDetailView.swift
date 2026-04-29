//
//  InventoryDetailView.swift
//  FMS Frontend
//
//  Created by Antigravity on 26/04/24.
//

import SwiftUI

struct InventoryDetailView: View {
    let partId: String
    @EnvironmentObject var store: MaintenanceStore
    @Environment(\.dismiss) var dismiss
    @State private var showingAddStock = false
    @State private var isEditing = false
    @State private var stockAppendValue = ""
    @State private var editPartName = ""
    @State private var editPartPrice = ""
    @State private var editPartCategory = ""
    @State private var editPartMinStock = ""
    @State private var editPartStockQty = ""
    @State private var showingEditValidation = false
    @State private var showingAddStockValidation = false
    @State private var showingStockSuccess = false
    @State private var lastStockUpdateMessage = ""

    private var part: InventoryPart? {
        store.inventoryParts.first { $0.partId == partId }
    }
    
    var body: some View {
        Group {
            if let part = part {
                List {
                    Section {
                        headerView(part: part)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    
                    Section("Stock Status") {
                        if isEditing {
                            editableRow(title: "Current Stock", text: $editPartStockQty, keyboard: .numberPad)
                        } else {
                            detailRow(title: "Current Stock", value: "\(part.stockQty) units", color: part.isLowStock ? .orange : .primary)
                        }
                        
                        if isEditing {
                            editableRow(title: "Reorder Threshold", text: $editPartMinStock, keyboard: .numberPad)
                        } else {
                            detailRow(title: "Reorder Threshold", value: "\(part.minStock)")
                        }
                        
                        detailRow(title: "Stock Status", value: part.isLowStock ? "LOW STOCK" : "OPTIMAL", color: part.isLowStock ? .orange : .green)
                    }
                    
                    Section("Financials") {
                        if isEditing {
                            editableRow(title: "Unit Price", text: $editPartPrice, keyboard: .decimalPad)
                        } else {
                            detailRow(title: "Unit Price", value: "₹\(part.unitPriceInr, default: "%.2f")")
                        }
                        detailRow(title: "Total Cost", value: "₹\(part.totalValue, default: "%.2f")", color: AppColors.primary)
                    }
                    
                    Section("Supply & Logistics") {
                        detailRow(title: "Supplier", value: part.supplier)
                        detailRow(title: "Location", value: part.location)
                        detailRow(title: "Vehicle Compatibility", value: part.vehicleType)
                    }
                    
                    Section("Identification") {
                        detailRow(title: "SKU / Part ID", value: part.partId)
                        if isEditing {
                            editableRow(title: "Category", text: $editPartCategory, keyboard: .default)
                        } else {
                            detailRow(title: "Category", value: part.category)
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    if showingAddStock {
                        addStockCard(part: part)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .navigationTitle(part.partName)
                .navigationBarTitleDisplayMode(.inline)
                .listStyle(.insetGrouped)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            if isEditing {
                                saveEdits(part: part)
                            } else {
                                startEditing(part: part)
                            }
                        }) {
                            Text(isEditing ? "Save" : "Edit")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    if isEditing {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                cancelEditing()
                            }
                        }
                    }
                }
                .alert("Invalid Details", isPresented: $showingEditValidation) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Enter a valid name, category, price, min stock, and current stock.")
                }
                .alert("Stock Updated", isPresented: $showingStockSuccess) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(lastStockUpdateMessage)
                }
                .alert("Invalid Quantity", isPresented: $showingAddStockValidation) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Enter a quantity greater than 0.")
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Part not found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func headerView(part: InventoryPart) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: categoryIcon(for: part.category))
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(spacing: 4) {
                Text(part.partName)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                Text(part.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private func detailRow(title: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
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

    private func editableRow(title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            TextField(title, text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 140)
        }
    }

    private func addStockCard(part: InventoryPart) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Stock")
                .font(.headline)

            TextField("Quantity", text: $stockAppendValue)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingAddStock = false
                    }
                }
                .buttonStyle(.bordered)

                Button("Add") {
                    guard let quantity = Int(stockAppendValue), quantity > 0 else {
                        showingAddStockValidation = true
                        return
                    }
                    store.appendInventoryStock(partId: part.partId, quantity: quantity)
                    lastStockUpdateMessage = "Added \(quantity) units to \(part.partName)."
                    stockAppendValue = ""
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingAddStock = false
                    }
                    showingStockSuccess = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private func startEditing(part: InventoryPart) {
        editPartName = part.partName
        editPartPrice = String(format: "%.2f", part.unitPriceInr)
        editPartCategory = part.category
        editPartMinStock = "\(part.minStock)"
        editPartStockQty = "\(part.stockQty)"
        showingAddStock = false
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = true
        }
    }

    private func cancelEditing() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = false
        }
    }

    private func saveEdits(part: InventoryPart) {
        guard !editPartName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !editPartCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let price = Double(editPartPrice),
              price >= 0,
              let minStock = Int(editPartMinStock),
              minStock >= 0,
              let stockQty = Int(editPartStockQty),
              stockQty >= 0 else {
            showingEditValidation = true
            return
        }
        let roundedPrice = (price * 100).rounded() / 100
        editPartPrice = String(format: "%.2f", roundedPrice)
        store.updateInventoryPart(partId: part.partId, name: editPartName, category: editPartCategory, minStock: minStock, stockQty: stockQty, unitPriceInr: roundedPrice)
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = false
        }
    }
}
