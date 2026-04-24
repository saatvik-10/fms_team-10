internal import UIKit
import PDFKit

// MARK: - Professional Fleet Trip Report Generator
// Produces an industry-grade A4 PDF with:
//   • Full-bleed navy header + trip-ID badge
//   • Dark sub-banner (vehicle / driver / date / status)
//   • 4 sectioned blocks with PRE-rendered backgrounds (correct PDF layer order)
//   • Zebra-striped rows, label-value columns
//   • Navy highlighted "TOTAL COST" row
//   • Clickable Google Maps route link
//   • Confidential footer with generation timestamp

final class TripReportGenerator {

    // ── Page geometry ──────────────────────────────────────────────────────
    private let pageWidth:  CGFloat = 595.2   // A4 pt width
    private let pageHeight: CGFloat = 841.8   // A4 pt height
    private let marginH:    CGFloat = 20  // Reduced for wider card

    // ── Brand palette ──────────────────────────────────────────────────────
    private let navy       = UIColor(red: 15/255,  green: 28/255,  blue: 36/255,  alpha: 1)
    private let darkBanner = UIColor(red: 30/255,  green: 50/255,  blue: 65/255,  alpha: 1)
    private let sectionBg  = UIColor(red: 246/255, green: 248/255, blue: 250/255, alpha: 1)
    private let accentBlue = UIColor(red: 0/255,   green: 102/255, blue: 204/255, alpha: 1)
    private let divider    = UIColor(red: 218/255,  green: 224/255, blue: 230/255, alpha: 1)
    private let bodyGray   = UIColor(red: 85/255,  green: 95/255,  blue: 107/255, alpha: 1)
    private let zebraWhite = UIColor.white.withAlphaComponent(0.55)

    // ── Computed helpers ───────────────────────────────────────────────────
    private var sectionX: CGFloat { marginH }
    private var sectionW: CGFloat { pageWidth - marginH * 2 }

    // ── Running vertical cursor ────────────────────────────────────────────
    private var y: CGFloat = 0

    // MARK: ── Row model ───────────────────────────────────────────────────

    enum RowItem {
        case standard(label: String, value: String)
        case link(label: String, displayText: String)
        case total(label: String, value: String)

        var height: CGFloat {
            switch self {
            case .standard, .link: return 34  // Increased for better spacing
            case .total:           return 40
            }
        }
    }

    // MARK: ── Public entry point ──────────────────────────────────────────

    func generate(from data: TripReportData) -> Data {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(
            pdfData,
            CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            nil
        )
        UIGraphicsBeginPDFPage()

        y = 0
        drawHeader(data: data)
        drawMetaBanner(data: data)
        y += 16

        // Combine all rows into one unified section
        var allRows = tripInfoRows(data)
        allRows.append(contentsOf: fuelRows(data))
        allRows.append(contentsOf: performanceRows(data))

        drawBlock(title: "TRIP INFORMATION", rows: allRows)

        drawFooter()
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    // MARK: ── Header ──────────────────────────────────────────────────────

    private func drawHeader(data: TripReportData) {
        let h: CGFloat = 90
        navy.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: pageWidth, height: h))

        // Main title (now at the top)
        put("Trip Completion Report",
            at: CGPoint(x: marginH, y: 22),
            font: .systemFont(ofSize: 22, weight: .bold),
            color: .white)

        // Subtitle
        put("Official Vehicle & Driver Performance Summary",
            at: CGPoint(x: marginH, y: 52),
            font: .systemFont(ofSize: 10, weight: .regular),
            color: .white, alpha: 0.55)

