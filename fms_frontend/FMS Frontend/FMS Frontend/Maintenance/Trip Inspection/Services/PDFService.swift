//
//  PDFService.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import PDFKit
import UIKit

class PDFService {
    static let shared = PDFService()
    
    func generateInspectionReport(inspection: TripInspection) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "FMS Maintenance App",
            kCGPDFContextAuthor: "Fleet Maintenance System",
            kCGPDFContextTitle: "Inspection Report - \(inspection.vehicleId)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // A4 Page Size
        let pageWidth = 8.27 * 72.0
        let pageHeight = 11.69 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // Draw Header
            let title = "VEHICLE INSPECTION REPORT"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor(hex: "0F1C24") ?? .black
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            title.draw(at: CGPoint(x: (pageWidth - titleSize.width) / 2, y: 40), withAttributes: titleAttributes)
            
            // Draw Date & ID
            let dateStr = "Date: \(inspection.timestamp.formatted(date: .abbreviated, time: .shortened))"
            let vehicleStr = "Vehicle ID: \(inspection.vehicleId)"
            let subHeaderAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            
            dateStr.draw(at: CGPoint(x: 40, y: 90), withAttributes: subHeaderAttributes)
            vehicleStr.draw(at: CGPoint(x: 40, y: 110), withAttributes: subHeaderAttributes)
            
            // Draw Divider
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: 40, y: 140))
            dividerPath.addLine(to: CGPoint(x: pageWidth - 40, y: 140))
            dividerPath.lineWidth = 1
            UIColor.lightGray.setStroke()
            dividerPath.stroke()
            
            // Draw Checklist Table Header
            "CHECKLIST ITEM".draw(at: CGPoint(x: 40, y: 160), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10)])
            "STATUS".draw(at: CGPoint(x: pageWidth - 100, y: 160), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10)])
            
            var currentY: CGFloat = 185
            
            for item in inspection.items {
                // Item Name
                let name = item.name
                name.draw(at: CGPoint(x: 40, y: currentY), withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
                
                // Status
                let status = item.result == .good ? "PASS" : (item.result == .repair ? "REPAIR" : (item.result == .alert ? "FAIL" : "PENDING"))
                let statusColor: UIColor
                switch item.result {
                case .good: statusColor = .systemGreen
                case .repair: statusColor = .systemOrange
                case .alert: statusColor = .systemRed
                case .pending: statusColor = .systemGray
                }
                
                status.draw(at: CGPoint(x: pageWidth - 100, y: currentY), withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 12),
                    .foregroundColor: statusColor
                ])
                
                // Criteria (Smaller text)
                let criteria = item.verificationCriteria
                let criteriaAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                criteria.draw(at: CGPoint(x: 40, y: currentY + 15), withAttributes: criteriaAttr)
                
                // Draw Item Divider
                let itemDivider = UIBezierPath()
                itemDivider.move(to: CGPoint(x: 40, y: currentY + 30))
                itemDivider.addLine(to: CGPoint(x: pageWidth - 40, y: currentY + 30))
                UIColor.separator.setStroke()
                itemDivider.stroke()
                
                currentY += 45
            }
            
            // Draw Evidence Images Section
            currentY += 20
            "VISUAL EVIDENCE".draw(at: CGPoint(x: 40, y: currentY), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
            currentY += 25
            
            var imageX: CGFloat = 40
            let imageSize: CGFloat = 120
            
            for item in inspection.items {
                if let imageData = item.imageData, let image = UIImage(data: imageData) {
                    image.draw(in: CGRect(x: imageX, y: currentY, width: imageSize, height: imageSize))
                    
                    // Label for image
                    let label = item.name
                    label.draw(at: CGPoint(x: imageX, y: currentY + imageSize + 5), withAttributes: [.font: UIFont.systemFont(ofSize: 8)])
                    
                    imageX += imageSize + 20
                    if imageX + imageSize > pageWidth - 40 {
                        imageX = 40
                        currentY += imageSize + 40
                    }
                }
            }
        }
        
        // Save to Documents
        let fileName = "Report_\(inspection.vehicleId)_\(UUID().uuidString.prefix(6)).pdf"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Could not save PDF: \(error)")
            return nil
        }
    }
}

// Helper for Hex conversion in PDF
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
