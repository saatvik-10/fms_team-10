//
//  InventoryView.swift
//  FMS Frontend
//

import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()
    
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Stock Stats Overview
                HStack(spacing: 20) {
                    InventoryStatCard(title: "Total SKUs", value: "\(viewModel.items.count)", icon: "box.truck.fill", color: AppColors.primary)
                    InventoryStatCard(title: "Low Stock", value: "\(viewModel.lowStockCount)", icon: "exclamationmark.triangle.fill", color: .orange)
                }
                .padding()
                
                // Search & Filter
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.secondaryText)
                        TextField("Search inventory...", text: $viewModel.searchText)
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(title: "All", isSelected: viewModel.selectedCategory == nil) {
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
                .padding(.bottom)
                
                List {
                    ForEach(viewModel.filteredItems) { item in
                        InventoryItemRow(item: item) { delta in
                            viewModel.updateQuantity(for: item.id, by: delta)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Inventory")
    }
}

struct InventoryItemRow: View {
    let item: InventoryItem
    let onUpdate: (Int) -> Void
    
    var body: some View {
        CardView {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(item.category.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Button(action: { onUpdate(-1) }) {
                            Image(systemName: "minus.circle")
                                .foregroundColor(AppColors.primary)
                        }
                        
                        Text("\(item.quantity)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .frame(width: 30)
                        
                        Button(action: { onUpdate(1) }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    
                    Text(item.unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .overlay(
                HStack {
                    if item.isLowStock {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 4)
                            .padding(.vertical, -16)
                            .padding(.leading, -16)
                        Spacer()
                    }
                }
            )
        }
    }
}

struct InventoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
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
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : Color.white)
                .foregroundColor(isSelected ? .white : AppColors.primaryText)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
}

struct InventoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            InventoryView()
        }
    }
}
