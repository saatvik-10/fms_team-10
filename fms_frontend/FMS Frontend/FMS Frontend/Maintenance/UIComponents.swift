//
//  UIComponents.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI
import PDFKit
import UIKit

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
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
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

/// A professional primary button for bottom actions.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.primary)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
    }
}

/// A native PDFKit wrapper for SwiftUI to view generated reports.
struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
    }
}

/// A unified card for work order tasks.
struct WorkOrderTaskCard: View {
    let order: WorkOrder

    private var statusColor: Color {
        switch order.status {
        case .completed: return .green
        case .inProgress: return .blue
        case .pending:    return .orange
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
                
                // Status Section (Rightmost)
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(order.status.rawValue.uppercased())
                        .font(.system(size: 10, weight: .black))
                }
                .foregroundColor(statusColor)
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGray6).opacity(0.2))
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
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
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
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
                    HStack(spacing: 12) {
                        Text(inspection.title.isEmpty ? inspection.type.rawValue : inspection.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(inspection.type == .preTrip ? "PRE-TRIP" : "POST-TRIP")
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(inspection.type == .preTrip ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1))
                            .foregroundColor(inspection.type == .preTrip ? .blue : .purple)
                            .cornerRadius(5)
                    }

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
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(inspection.status.rawValue.uppercased())
                        .font(.system(size: 10, weight: .black))
                }
                .foregroundColor(statusColor)
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGray6).opacity(0.2))
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

// Helper component for metadata cells
struct MetadataCell: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 10, weight: .bold))
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
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(AppColors.primary.opacity(0.7))
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

