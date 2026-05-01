//
//  AddDLViewModel.swift
//  Created by Kunal Khude
//

import SwiftUI
import Vision
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

class AddDLViewModel: ObservableObject {
    @Published var frontItem: PhotosPickerItem?
    @Published var backItem: PhotosPickerItem?
    @Published var frontImage: UIImage?
    @Published var backImage: UIImage?
    @Published var parsedData = DLData()
    @Published var rawLines: [String] = []
    @Published var isProcessing = false

    var canScan: Bool { frontImage != nil || backImage != nil }

    @MainActor
    func loadImage(from item: PhotosPickerItem?, isFront: Bool) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            if isFront { frontImage = uiImage } else { backImage = uiImage }
            parsedData = DLData()
            rawLines = []
        }
    }

    func runOCR() {
        isProcessing = true
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            var allLines: [String] = []
            let sides: [UIImage?] = [await MainActor.run { self.frontImage }, await MainActor.run { self.backImage }]

            for image in sides {
                guard let image else { continue }
                let processed = self.preprocessImage(image) ?? image
                guard let cgImage = processed.cgImage else { continue }

                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["en-IN", "en-US"]
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
                try? handler.perform([request])

                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let sorted = observations.sorted {
                    let dy = $1.boundingBox.minY - $0.boundingBox.minY
                    return abs(dy) > 0.015 ? dy > 0 : $0.boundingBox.minX < $1.boundingBox.minX
                }

                allLines += sorted.compactMap { $0.topCandidates(1).first?.string }
            }

            let result = self.parseDL(lines: allLines)

            await MainActor.run {
                self.rawLines = allLines
                self.parsedData = result
                self.isProcessing = false
                print("[SUCCESS] [SUCCESS] DL OCR Processing Complete")
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

    private func parseDL(lines: [String]) -> DLData {
        var d = DLData()

        let norm: [String] = lines.map {
            $0.uppercased()
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }

        let full = norm.joined(separator: "\n")

        if let raw = firstMatch(#"[A-Z]{2}[\s\-]?\d{2}[\s\-]?\d{4}[\s\-]?\d{7}"#, in: full) {
            d.dlNumber = raw.replacingOccurrences(of: #"[\s\-]"#, with: "", options: .regularExpression)
        }

        d.name = extractField(from: norm, keys: ["DL HOLDER NAME", "NAME OF DL HOLDER", "NAME", "HOLDER NAME"]) { val in
            let junk = ["GOVERNMENT", "TRANSPORT", "DEPARTMENT", "INDIA", "MINISTRY", "DRIVING", "LICENCE"]
            return val.count >= 3 && !junk.contains(where: { val.contains($0) })
        }

        d.dob = extractField(from: norm, keys: ["DATE OF BIRTH", "DOB", "BIRTH DATE"]) ?? allMatches(#"\d{2}[/\-\.]\d{2}[/\-\.]\d{4}"#, in: full).first

        let classKeywords = ["MCWG", "LMV", "HMV", "LMVTR"]
        var found: [String] = []
        for line in norm {
            for kw in classKeywords where line.contains(kw) {
                if !found.contains(kw) { found.append(kw) }
            }
        }
        if !found.isEmpty { d.vehicleClasses = found.joined(separator: ", ") }

        let allDates = allMatches(#"\d{2}[/\-\.]\d{2}[/\-\.]\d{4}"#, in: full)
        d.validFromNT = extractField(from: norm, keys: ["VALID FROM (NT)", "NT VALID FROM", "VALID FROM"]) ?? (allDates.count >= 2 ? allDates[1] : nil)
        d.expiryDate = getLatestDate(from: allDates)

        return d
    }

    private func extractField(from lines: [String], keys: [String], validate: ((String) -> Bool)? = nil) -> String? {
        for (i, line) in lines.enumerated() {
            guard let key = keys.first(where: { line.contains($0) }) else { continue }
            var remainder = line
            if let range = remainder.range(of: key) {
                remainder = String(remainder[range.upperBound...])
            }
            remainder = remainder.trimmingCharacters(in: CharacterSet(charactersIn: ".:- ")).trimmingCharacters(in: .whitespaces)
            if !remainder.isEmpty, validate?(remainder) ?? true { return remainder }
            for j in (i+1)..<min(i+3, lines.count) {
                let next = lines[j].trimmingCharacters(in: .whitespaces)
                if next.count > 2 { return next }
            }
        }
        return nil
    }

    private func getLatestDate(from dates: [String]) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let parsed = dates.compactMap { formatter.date(from: $0) }
        guard let maxDate = parsed.max() else { return nil }
        return formatter.string(from: maxDate)
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
