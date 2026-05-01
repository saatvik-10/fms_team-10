//
//  AddRCViewModel.swift
//  Created by Anshul Kumaria
//

import SwiftUI
import Vision
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

class AddRCViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var parsedData = RCData()
    @Published var rawLines: [String] = []
    @Published var isProcessing = false

    @MainActor
    func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            selectedImage = uiImage
            parsedData = RCData()
            rawLines = []
        }
    }

    func runOCR() {
        guard let image = selectedImage else { return }
        isProcessing = true
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let processed = self.preprocessImage(image) ?? image
            guard let cgImage = processed.cgImage else {
                await MainActor.run { self.isProcessing = false }
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
            let sorted = observations.sorted {
                let dy = $1.boundingBox.minY - $0.boundingBox.minY
                return abs(dy) > 0.015 ? dy > 0 : $0.boundingBox.minX < $1.boundingBox.minX
            }
            
            let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
            let result = self.parseRC(lines: lines)
            
            await MainActor.run {
                self.rawLines = lines
                self.parsedData = result
                self.isProcessing = false
                print("[SUCCESS] [SUCCESS] RC OCR Processing Complete")
            }
        }
    }

    private func preprocessImage(_ image: UIImage) -> UIImage? {
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

    private func parseRC(lines: [String]) -> RCData {
        var d = RCData()
        let norm: [String] = lines.map {
            $0.uppercased()
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }
        
        let full = norm.joined(separator: "\n")
        
        if let raw = firstMatch(#"[A-Z]{2}[\s\-]?\d{2}[\s\-]?[A-Z]{1,3}[\s\-]?\d{1,4}"#, in: full) {
            d.regNumber = raw.replacingOccurrences(of: #"[\s\-]"#, with: "", options: .regularExpression)
        }
        
        d.chassis = extractField(from: norm, keys: ["CHASSIS NO", "CHASSIS NUMBER", "CHASIS NO", "VIN NO"]) { val in
            val.replacingOccurrences(of: " ", with: "").range(of: #"^[A-Z0-9]{8,20}$"#, options: .regularExpression) != nil
        }
        
        d.engineNumber = extractField(from: norm, keys: ["ENGINE NO", "ENGINE NUMBER", "ENG NO"]) { val in
            val.replacingOccurrences(of: " ", with: "").range(of: #"^[A-Z0-9]{6,20}$"#, options: .regularExpression) != nil
        }
        
        d.owner = extractField(from: norm, keys: ["OWNER'S NAME", "OWNER S NAME", "NAME OF OWNER", "OWNER NAME", "RC OWNER", "REGISTERED OWNER"]) { val in
            let junk = ["GOVERNMENT", "TRANSPORT", "DEPARTMENT", "INDIA", "MINISTRY", "CERTIFICATE"]
            return val.count >= 3 && !junk.contains(where: { val.contains($0) })
        }
        
        d.address = extractMultiLine(from: norm, keys: ["ADDRESS", "PRESENT ADDRESS", "PERMANENT ADDRESS"], maxLines: 3)
        d.vehicleClass = extractField(from: norm, keys: ["VEHICLE CLASS", "CLASS OF VEHICLE", "VEH CLASS"])
        d.fuel = extractField(from: norm, keys: ["FUEL TYPE", "TYPE OF FUEL", "FUEL USED", "FUEL"]) ?? candidatesInText(full, candidates: ["PETROL", "DIESEL", "CNG", "LPG", "ELECTRIC", "EV", "HYBRID"])
        
        if let modelLine = norm.first(where: { $0.contains("MODEL") }) {
            d.model = inlineValue(from: modelLine, key: "MODEL")
            d.mfgYear = inlineValue(from: modelLine, key: "MFG. YEAR") ?? inlineValue(from: modelLine, key: "MFG YEAR") ?? inlineValue(from: modelLine, key: "MFG")
            d.seatingCapacity = inlineValue(from: modelLine, key: "SEATING CAPACITY") ?? inlineValue(from: modelLine, key: "SEATING")
        }
        
        if d.mfgYear == nil {
            d.mfgYear = extractField(from: norm, keys: ["MONTH & YEAR OF MFG", "MFG. YEAR", "MFG YEAR", "YEAR OF MFG", "MFG DATE", "MANUFACTURING YEAR"]) ?? allMatches(#"\b(19|20)\d{2}\b"#, in: full).last
        }
        
        if d.seatingCapacity == nil {
            d.seatingCapacity = extractField(from: norm, keys: ["SEATING CAPACITY", "NO. OF SEATS", "SEATING"])
        }
        
        let allDates = allMatches(#"\d{2}[/\-\.]\d{2}[/\-\.]\d{4}"#, in: full)
        d.regDate = extractField(from: norm, keys: ["REGISTRATION DATE", "REG DATE", "DATE OF REGISTRATION", "REG. DATE"]) ?? (allDates.count >= 1 ? allDates[0] : nil)
        d.validity = extractField(from: norm, keys: ["VALID UP TO", "VALID UPTO", "REGISTRATION VALID", "VALIDITY", "VALID TILL"]) ?? (allDates.count >= 2 ? allDates[1] : nil)
        
        return d
    }

    private func extractField(from lines: [String], keys: [String], validate: ((String) -> Bool)? = nil) -> String? {
        for (i, line) in lines.enumerated() {
            guard let matchedKey = keys.first(where: { line.contains($0) }) else { continue }
            var remainder = line
            if let keyRange = remainder.range(of: matchedKey) {
                remainder = String(remainder[keyRange.upperBound...])
            }
            remainder = remainder.trimmingCharacters(in: CharacterSet(charactersIn: ".:- ")).trimmingCharacters(in: .whitespaces)
            if let stopRange = remainder.range(of: #"\s{2,}[A-Z][A-Z\s\.]+:"#, options: .regularExpression) {
                remainder = String(remainder[..<stopRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
            if !remainder.isEmpty, validate?(remainder) ?? true { return remainder }
            for j in (i + 1)..<min(i + 4, lines.count) {
                let next = lines[j].trimmingCharacters(in: .whitespaces)
                guard !next.isEmpty else { continue }
                if isLabelLine(next) { break }
                if validate?(next) ?? true { return next }
            }
        }
        return nil
    }

    private func extractMultiLine(from lines: [String], keys: [String], maxLines: Int) -> String? {
        for (i, line) in lines.enumerated() {
            guard keys.contains(where: { line.contains($0) }) else { continue }
            var parts: [String] = []
            if line.contains(":"), let colon = line.firstIndex(of: ":") {
                let after = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
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

    private func inlineValue(from line: String, key: String) -> String? {
        guard line.contains(key) else { return nil }
        let escaped = NSRegularExpression.escapedPattern(for: key)
        let pattern = escaped + #"[\.:\s]*([A-Z0-9][A-Z0-9\s\(\)/\-]*)(?:\s{2,}[A-Z]|$)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              match.numberOfRanges > 1,
              let r = Range(match.range(at: 1), in: line) else { return nil }
        return String(line[r]).trimmingCharacters(in: .whitespaces)
    }

    private func isLabelLine(_ line: String) -> Bool {
        let tokens = ["OWNER", "CHASSIS", "ENGINE", "MODEL", "FUEL", "COLOUR", "COLOR", "CLASS", "BODY TYPE", "SEATING", "WEIGHT", "FITNESS", "TAX", "INSURANCE", "PUC", "VALID", "REGISTRATION", "VEHICLE", "ADDRESS", "FATHER", "FINANCIER", "MAKER", "MFG", "CUBIC", "CAPACITY"]
        return tokens.contains(where: { line.contains($0) })
    }

    private func candidatesInText(_ text: String, candidates: [String]) -> String? {
        candidates.first { text.contains($0) }
    }

    private func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else { return nil }
        return String(text[range])
    }

    private func allMatches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }
}
