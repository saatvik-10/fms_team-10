//
//  DetailedInspectionView.swift
//  FMS Frontend
//

import SwiftUI

struct DetailedInspectionView: View {
    @Environment(\.dismiss) var dismiss
    @State var inspection: TripInspection
    @State private var expandedSections: Set<String> = ["Mechanical Systems"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Native-like Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.headline)
                        .foregroundColor(AppColors.primary)
                }
                Text("Inspection")
                    .font(.headline)
                    .padding(.leading, 8)
                Spacer()
                StatusBadge(text: "IN PROGRESS", color: .blue)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            
            ScrollView {
                VStack(spacing: 24) {
                    // Vehicle Info & Metrics Card
                    VStack(spacing: 20) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "car.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.3))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(inspection.unitName)
                                    .font(.title3.bold())
                                Text("VIN: \(inspection.unitVIN)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        Divider()
                        
                        MetricsGrid(metrics: [
                            ("ODOMETER", inspection.odometer),
                            ("FUEL LEVEL", inspection.fuelLevel),
                            ("EFFICIENCY", inspection.efficiency),
                            ("ENGINE HOURS", inspection.engineHours)
                        ])
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                    
                    // Inspection Checklist Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("SYSTEM CHECKLIST")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(AppColors.primary.opacity(0.7))
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ForEach($inspection.items) { $item in
                                InspectionListItem(item: $item)
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                
                                if item.id != inspection.items.last?.id {
                                    Divider().padding(.leading, 16)
                                }
                            }
                            
                            // Add Other Option
                            Button(action: {
                                let newItem = InspectionItem(
                                    name: "Custom Factor",
                                    verificationCriteria: "User-defined criteria",
                                    isImageRequired: false
                                )
                                inspection.items.append(newItem)
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Other Factor")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding()
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                    }
                    
                    Spacer(minLength: 120)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            
            // Sticky Bottom Button
            VStack {
                Divider()
                Button(action: { dismiss() }) {
                    HStack {
                        Text("Submit Inspection Report")
                        Image(systemName: "text.badge.checkmark")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func toggleSection(_ id: String) {
        if expandedSections.contains(id) {
            expandedSections.remove(id)
        } else {
            expandedSections.insert(id)
        }
    }
}

struct InspectionAccordionSection<Content: View>: View {
    let title: String
    let systemImage: String
    let isExpanded: Bool
    let toggle: () -> Void
    let content: Content
    
    init(title: String, systemImage: String, isExpanded: Bool, toggle: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.isExpanded = isExpanded
        self.toggle = toggle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .foregroundColor(AppColors.primary)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
            }
            
            if isExpanded {
                VStack {
                    Divider()
                    content
                        .padding()
                }
                .background(Color(.secondarySystemGroupedBackground))
            }
        }
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}

struct InspectionListItem: View {
    @Binding var item: InspectionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(item.name)
                    .font(.body.bold())
                Spacer()
                ChoiceButtonGroup(selected: $item.result)
            }
            
            HStack(spacing: 12) {
                // Photo Placeholder
                Button(action: {}) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundColor(Color(.systemGray4))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "camera.badge.ellipsis")
                            .foregroundColor(.secondary)
                    }
                }
                
                if let data = item.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                }
            }
            
            TextField("Add notes for \(item.name.lowercased())...", text: $item.notes)
                .font(.caption)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            
            Divider()
        }
    }
}
