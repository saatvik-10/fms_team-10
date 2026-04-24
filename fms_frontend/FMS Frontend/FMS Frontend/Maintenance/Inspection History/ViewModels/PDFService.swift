//
//  PDFService.swift
//  FMS Frontend
//

import PDFKit
internal import UIKit

class PDFService {
    static let shared = PDFService()
    
    // Page dimensions (A4 at 72 DPI)
    private let pageWidth: CGFloat = 8.27 * 72.0
    private let pageHeight: CGFloat = 11.69 * 72.0
    private let margin: CGFloat = 40.0
    private let secondaryColor = UIColor(red: 15/255, green: 28/255, blue: 36/255, alpha: 1.0)
    private let accentColor = UIColor(red: 242/255, green: 244/255, blue: 247/255, alpha: 1.0)
    
    func generateInspectionReport(inspection: TripInspection) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "FMS Maintenance App",
            kCGPDFContextAuthor: "Fleet Management System",
            kCGPDFContextTitle: "Report_\(inspection.unitName.replacingOccurrences(of: " ", with: ""))"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // 1. Header Bar
            let headerRect = CGRect(x: 0, y: 0, width: pageWidth, height: 80)
            secondaryColor.setFill()
            context.fill(headerRect)
            
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .black),
                .foregroundColor: UIColor.white
            ]
            "FLEET MANAGEMENT SYSTEM".draw(at: CGPoint(x: margin, y: 25), withAttributes: titleAttr)
            
            let subTitleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            "Vehicle Inspection Report".draw(at: CGPoint(x: margin, y: 48), withAttributes: subTitleAttr)
            
            var currentY: CGFloat = 100
            
            // 2. VEHICLE INFORMATION SECTION
            drawSectionHeader(title: "VEHICLE INFORMATION", at: &currentY, in: context)
            
            let vehicleInfo: [(String, String)] = [
                ("Vehicle", inspection.unitName),
                ("VIN", inspection.unitVIN),
                ("Type", inspection.vehicleType == .truck ? "Truck" : "Car"),
                ("Inspection", inspection.type == .preTrip ? "Pre-Trip" : "Post-Trip"),
                ("Date", inspection.timestamp.formatted(date: .long, time: .shortened)),
                ("Inspector ID", "STAFF-01"),
                ("Driver ID", "DRV-CURRENT"),
                ("Status", inspection.status.rawValue.capitalized)
            ]
            
            drawKeyValueGrid(info: vehicleInfo, at: &currentY, context: context)
            
            currentY += 20
            
            // 3. VEHICLE METRICS SECTION
            drawSectionHeader(title: "VEHICLE METRICS", at: &currentY, in: context)
            let metrics: [(String, String)] = [
                ("Fuel Level", "75%"),
                ("Fuel Effic.", "14.2 mpg"),
                ("Engine Hours", "4,821 hrs")
            ]
            drawKeyValueGrid(info: metrics, at: &currentY, context: context)
            
            currentY += 20
            
            // 4. INSPECTION SUMMARY
            drawSectionHeader(title: "INSPECTION SUMMARY", at: &currentY, in: context)
            let counts = getResultCounts(items: inspection.items)
            let summary: [(String, String)] = [
                ("Total Items", "\(inspection.items.count)"),
                ("Good", "\(counts.good)"),
                ("Repair Needed", "\(counts.repair)"),
                ("Alert", "\(counts.alert)"),
                ("Pending", "\(counts.pending)")
            ]
            drawKeyValueGrid(info: summary, at: &currentY, context: context)
            
            currentY += 20
            
            // PASS / FAIL Badge
            let passBadgeRect = CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 30)
            let isPass = counts.repair == 0 && counts.alert == 0
            (isPass ? UIColor.systemGreen : UIColor.systemRed).withAlphaComponent(0.1).setFill()
            context.fill(passBadgeRect)
            
            let badgeText = isPass ? "✓ PASS" : "✗ ATTENTION REQUIRED"
            let badgeAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: isPass ? UIColor.systemGreen : UIColor.systemRed
            ]
            badgeText.draw(at: CGPoint(x: margin + 10, y: currentY + 7), withAttributes: badgeAttr)
            
            currentY += 50
            
            // 5. ADDITIONAL NOTES
            drawSectionHeader(title: "ADDITIONAL NOTES", at: &currentY, in: context)
            let notesText = inspection.notes ?? "No additional notes provided."
            notesText.draw(in: CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 60), withAttributes: [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.label
            ])
            
            currentY += 40
            
            // Footer (Page 1)
            drawFooter(pageNum: 1, context: context)
            
            // START PAGE 2
            context.beginPage()
            currentY = 60
            
            // 6. INSPECTION CHECKLIST
            drawSectionHeader(title: "INSPECTION CHECKLIST", at: &currentY, in: context)
            
            // Table Header
            let tableHeaderY = currentY
            let colWidths: [CGFloat] = [180, 80, 180, 80] // Adjusted widths
            let headers = ["Inspection Item", "Result", "Notes", "Photo"]
            accentColor.setFill()
            context.fill(CGRect(x: margin, y: tableHeaderY, width: pageWidth - (margin * 2), height: 25))
            
            var currentX = margin + 10
            for (i, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: currentX, y: tableHeaderY + 5), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold)])
                currentX += colWidths[i]
            }
            
            currentY += 25
            
            // Table Rows
            for (index, item) in inspection.items.enumerated() {
                let rowHeight: CGFloat = 50 // Increased row height for photos/notes
                
                if currentY > pageHeight - 100 {
                    drawFooter(pageNum: 2, context: context)
                    context.beginPage()
                    currentY = 60
                }
                
                if index % 2 != 0 {
                    accentColor.withAlphaComponent(0.5).setFill()
                    context.fill(CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: rowHeight))
                }
                
                let rowX = margin + 10
                
                // Item Name
                item.name.draw(in: CGRect(x: rowX, y: currentY + 10, width: colWidths[0] - 10, height: rowHeight - 10), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold)])
                
                // Result
                let resultAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8, weight: .black),
                    .foregroundColor: resultColor(item.result)
                ]
                item.result.rawValue.uppercased().draw(at: CGPoint(x: rowX + colWidths[0], y: currentY + 18), withAttributes: resultAttr)
                
                // Notes
                let noteText = item.notes.isEmpty ? "—" : item.notes
                noteText.draw(in: CGRect(x: rowX + colWidths[0] + colWidths[1], y: currentY + 10, width: colWidths[2] - 10, height: rowHeight - 10), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 8),
                    .foregroundColor: item.notes.isEmpty ? UIColor.secondaryLabel : UIColor.label
                ])
                
                // Photo
                if let imageData = item.imageData, let image = UIImage(data: imageData) {
                    image.draw(in: CGRect(x: rowX + colWidths[0] + colWidths[1] + colWidths[2] + 10, y: currentY + 5, width: 40, height: 40))
                } else {
                    "—".draw(at: CGPoint(x: rowX + colWidths[0] + colWidths[1] + colWidths[2] + 25, y: currentY + 18), withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.secondaryLabel])
                }
                
                currentY += rowHeight
            }
            
            currentY += 40
            
            // 7. SIGNATURES
            let sigY = currentY
            "Inspector Signature: _______________________".draw(at: CGPoint(x: margin, y: sigY), withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            "Date: ____________".draw(at: CGPoint(x: pageWidth - 160, y: sigY), withAttributes: [.font: UIFont.systemFont(ofSize: 10)])
            
            drawFooter(pageNum: 2, context: context)
        }
        
        let fileName = "Report_\(inspection.unitName.replacingOccurrences(of: " ", with: "_")).pdf"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("PDF Error: \(error)")
            return nil
        }
    }
    
    // MARK: - Helpers
    
    private func drawSectionHeader(title: String, at y: inout CGFloat, in context: UIGraphicsPDFRendererContext) {
        let rect = CGRect(x: margin, y: y, width: pageWidth - (margin * 2), height: 18)
        accentColor.setFill()
        context.fill(rect)
        
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: UIColor.secondaryLabel
        ]
        title.draw(at: CGPoint(x: margin + 5, y: y + 4), withAttributes: attr)
        y += 24
    }
    
    private func drawKeyValueGrid(info: [(String, String)], at y: inout CGFloat, context: UIGraphicsPDFRendererContext) {
        let labelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.secondaryLabel]
        let valueAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10, weight: .medium), .foregroundColor: UIColor.label]
        
        for item in info {
            item.0.draw(at: CGPoint(x: margin + 5, y: y), withAttributes: labelAttr)
            item.1.draw(at: CGPoint(x: margin + 150, y: y), withAttributes: valueAttr)
            
            let line = UIBezierPath()
            line.move(to: CGPoint(x: margin, y: y + 16))
            line.addLine(to: CGPoint(x: pageWidth - margin, y: y + 16))
            UIColor.separator.withAlphaComponent(0.5).setStroke()
            line.stroke()
            
            y += 20
        }
    }
    
    private func drawFooter(pageNum: Int, context: UIGraphicsPDFRendererContext) {
        let footerY = pageHeight - 40
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: footerY))
        line.addLine(to: CGPoint(x: pageWidth - margin, y: footerY))
        UIColor.separator.setStroke()
        line.stroke()
        
        let attr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.secondaryLabel]
        "Fleet Management System — Confidential".draw(at: CGPoint(x: margin, y: footerY + 10), withAttributes: attr)
        "Page \(pageNum)".draw(at: CGPoint(x: pageWidth - margin - 40, y: footerY + 10), withAttributes: attr)
    }
    
    private func resultColor(_ result: InspectionResult) -> UIColor {
        switch result {
        case .good: return .systemGreen
        case .repair: return .systemOrange
        case .alert: return .systemRed
        case .pending: return .systemGray
        }
    }
    
    private func getResultCounts(items: [InspectionItem]) -> (good: Int, repair: Int, alert: Int, pending: Int) {
        var g = 0, r = 0, a = 0, p = 0
        for i in items {
            switch i.result {
            case .good: g += 1
            case .repair: r += 1
            case .alert: a += 1
            case .pending: p += 1
            }
        }
        return (g, r, a, p)
    }
}
