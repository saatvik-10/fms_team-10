//
//  InventoryView.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()
    
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Professional Stats Header
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        InventoryStatCard(title: "In Stock", value: "\(viewModel.items.count)", icon: "box.truck.fill", color: AppColors.primary)
                        InventoryStatCard(title: "Low Stock", value: "\(viewModel.lowStockCount)", icon: "exclamationmark.triangle.fill", color: .orange)
                        InventoryStatCard(title: "Out of Stock", value: "0", icon: "xmark.octagon.fill", color: .red)
                    }
                    .padding()
                }
                
                // Search & Filter Bar
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.secondaryText)
                            TextField("Search SKU or Part Name", text: $viewModel.searchText)
                                .font(.system(size: 15))
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                        
                        Button(action: { /* Scan Barcode */ }) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(AppColors.primary)
                                .cornerRadius(12)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(title: "All Items", isSelected: viewModel.selectedCategory == nil) {
                                viewModel.selectedCategory = nil
                            }
                            ForEach(InventoryCategory.allCases, id: \.self) { category in
                                FilterChip(title: category.rawValue, isSelected: viewModel.selectedCategory == category) {
                                    viewModel.selectedCategory = category
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                List {
                    Section {
                        ForEach(viewModel.filteredItems) { item in
                            InventoryItemRow(item: item) { delta in
                                withAnimation(.spring()) {
                                    viewModel.updateQuantity(for: item.id, by: delta)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text("INVENTORY CATALOG")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)
                            .padding(.bottom, 8)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { /* Add Item */ }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

struct InventoryItemRow: View {
    let item: InventoryItem
    let onUpdate: (Int) -> Void
    
    var body: some View {
        CardView {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // Category Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(item.isLowStock ? Color.orange.opacity(0.1) : AppColors.primary.opacity(0.05))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: categoryIcon(item.category))
                            .foregroundColor(item.isLowStock ? .orange : AppColors.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                        
                        HStack {
                            Text(item.category.rawValue)
                            Text("•")
                            Text("Min Stock: \(item.reorderLevel)")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(item.quantity)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(item.isLowStock ? .orange : AppColors.primaryText)
                        
                        Text(item.unit)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                Divider()
                
                HStack {
                    if item.isLowStock {
                        Label("Low Stock Alert", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                    } else {
                        Label("In Stock", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.success)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Button(action: { onUpdate(-1) }) {
                            Text("Use")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.05))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                        }
                        
                        Button(action: { onUpdate(1) }) {
                            Text("Restock")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppColors.success.opacity(0.05))
                                .foregroundColor(AppColors.success)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    func categoryIcon(_ category: InventoryCategory) -> String {
        switch category {
        case .spareParts: return "gearshape.2.fill"
        case .fluids: return "drop.fill"
        case .tools: return "wrench.adjustable.fill"
        case .tires: return "circle.dashed"
        }
    }
}

// Reusing Stat Card from previous step, but polished
struct InventoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .frame(width: 120, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : Color.white)
                .foregroundColor(isSelected ? .white : AppColors.primaryText)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.black.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
    }
}
