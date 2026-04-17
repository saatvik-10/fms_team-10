//
//  UIComponents.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI
import PDFKit

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
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(width: 48, height: 48)
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(AppColors.primary)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(order.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(order.vehicleName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 10) {
                PriorityBadge(priority: order.priority.rawValue)
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
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

