//
//  DetailedInspectionView.swift
//  FMS Frontend
//

import SwiftUI
import PDFKit

// MARK: - PDF Report Generator
struct InspectionReportGenerator {

    static func generate(for inspection: TripInspection, allInspections: [TripInspection]) -> URL? {
        let pdfMetaData: [String: Any] = [
            "Creator": "FMS Fleet Management",
            "Author":  "Fleet Management System",
            "Title":   "Vehicle Inspection Report"
        ]
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { ctx in
            // ── Page 1: Header & Vehicle Info ───────────────────────────
            ctx.beginPage()
            drawPage1(ctx: ctx.cgContext, pageRect: pageRect, inspection: inspection)

            // ── Page 2+: Checklist ───────────────────────────────────────
            ctx.beginPage()
            drawChecklist(rendererContext: ctx, pageRect: pageRect, allInspections: allInspections)
            
            // ── Page 3+: Documentation & Analysis ────────────────────────
            let inspectionsWithImages = allInspections.filter { !$0.imagesData.isEmpty }
            if !inspectionsWithImages.isEmpty {
                ctx.beginPage()
                drawDocumentationPage(rendererContext: ctx, pageRect: pageRect, allInspections: inspectionsWithImages)
            }
        }

        // Write to temp file
        let dateString = Date().formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits)).replacingOccurrences(of: "/", with: "-")
        let cleanUnitName = inspection.unitName.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        let filename = "Report_\(cleanUnitName)_\(dateString).pdf"
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
        }
        return url
    }

    // MARK: Page 1 — Header + Vehicle Info
    private static func drawPage1(ctx: CGContext, pageRect: CGRect, inspection: TripInspection) {
        let margin: CGFloat = 48
        var y: CGFloat = margin

        // ── Brand header bar ─────────────────────────────────────────────
        let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 80)
        UIColor(AppColors.primary).setFill()
        ctx.fill(headerRect)

        "FLEET MANAGEMENT SYSTEM".draw(
            at: CGPoint(x: margin, y: 22),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.white
            ]
        )
        "Vehicle Inspection Report".draw(
            at: CGPoint(x: margin, y: 46),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
        )

        y = 100

        // ── Section: Vehicle Information ─────────────────────────────────
        y = drawSectionHeader("VEHICLE INFORMATION", y: y, pageRect: pageRect, ctx: ctx)

        let vehicleFields: [(String, String)] = [
            ("Vehicle",       inspection.unitName),
            ("VIN",           inspection.unitVIN),
            ("Type",          inspection.vehicleType.rawValue),
            ("Inspection",    inspection.type.rawValue),
            ("Date",          inspection.timestamp.formatted(date: .long, time: .shortened)),
            ("Inspector ID",  inspection.maintenanceStaffId),
            ("Driver ID",     inspection.driverId),
            ("Status",        inspection.status.rawValue)
        ]
        for (label, value) in vehicleFields {
            y = drawRow(label: label, value: value, y: y, margin: margin, pageRect: pageRect, ctx: ctx)
        }

        // ── Section: Metrics ─────────────────────────────────────────────
        y += 16
        y = drawSectionHeader("VEHICLE METRICS", y: y, pageRect: pageRect, ctx: ctx)

        let metrics: [(String, String)] = [
            ("Odometer",      inspection.odometer),
            ("Fuel Level",    inspection.fuelLevel),
            ("Fuel Effic.",   inspection.efficiency),
            ("Engine Hours",  inspection.engineHours)
        ]
        for (label, value) in metrics {
            y = drawRow(label: label, value: value, y: y, margin: margin, pageRect: pageRect, ctx: ctx)
        }

        // ── Summary stats ────────────────────────────────────────────────
        y += 24
        let good   = inspection.items.filter { $0.result == .good }.count
        let repair = inspection.items.filter { $0.result == .repair }.count
        let alert  = inspection.items.filter { $0.result == .alert }.count
        let pending = inspection.items.filter { $0.result == .pending }.count
        let total  = inspection.items.count

        y = drawSectionHeader("INSPECTION SUMMARY", y: y, pageRect: pageRect, ctx: ctx)
        y = drawRow(label: "Total Items",   value: "\(total)",  y: y, margin: margin, pageRect: pageRect, ctx: ctx)
        y = drawRow(label: "Good",          value: "\(good)",   y: y, margin: margin, pageRect: pageRect, ctx: ctx)
        y = drawRow(label: "Repair Needed", value: "\(repair)", y: y, margin: margin, pageRect: pageRect, ctx: ctx)
        y = drawRow(label: "Alert",         value: "\(alert)",  y: y, margin: margin, pageRect: pageRect, ctx: ctx)
        y = drawRow(label: "Pending",       value: "\(pending)", y: y, margin: margin, pageRect: pageRect, ctx: ctx)

        // Verdict badge
        y += 16
        let verdictColor: UIColor = (repair > 0 || alert > 0) ? .systemRed : .systemGreen
        let verdict: String       = (repair > 0 || alert > 0) ? "⚠ REQUIRES ATTENTION" : "✓ PASS"
        ctx.setFillColor(verdictColor.withAlphaComponent(0.1).cgColor)
        ctx.fill(CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: 36))
        verdict.draw(
            at: CGPoint(x: margin + 12, y: y + 10),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: verdictColor
            ]
        )
        y += 48

        // ── Notes ────────────────────────────────────────────────────────
        if let notes = inspection.notes, !notes.isEmpty {
            y = drawSectionHeader("ADDITIONAL NOTES", y: y, pageRect: pageRect, ctx: ctx)
            notes.draw(
                in: CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: 80),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.darkGray
                ]
            )
        }

        drawFooter(pageRect: pageRect, ctx: ctx, pageNumber: 1)
    }

    // MARK: Page 2 — Checklist Table
    private static func drawChecklist(rendererContext: UIGraphicsPDFRendererContext, pageRect: CGRect, allInspections: [TripInspection]) {
        let ctx = rendererContext.cgContext
        let margin: CGFloat = 48
        var y: CGFloat = margin
        
        let inspections = allInspections.sorted(by: { $0.type.rawValue < $1.type.rawValue })

        for inspection in inspections {
            if y > pageRect.height - 150 {
                drawFooter(pageRect: pageRect, ctx: ctx, pageNumber: 2)
                rendererContext.beginPage()
                y = margin
            }
            
            // Title
            "\(inspection.type.rawValue.uppercased()) CHECKLIST".draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                    .foregroundColor: UIColor(AppColors.primary)
                ]
            )
            y += 30

            // Column headers
            let colWidths: [CGFloat] = [220, 80, 120, 80]  // Item, Result, Notes/Criteria, Image
            let colX: [CGFloat] = [margin, margin + 220, margin + 300, margin + 420]
            let headers = ["Inspection Item", "Result", "Notes", "Photo"]

            ctx.setFillColor(UIColor(AppColors.primary).withAlphaComponent(0.08).cgColor)
            ctx.fill(CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: 22))

            for (i, header) in headers.enumerated() {
                header.draw(
                    at: CGPoint(x: colX[i] + 4, y: y + 5),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                        .foregroundColor: UIColor(AppColors.primary)
                    ]
                )
            }
            y += 26

            // Rows
            for (index, item) in inspection.items.enumerated() {
                if y > pageRect.height - 100 {
                    drawFooter(pageRect: pageRect, ctx: ctx, pageNumber: 2)
                    rendererContext.beginPage()
                    y = margin
                    
                    ctx.setFillColor(UIColor(AppColors.primary).withAlphaComponent(0.08).cgColor)
                    ctx.fill(CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: 22))
                    for (i, header) in headers.enumerated() {
                        header.draw(at: CGPoint(x: colX[i] + 4, y: y + 5), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor(AppColors.primary)])
                    }
                    y += 26
                }
                
                let rowHeight: CGFloat = 38
                let bg: UIColor = index.isMultiple(of: 2) ? UIColor.systemGray6 : .white
                ctx.setFillColor(bg.cgColor)
                ctx.fill(CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: rowHeight))

                // Item name
                item.name.draw(in: CGRect(x: colX[0] + 4, y: y + 4, width: colWidths[0] - 8, height: 30), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .medium), .foregroundColor: UIColor.black])
                
                // Result coloured
                let resultColor: UIColor
                switch item.result {
                case .good:    resultColor = .systemGreen
                case .repair:  resultColor = .systemOrange
                case .alert:   resultColor = .systemRed
                case .pending: resultColor = .systemGray
                }
                item.result.rawValue.draw(at: CGPoint(x: colX[1] + 4, y: y + 12), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: resultColor])

                // Notes
                let noteText = item.notes.isEmpty ? "—" : item.notes
                noteText.draw(in: CGRect(x: colX[2] + 4, y: y + 4, width: colWidths[2] - 8, height: 30), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.darkGray])

                // Photo
                if let data = item.imageData, let img = UIImage(data: data) {
                    let imgRect = CGRect(x: colX[3] + 4, y: y + 2, width: 32, height: 32)
                    img.draw(in: imgRect)
                } else {
                    "—".draw(at: CGPoint(x: colX[3] + 4, y: y + 12), withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.systemGray])
                }

                y += rowHeight
            }
            y += 40
        }

        if y > pageRect.height - 120 {
            drawFooter(pageRect: pageRect, ctx: ctx, pageNumber: 2)
            rendererContext.beginPage()
            y = margin
        }
        let signY = min(y, pageRect.height - 120)
        "Inspector Signature: ___________________________".draw(
            at: CGPoint(x: margin, y: signY),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.darkGray
            ]
        )
        "Date: ______________".draw(
            at: CGPoint(x: pageRect.width - 200, y: signY),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.darkGray
            ]
        )

        drawFooter(pageRect: pageRect, ctx: ctx, pageNumber: 2)
    }

    // MARK: Page 3 — Documentation & AI Analysis
    private static func drawDocumentationPage(rendererContext: UIGraphicsPDFRendererContext, pageRect: CGRect, allInspections: [TripInspection]) {
        let ctx = rendererContext.cgContext
        let margin: CGFloat = 48
        var y: CGFloat = margin

        // Page title
        "DOCUMENTATION & AI ANALYSIS".draw(
            at: CGPoint(x: margin, y: y),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: UIColor(AppColors.primary)
            ]
        )
        y += 40

        for inspection in allInspections {
            for (index, data) in inspection.imagesData.enumerated() {
                if let img = UIImage(data: data) {
                    // Image Box
                    let imgWidth: CGFloat = 120
                    let imgHeight: CGFloat = 120
                    let imgRect = CGRect(x: margin, y: y, width: imgWidth, height: imgHeight)
                    
                    // Draw rounded background for image
                    ctx.setFillColor(UIColor.systemGray6.cgColor)
                    ctx.fill(imgRect.insetBy(dx: -4, dy: -4))
                    img.draw(in: imgRect)
                    
                    // Analysis Text
                    let analysisX = margin + imgWidth + 24
                    let analysisWidth = pageRect.width - analysisX - margin
                    let analysis = inspection.imageAnalyses.indices.contains(index) ? inspection.imageAnalyses[index] : "Analysis not available."
                    
                    "AI ANALYSIS REPORT - \(inspection.type.rawValue.uppercased())".draw(
                        at: CGPoint(x: analysisX, y: y),
                        withAttributes: [
                            .font: UIFont.systemFont(ofSize: 10, weight: .black),
                            .foregroundColor: UIColor(AppColors.primary)
                        ]
                    )
                    
                    analysis.draw(
                        in: CGRect(x: analysisX, y: y + 16, width: analysisWidth, height: imgHeight - 16),
                        withAttributes: [
                            .font: UIFont.systemFont(ofSize: 10),
                            .foregroundColor: UIColor.darkGray
                        ]
                    )
                    
                    y += imgHeight + 40
                    
                    // Check if we need a new page
                    if y > pageRect.height - 150 {
                        drawFooter(pageRect: pageRect, ctx: ctx, pageNumber: 3)
                        rendererContext.beginPage()
                        y = margin
                    }
                }
            }
        }

        drawFooter(pageRect: pageRect, ctx: ctx, pageNumber: 3)
    }

    // MARK: Helpers
    @discardableResult
    private static func drawSectionHeader(_ title: String, y: CGFloat, pageRect: CGRect, ctx: CGContext) -> CGFloat {
        let margin: CGFloat = 48
        ctx.setFillColor(UIColor(AppColors.primary).withAlphaComponent(0.06).cgColor)
        ctx.fill(CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: 20))
        title.draw(
            at: CGPoint(x: margin + 4, y: y + 4),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 9, weight: .black),
                .foregroundColor: UIColor(AppColors.primary)
            ]
        )
        return y + 24
    }

    @discardableResult
    private static func drawRow(label: String, value: String, y: CGFloat, margin: CGFloat, pageRect: CGRect, ctx: CGContext) -> CGFloat {
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]
        label.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttrs)
        value.draw(at: CGPoint(x: margin + 140, y: y), withAttributes: valueAttrs)

        ctx.setStrokeColor(UIColor.systemGray5.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: margin, y: y + 16))
        ctx.addLine(to: CGPoint(x: pageRect.width - margin, y: y + 16))
        ctx.strokePath()

        return y + 20
    }

    private static func drawFooter(pageRect: CGRect, ctx: CGContext, pageNumber: Int) {
        let footerY = pageRect.height - 36
        ctx.setFillColor(UIColor.systemGray6.cgColor)
        ctx.fill(CGRect(x: 0, y: footerY, width: pageRect.width, height: 36))

        "Fleet Management System — Confidential".draw(
            at: CGPoint(x: 48, y: footerY + 10),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.darkGray
            ]
        )
        "Page \(pageNumber)".draw(
            at: CGPoint(x: pageRect.width - 72, y: footerY + 10),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.darkGray
            ]
        )
    }
}

