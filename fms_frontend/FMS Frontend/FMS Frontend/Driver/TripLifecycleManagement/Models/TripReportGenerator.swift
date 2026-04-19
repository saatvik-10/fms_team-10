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
    private let marginH:    CGFloat = 40

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
            case .standard, .link: return 22
            case .total:           return 30
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

        drawBlock(number: 1, title: "TRIP INFORMATION",        rows: tripInfoRows(data))
        drawBlock(number: 2, title: "DISTANCE & FUEL METRICS", rows: fuelRows(data))
        drawBlock(number: 3, title: "PERFORMANCE METRICS",     rows: performanceRows(data))
        drawBlock(number: 4, title: "COST BREAKDOWN",          rows: costRows(data))

        drawFooter()
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    // MARK: ── Header ──────────────────────────────────────────────────────

    private func drawHeader(data: TripReportData) {
        let h: CGFloat = 90
        navy.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: pageWidth, height: h))

        // Eye-brow label
        put("FLEET MANAGEMENT SYSTEM",
            at: CGPoint(x: marginH, y: 15),
            font: .systemFont(ofSize: 9, weight: .semibold),
            color: .white, alpha: 0.55, kern: 2.8)

        // Main title
        put("Trip Completion Report",
            at: CGPoint(x: marginH, y: 33),
            font: .systemFont(ofSize: 22, weight: .bold),
            color: .white)

        // Subtitle
        put("Official Vehicle & Driver Performance Summary",
            at: CGPoint(x: marginH, y: 61),
            font: .systemFont(ofSize: 10, weight: .regular),
            color: .white, alpha: 0.55)

        // Trip ID badge (right)
        let pillFont  = UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)
        let pillAttrs: [NSAttributedString.Key: Any] = [.font: pillFont, .foregroundColor: navy]
        let pillSize  = (data.tripID as NSString).size(withAttributes: pillAttrs)
        let pillW     = pillSize.width + 24
        let pillH: CGFloat  = 26
        let pillX     = pageWidth - marginH - pillW
        let pillY: CGFloat  = 38

        UIColor.white.setFill()
        UIBezierPath(roundedRect: CGRect(x: pillX, y: pillY, width: pillW, height: pillH),
                     cornerRadius: 5).fill()
        (data.tripID as NSString).draw(at: CGPoint(x: pillX + 12, y: pillY + 5),
                                        withAttributes: pillAttrs)
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
            ("STATUS",   "COMPLETED ✓")
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

    private func drawBlock(number: Int, title: String, rows: [RowItem]) {
        // Page-break guard
        let totalH = 28 + 8 + rows.reduce(0) { $0 + $1.height } + 8
        if y + totalH > pageHeight - 36 {
            UIGraphicsBeginPDFPage()
            y = 36
        }

        let headerH: CGFloat = 28

        // 1. Section content background (bottom-rounded)
        sectionBg.setFill()
        let contentH = 8 + rows.reduce(0) { $0 + $1.height } + 8
        UIBezierPath(
            roundedRect: CGRect(x: sectionX, y: y + headerH, width: sectionW, height: contentH),
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: 6, height: 6)
        ).fill()

        // 2. Section header (top-rounded)
        navy.setFill()
        UIBezierPath(
            roundedRect: CGRect(x: sectionX, y: y, width: sectionW, height: headerH),
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 6, height: 6)
        ).fill()
        put("\(number)  \(title)",
            at: CGPoint(x: sectionX + 14, y: y + 9),
            font: .systemFont(ofSize: 10, weight: .bold), color: .white, kern: 0.5)


        y += headerH + 8  // enter content area

        // 3. Draw rows on top of already-rendered background
        for (i, row) in rows.enumerated() {
            drawRow(row, index: i)
        }

        y += 8   // bottom inner padding
        y += 14  // gap to next section
    }

    // MARK: ── Row rendering ───────────────────────────────────────────────

    private func drawRow(_ row: RowItem, index: Int) {
        let labelX = sectionX + 16
        let valueX = sectionX + sectionW * 0.52

        switch row {
        case .standard(let label, let value):
            if index % 2 == 0 {
                zebraWhite.setFill()
                UIRectFill(CGRect(x: sectionX, y: y, width: sectionW, height: row.height))
            }
            put(label, at: CGPoint(x: labelX, y: y + 6),
                font: .systemFont(ofSize: 9.5, weight: .medium), color: bodyGray)
            put(value, at: CGPoint(x: valueX, y: y + 6),
                font: .systemFont(ofSize: 9.5, weight: .semibold), color: .black)
            divider.setFill()
            UIRectFill(CGRect(x: labelX, y: y + row.height - 0.5, width: sectionW - 32, height: 0.5))
            y += row.height

        case .link(let label, let displayText):
            if index % 2 == 0 {
                zebraWhite.setFill()
                UIRectFill(CGRect(x: sectionX, y: y, width: sectionW, height: row.height))
            }
            put(label,       at: CGPoint(x: labelX, y: y + 6),
                font: .systemFont(ofSize: 9.5, weight: .medium), color: bodyGray)
            put(displayText, at: CGPoint(x: valueX, y: y + 6),
                font: .systemFont(ofSize: 9.5, weight: .semibold), color: accentBlue, underline: true)
            y += row.height

        case .total(let label, let value):
            navy.setFill()
            UIBezierPath(
                roundedRect: CGRect(x: sectionX, y: y, width: sectionW, height: row.height),
                byRoundingCorners: [.bottomLeft, .bottomRight],
                cornerRadii: CGSize(width: 6, height: 6)
            ).fill()
            put(label, at: CGPoint(x: labelX, y: y + 9),
                font: .systemFont(ofSize: 11, weight: .bold), color: .white)
            put(value, at: CGPoint(x: valueX, y: y + 8),
                font: .systemFont(ofSize: 13, weight: .heavy), color: .white)
            y += row.height
        }
    }

    // MARK: ── Section data builders ──────────────────────────────────────

    private func tripInfoRows(_ d: TripReportData) -> [RowItem] {
        [
            .standard(label: "Trip ID",            value: d.tripID),
            .standard(label: "Vehicle ID",         value: d.vehicleID),
            .standard(label: "Vehicle Number",     value: d.vehicleNumber),
            .standard(label: "Driver Name",        value: d.driverName),
            .standard(label: "Driver ID",          value: d.driverID),
            .standard(label: "Start Date & Time",  value: d.startDateTime),
            .standard(label: "End Date & Time",    value: d.endDateTime),
            .standard(label: "Trip Duration",      value: d.tripDuration),
            .standard(label: "Start Location",     value: d.startLocation),
            .standard(label: "End Location",       value: d.endLocation),
        ]
    }

    private func fuelRows(_ d: TripReportData) -> [RowItem] { [
        .standard(label: "Total Distance Covered", value: String(format: "%.1f km",    d.totalDistanceKm)),
        .standard(label: "Fuel Consumed",          value: String(format: "%.2f L",     d.fuelConsumedLiters)),
        .standard(label: "Fuel Efficiency",        value: String(format: "%.2f km/L",  d.fuelEfficiencyKmL)),
        .standard(label: "Fuel Cost",              value: fmt(d.fuelCostINR)),
    ] }

    private func performanceRows(_ d: TripReportData) -> [RowItem] {
        let dh = Int(d.drivingTimeHours * 60)
        let ih = Int(d.idleTimeHours    * 60)
        var rows: [RowItem] = [
            .standard(label: "Average Speed",  value: String(format: "%.1f km/h", d.averageSpeedKmH)),
            .standard(label: "Max Speed",      value: String(format: "%.1f km/h", d.maxSpeedKmH)),
            .standard(label: "Driving Time",   value: "\(dh / 60)h \(dh % 60)m"),
            .standard(label: "Idle Time",      value: "\(ih / 60)h \(ih % 60)m"),
            .standard(label: "Stops Count",    value: "\(d.stopsCount) stops"),
        ]
        if let rh = d.restingHours {
            let rm = Int(rh * 60)
            rows.append(.standard(label: "Resting Hours", value: "\(rm / 60)h \(rm % 60)m"))
        }
        return rows
    }

    private func costRows(_ d: TripReportData) -> [RowItem] { [
        .standard(label: "Toll Charges", value: fmt(d.tollCostINR)),
        .standard(label: "Driver Cost",  value: fmt(d.driverCostINR)),
        .total(   label: "TOTAL COST",   value: fmt(d.totalCostINR)),
    ] }

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
