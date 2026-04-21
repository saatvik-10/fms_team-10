//
//  UIComponents.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI
import PDFKit
internal import UIKit

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

/// A premium, enterprise-level card container following iOS HIG.
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
    }
}

/// A subtle, professional status indicator.
struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text.uppercased())
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

/// A badge for vehicle identification.
struct VINBadge: View {
    let vin: String
    
    var body: some View {
        Text("VIN: \(vin)")
            .font(.caption2.monospaced())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.1))
            .foregroundColor(.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// A badge for work order priority.
struct PriorityBadge: View {
    let priority: String
    
    var color: Color {
        switch priority.lowercased() {
        case "critical": return AppColors.priorityCritical
        case "high": return AppColors.priorityHigh
        case "medium": return AppColors.priorityMedium
        default: return AppColors.priorityLow
        }
    }
    
    var body: some View {
        Text(priority.uppercased())
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// A standard iOS native action button for enterprise flows.
struct ActionButton: View {
    let title: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.callout.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? .white : color)
            .cornerRadius(12)
        }
    }
}



/// A unified card for work order tasks.
struct WorkOrderTaskCard: View {
    let order: WorkOrder

    private func priorityColor(_ priority: WorkOrderPriority) -> Color {
        switch priority {
        case .critical: return .red
        case .high:     return .orange
        case .medium:   return .blue
        case .low:      return .gray
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main Content Area
            HStack(spacing: 20) {
                // Left: Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .frame(width: 48, height: 48)
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundColor(AppColors.primary)
                        .font(.system(size: 20))
                }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(order.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                    Text(order.vehicleName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.systemGray4))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // Bottom 3-Part Metadata Row
            HStack(spacing: 0) {
                // Date Section
                MetadataCell(icon: "calendar", text: order.scheduledDate.formatted(.dateTime.day().month(.abbreviated)))
                
                Divider().frame(height: 16)
                
                // Time Section
                MetadataCell(icon: "clock", text: order.scheduledDate.formatted(.dateTime.hour().minute()))
                
                Divider().frame(height: 16)
                
                // Priority Section (Rightmost)
                HStack(spacing: 6) {
                    Text(order.priority.rawValue.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor(order.priority).opacity(0.12))
                        .foregroundColor(priorityColor(order.priority))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGray6).opacity(0.2))
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

/// A grid for displaying vehicle metrics (Odometer, Fuel, etc.)
struct MetricsGrid: View {
    let metrics: [(label: String, value: String)]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            ForEach(metrics, id: \.label) { metric in
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.label.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(metric.value)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}

/// A horizontal group of choice buttons for inspection results.
struct ChoiceButtonGroup: View {
    @Binding var selected: InspectionResult
    
    var body: some View {
        HStack(spacing: 8) {
            ChoiceButton(title: "GOOD", result: .good, selected: $selected, color: Color.green)
            ChoiceButton(title: "REPAIR", result: .repair, selected: $selected, color: Color.orange)
            ChoiceButton(title: "ALERT", result: .alert, selected: $selected, color: Color.gray)
        }
    }
}

struct ChoiceButton: View {
    let title: String
    let result: InspectionResult
    @Binding var selected: InspectionResult
    let color: Color
    
    var body: some View {
        Button(action: { selected = result }) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected == result ? color : Color(.systemGray6))
                .foregroundColor(selected == result ? .white : .secondary)
                .cornerRadius(8)
        }
    }
}


/// A professional card for trip inspections in a list view.
struct InspectionTaskCard: View {
    let inspection: TripInspection
    var showUnitName: Bool = true

    private var statusColor: Color {
        switch inspection.status {
        case .completed: return .green
        case .pending:    return .orange
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main Content Area
            HStack(spacing: 20) {
                // Left: Icon with Subtle indicator
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemGray6))
                            .frame(width: 48, height: 48)
                        Image(systemName: "clipboard.fill")
                            .foregroundColor(AppColors.primary)
                            .font(.system(size: 20))
                    }
                    
                    Circle()
                        .fill(inspection.type == .preTrip ? Color.blue : Color.purple)
                        .frame(width: 10, height: 10)
                        .offset(x: 3, y: -3)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(inspection.title.isEmpty ? inspection.type.rawValue : inspection.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if showUnitName {
                        Text(inspection.unitName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.systemGray4))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // Bottom 3-Part Metadata Row
            HStack(spacing: 0) {
                // Date Section
                MetadataCell(icon: "calendar", text: inspection.timestamp.formatted(.dateTime.day().month(.abbreviated)))
                
                Divider().frame(height: 16)
                
                // Time Section
                MetadataCell(icon: "clock", text: inspection.timestamp.formatted(.dateTime.hour().minute()))
                
                Divider().frame(height: 16)
                
                // Status Section (Rightmost)
                HStack(spacing: 6) {
                    Text(inspection.status.rawValue.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(inspection.status == .completed ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        .foregroundColor(inspection.status == .completed ? .green : .blue)
                        .cornerRadius(5)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGray6).opacity(0.2))
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
    
    private func tagColor(for type: InspectionType) -> Color {
        switch type {
        case .preTrip: return .blue
        case .postTrip: return .purple
        case .maintenance: return .orange
        }
    }
}

// Helper component for metadata cells
struct MetadataCell: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.bold())
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity)
    }
}

/// A section for information blocks in details views.
struct InfoSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            content
        }
    }
}

/// A card for displaying captured inspection images with an expandable AI analysis.
struct ImageAnalysisCard: View {
    let imageData: Data
    let analysis: String
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { isExpanded.toggle() } }) {
                HStack(spacing: 16) {
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .cornerRadius(10)
                            .clipped()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Photo Analysis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        Text(isExpanded ? "Hide Details" : "Tap to view AI Insights")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(12)
                .background(Color(.systemGray6).opacity(0.3))
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().padding(.horizontal, 12)
                    Text(analysis)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}


/// A reusable empty state view for lists.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.3))
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

/// A premium selection pill for filtering.
struct MaintStatusPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : Color.white)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
    }
}

/// A card-based group for form fields with a small uppercase title.
struct FormGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Standardized Checklist Item
struct InspectionListItem: View {
    @Binding var item: InspectionItem
    @State private var showImagePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1: Title & Status Menu
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(item.verificationCriteria)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 12)
                
                Menu {
                    Button(action: { item.result = .good }) {
                        Label("Good", systemImage: "checkmark.circle.fill")
                    }
                    Button(action: { item.result = .repair }) {
                        Label("Repair", systemImage: "wrench.and.screwdriver.fill")
                    }
                    Button(action: { item.result = .alert }) {
                        Label("Alert", systemImage: "exclamationmark.triangle.fill")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(item.result == .pending ? "Select" : item.result.rawValue.capitalized)
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(statusColor(item.result).opacity(0.1))
                    .foregroundColor(statusColor(item.result))
                    .cornerRadius(8)
                }
            }

            // Row 2: Photo Button & Notes Field
            HStack(spacing: 12) {
                Button(action: { showImagePicker = true }) {
                    if let data = item.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .shadow(radius: 1)
                                    .padding(2),
                                alignment: .bottomTrailing
                            )
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray5))
                                .frame(width: 36, height: 36)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(item.isImageRequired ? AppColors.primary : .secondary)
                        }
                    }
                }
                
                TextField("Add a note...", text: $item.notes)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(imageData: $item.imageData, sourceType: .photoLibrary)
        }
    }
    
    private func statusColor(_ result: InspectionResult) -> Color {
        switch result {
        case .good: return .green
        case .repair: return .orange
        case .alert: return .red
        case .pending: return .blue
        }
    }
}