// MARK: - Main View
struct DetailedInspectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    @State var inspection: TripInspection
    @State private var showingPDFPreview = false
    @State private var reportURL: URL?
    @State private var isGenerating = false

    @State private var showingDoneAlert = false

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
                            Text(inspection.type.rawValue)
                                .font(.caption.bold())
                                .foregroundColor(AppColors.primary)
                        }
                        Spacer()
                    }

                    Divider()

                    MetricsGrid(metrics: [
                        ("ODOMETER",     inspection.odometer),
                        ("FUEL LEVEL",   inspection.fuelLevel),
                        ("EFFICIENCY",   inspection.efficiency),
                        ("ENGINE HOURS", inspection.engineHours)
                    ])
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))

                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(title: "SYSTEM CHECKLIST", icon: "checklist")
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach($inspection.items, id: \.id) { $item in
                            InspectionListItem(item: $item)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))

                            if item.id != inspection.items.last?.id {
                                Divider().padding(.leading, 16)
                            }
                        }
                        // Add Other
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
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                }
                // Documentation Section
                if !inspection.imagesData.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Documentation", icon: "photo.fill")
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(0..<inspection.imagesData.count, id: \.self) { index in
                                ImageAnalysisCard(
                                    imageData: inspection.imagesData[index],
                                    analysis: inspection.imageAnalyses.indices.contains(index) ? inspection.imageAnalyses[index] : "Analysis not available"
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 120)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(inspection.title.isEmpty ? "Inspection" : inspection.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingDoneAlert = true }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.primary)
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
                PDFPreviewView(url: url, title: getReportTitle())
            } else {
                EmptyView()
            }
        }
    }

    private func getReportTitle() -> String {
        let initials = inspection.unitName.components(separatedBy: " ")
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        let dateStr = formatter.string(from: Date())
        
        return "\(initials) - \(dateStr)"
    }

    private func submitAndGeneratePDF() {
        // Ensure changes are persisted
        inspection.status = .completed
        store.updateInspection(inspection)
        
        isGenerating = true
        
        var inspectionsToInclude: [TripInspection] = [inspection]
        
        // If Post-Trip, include Pre-Trip as well (if available) for the report sections
        if inspection.type == .postTrip {
            let allForUnit = store.inspections.filter { $0.unitName == inspection.unitName }
            inspectionsToInclude = allForUnit.sorted(by: { $0.type.rawValue < $1.type.rawValue })
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let url = InspectionReportGenerator.generate(for: inspection, allInspections: inspectionsToInclude)
            DispatchQueue.main.async {
                isGenerating = false
                reportURL = url
                showingPDFPreview = url != nil
            }
        }
    }
}

// MARK: - Inspection List Item (Optional Images)
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
