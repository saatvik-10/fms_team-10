//
//  RC.swift
//  Nigga
//
//  Created by Harsh Choudhary on 20/04/26.
//

import SwiftUI
import Vision
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Data Model

struct RCData {
    var regNumber: String?
    var owner: String?
    var address: String?

    var engineNumber: String?
    var chassis: String?

    var model: String?
    var vehicleClass: String?
    var fuel: String?

    var regDate: String?
    var validity: String?

    var mfgYear: String?
    var seatingCapacity: String?
}

// MARK: - ContentView

struct AddRC: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var parsedData = RCData()
    @State private var rawLines: [String] = []
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Image Preview
                Group {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 220)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        ContentUnavailableView(
                            "No RC Selected",
                            systemImage: "card.text",
                            description: Text("Pick an image to begin")
                        )
                        .frame(height: 220)
                    }
                }
                .padding(.top)
                
                // Controls
                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Pick Photo", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: runOCR) {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Label("Scan RC", systemImage: "barcode.viewfinder")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedImage == nil || isProcessing)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                
                // Results
                List {
                    Section("Vehicle") {
                        ResultRow(label: "Reg Number", value: parsedData.regNumber, icon: "number.circle.fill")
                        ResultRow(label: "Chassis No", value: parsedData.chassis, icon: "barcode")
                        ResultRow(label: "Engine No", value: parsedData.engineNumber, icon: "gear")
                        ResultRow(label: "Model", value: parsedData.model, icon: "car.circle")
                        ResultRow(label: "Vehicle Class", value: parsedData.vehicleClass, icon: "tag.fill")
                        ResultRow(label: "Fuel Type", value: parsedData.fuel, icon: "fuelpump.fill")
                        ResultRow(label: "Seating", value: parsedData.seatingCapacity, icon: "person.2.fill")
                        ResultRow(label: "Mfg Year", value: parsedData.mfgYear, icon: "wrench.fill")
                    }
                    
                    Section("Owner") {
                        ResultRow(label: "Owner Name", value: parsedData.owner, icon: "person.fill")
                        ResultRow(label: "Address", value: parsedData.address, icon: "location.fill")
                    }
                    
                    Section("Validity") {
                        ResultRow(label: "Reg Date", value: parsedData.regDate, icon: "calendar")
                        ResultRow(label: "Valid Till", value: parsedData.validity, icon: "checkmark.seal.fill")
                    }
                    
                    if !rawLines.isEmpty {
                        Section {
                            DisclosureGroup("Raw OCR (\(rawLines.count) lines)") {
                                ForEach(Array(rawLines.enumerated()), id: \.offset) { i, line in
                                    Text("\(i+1). \(line)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            
            .navigationTitle("RC Scanner")
            .onChange(of: selectedItem) { _, newItem in loadImage(from: newItem) }
        }
    }
    
    
    // MARK: - Load Image
    
    func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = uiImage
                    parsedData = RCData()
                    rawLines = []
                }
            }
        }
    }
    
    // MARK: - OCR Pipeline
    
    func runOCR() {
        guard let image = selectedImage else { return }
        isProcessing = true
        
        Task.detached(priority: .userInitiated) {
            let processed = preprocessImage(image) ?? image
            guard let cgImage = processed.cgImage else {
                await MainActor.run { isProcessing = false }
                return
            }
            
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-IN", "en-US"]
            request.usesLanguageCorrection = true
            request.customWords = [
                "MCWG", "LMV", "HMV", "HPMV", "LMVTR",
                "Petrol", "Diesel", "CNG", "Electric",
                "Chassis", "Hypothecation", "Fitness",
                "Activa", "Splendor", "Pulsar", "Swift"
            ]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            try? handler.perform([request])
            
            let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
            
            // Sort top-to-bottom, left-to-right
            let sorted = observations.sorted {
                let dy = $1.boundingBox.minY - $0.boundingBox.minY
                return abs(dy) > 0.015 ? dy > 0 : $0.boundingBox.minX < $1.boundingBox.minX
            }
            
            let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
            let result = parseRC(lines: lines)
            
            await MainActor.run {
                rawLines = lines
                parsedData = result
                isProcessing = false
            }
        }
    }
    
    // MARK: - Preprocess
    
    func preprocessImage(_ image: UIImage) -> UIImage? {
        guard let ci = CIImage(image: image) else { return nil }
        let f = CIFilter.colorControls()
        f.inputImage = ci
        f.saturation = 0.0
        f.contrast = 1.5
        f.brightness = 0.05
        let ctx = CIContext()
        guard let out = f.outputImage,
              let cg = ctx.createCGImage(out, from: out.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
    
    // MARK: - Main Parser
    
    func parseRC(lines: [String]) -> RCData {
        var d = RCData()
        
        let norm: [String] = lines.map {
            $0.uppercased()
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }
        
        let full = norm.joined(separator: "\n")
        
        // ── REG NUMBER ─────────────────────────────────────────────────────────
        if let raw = firstMatch(#"[A-Z]{2}[\s\-]?\d{2}[\s\-]?[A-Z]{1,3}[\s\-]?\d{1,4}"#, in: full) {
            d.regNumber = raw.replacingOccurrences(of: #"[\s\-]"#, with: "", options: .regularExpression)
        }
        
        // ── CHASSIS ────────────────────────────────────────────────────────────
        d.chassis = extractField(from: norm, keys: [
            "CHASSIS NO", "CHASSIS NUMBER", "CHASIS NO", "VIN NO"
        ]) { val in
            val.replacingOccurrences(of: " ", with: "")
                .range(of: #"^[A-Z0-9]{8,20}$"#, options: .regularExpression) != nil
        }
        
        // ── ENGINE ─────────────────────────────────────────────────────────────
        d.engineNumber = extractField(from: norm, keys: [
            "ENGINE NO", "ENGINE NUMBER", "ENG NO"
        ]) { val in
            val.replacingOccurrences(of: " ", with: "")
                .range(of: #"^[A-Z0-9]{6,20}$"#, options: .regularExpression) != nil
        }
        
        // ── OWNER NAME ─────────────────────────────────────────────────────────
        // Card prints "Owner's Name:" — after uppercasing becomes "OWNER'S NAME"
        // Also handle OCR misreading apostrophe as space → "OWNER S NAME"
        d.owner = extractField(from: norm, keys: [
            "OWNER'S NAME", "OWNER S NAME", "NAME OF OWNER",
            "OWNER NAME", "RC OWNER", "REGISTERED OWNER"
        ]) { val in
            let junk = ["GOVERNMENT", "TRANSPORT", "DEPARTMENT", "INDIA", "MINISTRY", "CERTIFICATE"]
            return val.count >= 3 && !junk.contains(where: { val.contains($0) })
        }
        
        
        
        // ── ADDRESS ───────────────────────────────────────────────────────────
        d.address = extractMultiLine(from: norm, keys: [
            "ADDRESS", "PRESENT ADDRESS", "PERMANENT ADDRESS"
        ], maxLines: 3)
        
        // ── VEHICLE CLASS ──────────────────────────────────────────────────────
        d.vehicleClass = extractField(from: norm, keys: [
            "VEHICLE CLASS", "CLASS OF VEHICLE", "VEH CLASS"
        ])
        
        // ── FUEL ──────────────────────────────────────────────────────────────
        d.fuel = extractField(from: norm, keys: [
            "FUEL TYPE", "TYPE OF FUEL", "FUEL USED", "FUEL"
        ]) ?? firstInText(full, candidates: ["PETROL", "DIESEL", "CNG", "LPG", "ELECTRIC", "EV", "HYBRID"])
        
        // ── MODEL / MFG YEAR / SEATING — all three often on one line ──────────
        // e.g. "Model: SWIFT DX    Mfg. Year: 2020    Seating Capacity: 5"
        if let modelLine = norm.first(where: { $0.contains("MODEL") }) {
            d.model           = inlineValue(from: modelLine, key: "MODEL")
            d.mfgYear         = inlineValue(from: modelLine, key: "MFG. YEAR")
            ?? inlineValue(from: modelLine, key: "MFG YEAR")
            ?? inlineValue(from: modelLine, key: "MFG")
            d.seatingCapacity = inlineValue(from: modelLine, key: "SEATING CAPACITY")
            ?? inlineValue(from: modelLine, key: "SEATING")
        }
        
        // ── MFG YEAR fallback ─────────────────────────────────────────────────
        if d.mfgYear == nil {
            d.mfgYear = extractField(from: norm, keys: [
                "MONTH & YEAR OF MFG", "MFG. YEAR", "MFG YEAR",
                "YEAR OF MFG", "MFG DATE", "MANUFACTURING YEAR"
            ]) ?? allMatches(#"\b(19|20)\d{2}\b"#, in: full).last
        }
        
        // ── SEATING fallback ──────────────────────────────────────────────────
        if d.seatingCapacity == nil {
            d.seatingCapacity = extractField(from: norm, keys: [
                "SEATING CAPACITY", "NO. OF SEATS", "SEATING"
            ])
        }
        
        
        // ── DATES ─────────────────────────────────────────────────────────────
        let allDates = allMatches(#"\d{2}[/\-\.]\d{2}[/\-\.]\d{4}"#, in: full)
        
        d.regDate = extractField(from: norm, keys: [
            "REGISTRATION DATE", "REG DATE", "DATE OF REGISTRATION", "REG. DATE"
        ]) ?? (allDates.count >= 1 ? allDates[0] : nil)
        
        d.validity = extractField(from: norm, keys: [
            "VALID UP TO", "VALID UPTO", "REGISTRATION VALID", "VALIDITY", "VALID TILL"
        ]) ?? (allDates.count >= 2 ? allDates[1] : nil)
        
        
        return d
    }
    
    // MARK: - Core Field Extractor
    //
    // Pattern A: "Engine No.:  XYT1234567"        → same line, after colon
    // Pattern B: "Chassis No.  ABCD987654321"     → same line, no colon (strips keyword)
    // Pattern C: "Engine No.\n  XYT1234567"       → next line
    
    func extractField(
        from lines: [String],
        keys: [String],
        validate: ((String) -> Bool)? = nil
    ) -> String? {
        
        for (i, line) in lines.enumerated() {
            guard let matchedKey = keys.first(where: { line.contains($0) }) else { continue }
            
            // Strategy A + B — strip the keyword, everything left is the value
            var remainder = line
            if let keyRange = remainder.range(of: matchedKey) {
                remainder = String(remainder[keyRange.upperBound...])
            }
            // Strip leading punctuation / whitespace
            remainder = remainder
                .trimmingCharacters(in: CharacterSet(charactersIn: ".:- "))
                .trimmingCharacters(in: .whitespaces)
            
            // If there are multiple key-value pairs on the line, take only the
            // first value — stop when we see 2+ spaces followed by a new label-ish word
            if let stopRange = remainder.range(of: #"\s{2,}[A-Z][A-Z\s\.]+:"#,
                                               options: .regularExpression) {
                remainder = String(remainder[..<stopRange.lowerBound])
                    .trimmingCharacters(in: .whitespaces)
            }
            
            if !remainder.isEmpty, validate?(remainder) ?? true {
                return remainder
            }
            
            // Strategy C — check the next non-empty line
            for j in (i + 1)..<min(i + 4, lines.count) {
                let next = lines[j].trimmingCharacters(in: .whitespaces)
                guard !next.isEmpty else { continue }
                if isLabelLine(next) { break }
                if validate?(next) ?? true { return next }
            }
        }
        return nil
    }
    
    // MARK: - Multi-line Extractor
    
    func extractMultiLine(from lines: [String], keys: [String], maxLines: Int) -> String? {
        for (i, line) in lines.enumerated() {
            guard keys.contains(where: { line.contains($0) }) else { continue }
            
            var parts: [String] = []
            
            if line.contains(":"), let colon = line.firstIndex(of: ":") {
                let after = String(line[line.index(after: colon)...])
                    .trimmingCharacters(in: .whitespaces)
                if !after.isEmpty { parts.append(after) }
            }
            
            var j = i + 1
            while j < lines.count, parts.count < maxLines {
                let next = lines[j].trimmingCharacters(in: .whitespaces)
                if next.isEmpty || isLabelLine(next) { break }
                parts.append(next)
                j += 1
            }
            
            if !parts.isEmpty { return parts.joined(separator: ", ") }
        }
        return nil
    }
    
    // MARK: - Inline Multi-KV Line Parser
    //
    // "Model: SWIFT DX    Mfg. Year: 2020    Seating Capacity: 5"
    // Pass key = "MODEL" → "SWIFT DX"
    // Pass key = "MFG. YEAR" → "2020"
    // Pass key = "SEATING CAPACITY" → "5"
    
    func inlineValue(from line: String, key: String) -> String? {
        guard line.contains(key) else { return nil }
        let escaped = NSRegularExpression.escapedPattern(for: key)
        // Capture from after KEY+punctuation until end-of-line or 2+ spaces before next word+colon
        let pattern = escaped + #"[\.:\s]*([A-Z0-9][A-Z0-9\s\(\)/\-]*)(?:\s{2,}[A-Z]|$)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              match.numberOfRanges > 1,
              let r = Range(match.range(at: 1), in: line) else { return nil }
        return String(line[r]).trimmingCharacters(in: .whitespaces)
    }
    
    
    // MARK: - Helpers
    
    func isLabelLine(_ line: String) -> Bool {
        let tokens = [
            "OWNER", "CHASSIS", "ENGINE", "MODEL", "FUEL", "COLOUR", "COLOR",
            "CLASS", "BODY TYPE", "SEATING", "WEIGHT", "FITNESS", "TAX",
            "INSURANCE", "PUC", "VALID", "REGISTRATION", "VEHICLE", "ADDRESS",
            "FATHER", "FINANCIER", "MAKER", "MFG", "CUBIC", "CAPACITY"
        ]
        return tokens.contains(where: { line.contains($0) })
    }
    
    func firstInText(_ text: String, candidates: [String]) -> String? {
        candidates.first { text.contains($0) }
    }
    
    func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else { return nil }
        return String(text[range])
    }
    
    func allMatches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }
    
    
    // MARK: - Result Row
    
    struct ResultRow: View {
        var label: String
        var value: String?
        var icon: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value ?? "—")
                        .font(.subheadline)
                        .fontWeight(value != nil ? .medium : .regular)
                        .foregroundColor(value != nil ? .primary : .secondary)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

