//
//  DetailedInspectionView.swift
//  FMS Frontend
//

import SwiftUI
import PDFKit


// MARK: - Main View
struct DetailedInspectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    @State var inspection: TripInspection
    @State private var showingPDFPreview = false
    @State private var reportURL: URL?
    @State private var isGenerating = false

    @State private var showingDoneAlert = false

    private var reportTitle: String {
        let initials = inspection.unitName.components(separatedBy: " ")
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        let dateStr = formatter.string(from: Date())
        
        return "\(initials) - \(dateStr)"
    }

    var body: some View {
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
                            
                            HStack {
                                Text(inspection.type.rawValue)
                                    .font(.caption.bold())
                                    .foregroundColor(AppColors.primary)
                                
                                Text("•")
                                    .foregroundColor(.secondary)
                                
                                Text(inspection.status.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(inspection.status == .completed ? .green : .blue)
                            }
                        }
                        Spacer()
                    }

                    if inspection.status == .completed {
                        Button(action: {
                            isGenerating = true
                            DispatchQueue.global(qos: .userInitiated).async {
                                let url = PDFService.shared.generateInspectionReport(inspection: inspection)
                                DispatchQueue.main.async {
                                    isGenerating = false
                                    reportURL = url
                                    showingPDFPreview = url != nil
                                }
                            }
                        }) {
                            HStack {
                                if isGenerating {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "doc.text.fill")
                                }
                                Text("View Full PDF Report")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isGenerating)
                    }

                    Divider()

                    MetricsGrid(metrics: [
                        ("FUEL LEVEL",   inspection.fuelLevel),
                        ("EFFICIENCY",   inspection.efficiency),
                        ("ENGINE HOURS", inspection.engineHours)
                    ])
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))

                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(title: "AUDIT RESULTS", icon: "checklist")
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach($inspection.items, id: \.id) { $item in
                            InspectionListItem(item: $item)
                                .padding()
                                .disabled(inspection.status == .completed)
                                .background(Color(.secondarySystemGroupedBackground))

                            if item.id != inspection.items.last?.id {
                                Divider().padding(.leading, 16)
                            }
                        }
                        
                        if inspection.status != .completed {
                            Button(action: {
                                let newItem = InspectionItem(
                                    name: "Custom Observation",
                                    verificationCriteria: "User-defined criteria",
                                    isImageRequired: false
                                )
                                inspection.items.append(newItem)
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Observation")
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
        .navigationTitle("Inspection Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if inspection.status != .completed {
                    Button(action: { showingDoneAlert = true }) {
                        Text("Finish")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .alert("", isPresented: $showingDoneAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Generate Report") {
                submitAndGeneratePDF()
            }
        }
        .fullScreenCover(isPresented: $showingPDFPreview) {
            if let url = reportURL {
                PDFPreviewView(url: url, title: reportTitle)
            } else {
                EmptyView()
            }
        }
    }

    private func submitAndGeneratePDF() {
        // Ensure changes are persisted
        inspection.status = .completed
        store.updateInspection(inspection)
        
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let url = PDFService.shared.generateInspectionReport(inspection: inspection)
            DispatchQueue.main.async {
                isGenerating = false
                reportURL = url
                showingPDFPreview = url != nil
            }
        }
    }
}

// MARK: - Inspection List Item (Optional Images)

// MARK: - Accordion Section (kept for other uses)
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
                    content.padding()
                }
                .background(Color(.secondarySystemGroupedBackground))
            }
        }
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}