        y = h
    }

    // MARK: ── Meta banner ─────────────────────────────────────────────────

    private func drawMetaBanner(data: TripReportData) {
        let h: CGFloat = 44
        darkBanner.setFill()
        UIRectFill(CGRect(x: 0, y: y, width: pageWidth, height: h))

        let items: [(String, String)] = [
            ("VEHICLE",  data.vehicleNumber),
            ("DRIVER",   data.driverName),
            ("DATE",     shortDate(data.startDateTime)),
            ("STATUS",   "COMPLETED")
        ]
        let colW = sectionW / CGFloat(items.count)
        for (i, (label, value)) in items.enumerated() {
            let x = sectionX + CGFloat(i) * colW
            put(label, at: CGPoint(x: x, y: y + 7),
                font: .systemFont(ofSize: 8, weight: .medium), color: .white, alpha: 0.6, kern: 1.5)
            put(value, at: CGPoint(x: x, y: y + 21),
                font: .systemFont(ofSize: 10, weight: .bold), color: .white)
        }
        y += h
    }

    // MARK: ── Section block (single-pass, bg drawn before text) ──────────

    private func drawBlock(title: String, rows: [RowItem]) {
        // Page-break guard
        let totalH = 40 + 12 + rows.reduce(0) { $0 + $1.height } + 12
        if y + totalH > pageHeight - 36 {
            UIGraphicsBeginPDFPage()
            y = 36
        }

        let headerH: CGFloat = 40

        // 1. Section content background (bottom-rounded)
        sectionBg.setFill()
        let contentH = 12 + rows.reduce(0) { $0 + $1.height } + 12
        UIBezierPath(
            roundedRect: CGRect(x: sectionX, y: y + headerH, width: sectionW, height: contentH),
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: 8, height: 8)
        ).fill()

        // 2. Section header (top-rounded)
        navy.setFill()
        UIBezierPath(
            roundedRect: CGRect(x: sectionX, y: y, width: sectionW, height: headerH),
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 8, height: 8)
        ).fill()
        
        put(title,
            at: CGPoint(x: sectionX + 20, y: y + 13),
            font: .systemFont(ofSize: 12, weight: .bold), color: .white, kern: 1.2)


        y += headerH + 12  // enter content area

        // 3. Draw rows on top of already-rendered background
        for (i, row) in rows.enumerated() {
            drawRow(row, index: i)
        }

        y += 8   // bottom inner padding
        y += 14  // gap to next section
    }

    // MARK: ── Row rendering ───────────────────────────────────────────────

    private func drawRow(_ row: RowItem, index: Int) {
        let labelX = sectionX + 20
        let valueX = sectionX + sectionW * 0.48 // Start value column slightly earlier but with more space

        switch row {
        case .standard(let label, let value):
            if index % 2 == 0 {
                zebraWhite.setFill()
                UIRectFill(CGRect(x: sectionX, y: y, width: sectionW, height: row.height))
            }
            
            // Label: Lighter, smaller
            put(label, at: CGPoint(x: labelX, y: y + 10),
                font: .systemFont(ofSize: 9, weight: .medium), color: bodyGray)
            
            // Value: Larger, semibold
            put(value, at: CGPoint(x: valueX, y: y + 9),
                font: .systemFont(ofSize: 11, weight: .semibold), color: .black)
            
            // Subtle divider
            divider.setFill()
            UIRectFill(CGRect(x: labelX, y: y + row.height - 0.5, width: sectionW - 40, height: 0.5))
            
            y += row.height

        case .link(let label, let displayText):
            if index % 2 == 0 {
                zebraWhite.setFill()
                UIRectFill(CGRect(x: sectionX, y: y, width: sectionW, height: row.height))
            }
            put(label,       at: CGPoint(x: labelX, y: y + 10),
                font: .systemFont(ofSize: 9, weight: .medium), color: bodyGray)
            put(displayText, at: CGPoint(x: valueX, y: y + 9),
                font: .systemFont(ofSize: 11, weight: .semibold), color: accentBlue, underline: true)
            y += row.height

        case .total(let label, let value):
            navy.setFill()
            UIBezierPath(
                roundedRect: CGRect(x: sectionX, y: y, width: sectionW, height: row.height),
                byRoundingCorners: [.bottomLeft, .bottomRight],
                cornerRadii: CGSize(width: 8, height: 8)
            ).fill()
            put(label, at: CGPoint(x: labelX, y: y + 13),
                font: .systemFont(ofSize: 12, weight: .bold), color: .white)
            put(value, at: CGPoint(x: valueX, y: y + 11),
                font: .systemFont(ofSize: 14, weight: .heavy), color: .white)
            y += row.height
        }
    }

    // MARK: ── Section data builders ──────────────────────────────────────

    private func tripInfoRows(_ d: TripReportData) -> [RowItem] {
        [
            .standard(label: "Vehicle Number",     value: d.vehicleNumber),
            .standard(label: "Driver Name",        value: d.driverName),
            .standard(label: "Start Date & Time",  value: d.startDateTime),
            .standard(label: "End Date & Time",    value: d.endDateTime),
            .standard(label: "Start Location",     value: d.startLocation),
            .standard(label: "End Location",       value: d.endLocation),
        ]
    }

    private func fuelRows(_ d: TripReportData) -> [RowItem] { [
        .standard(label: "Total Distance Covered", value: String(format: "%.1f km",    d.totalDistanceKm)),
    ] }

    private func performanceRows(_ d: TripReportData) -> [RowItem] {
        let dh = Int(d.drivingTimeHours * 60)
        return [
            .standard(label: "Driving Time",   value: "\(dh / 60)h \(dh % 60)m"),
        ]
    }

    // MARK: ── Footer ──────────────────────────────────────────────────────

    private func drawFooter() {
        let fy = pageHeight - 26
        divider.setFill()
        UIRectFill(CGRect(x: marginH, y: fy - 5, width: sectionW, height: 0.5))

        put("Generated: \(formattedNow())",
            at: CGPoint(x: marginH, y: fy),
            font: .systemFont(ofSize: 8, weight: .regular), color: bodyGray)

        let conf = "CONFIDENTIAL — For internal fleet use only"
        let cw = (conf as NSString).size(withAttributes: [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular)
        ]).width
        put(conf,
            at: CGPoint(x: pageWidth - marginH - cw, y: fy),
            font: .systemFont(ofSize: 8, weight: .regular), color: bodyGray)
    }

    // MARK: ── Primitives ──────────────────────────────────────────────────

    @discardableResult
    private func put(_ text: String,
                     at point: CGPoint,
                     font: UIFont,
                     color: UIColor,
                     alpha: CGFloat = 1.0,
                     kern: CGFloat = 0,
                     underline: Bool = false) -> CGSize {
        var attrs: [NSAttributedString.Key: Any] = [
            .font:            font,
            .foregroundColor: color.withAlphaComponent(alpha),
            .kern:            kern
        ]
        if underline { attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue }
        let ns = text as NSString
        ns.draw(at: point, withAttributes: attrs)
        return ns.size(withAttributes: attrs)
    }

    private func fmt(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle           = .currency
        f.currencySymbol        = "₹"
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: amount)) ?? String(format: "₹%.2f", amount)
    }

    private func formattedNow() -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy, HH:mm"
        return f.string(from: Date())
    }

    private func shortDate(_ dateTime: String) -> String {
        dateTime.components(separatedBy: "  ").first ?? dateTime
    }
}
