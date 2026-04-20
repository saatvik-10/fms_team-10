//
//  DLData.swift
//  FMS Frontend
//
//  Created by Harsh Choudhary on 20/04/26.
//


import SwiftUI
import Vision
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Data Model

//struct DLData {
//    var dlNumber: String?
//    var name: String?
//    var dob: String?
//    var vehicleClasses: String?
//    var validFromNT: String?
//    var expiryDate: String?   // ✅ NEW
//}

// MARK: - ContentView

struct AddDL: View {
    @State private var frontItem: PhotosPickerItem?
    @State private var backItem: PhotosPickerItem?
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var parsedData = DLData()
    @State private var rawLines: [String] = []
    @State private var isProcessing = false

    var canScan: Bool { frontImage != nil || backImage != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                HStack(spacing: 12) {
                    DLImageSlot(image: frontImage, label: "Front",
                                systemImage: "person.crop.rectangle.fill",
                                pickerItem: $frontItem)

                    DLImageSlot(image: backImage, label: "Back",
                                systemImage: "rectangle.on.rectangle",
                                pickerItem: $backItem)
                }
                .padding(.horizontal)
                .padding(.top)

                Button(action: runOCR) {
                    Group {
                        if isProcessing {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white)
                                Text("Scanning…")
                            }
                        } else {
                            Label("Scan Both Sides", systemImage: "barcode.viewfinder")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canScan || isProcessing)
                .padding()

                List {
                    Section("Identity") {
                        DLResultRow(label: "DL Number", value: parsedData.dlNumber, icon: "number.circle.fill")
                        DLResultRow(label: "Name", value: parsedData.name, icon: "person.fill")
                        DLResultRow(label: "Date of Birth", value: parsedData.dob, icon: "calendar")
                    }

                    Section("Licence Details") {
                        DLResultRow(label: "Vehicle Classes", value: parsedData.vehicleClasses, icon: "car.2.fill")
                        DLResultRow(label: "NT Valid From", value: parsedData.validFromNT, icon: "calendar.badge.checkmark")
                        DLResultRow(label: "Expiry Date", value: parsedData.expiryDate, icon: "calendar.badge.exclamationmark") // ✅ NEW
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
            .navigationTitle("DL Scanner")
            .onChange(of: frontItem) { _, _ in loadImage(from: frontItem, isFront: true) }
            .onChange(of: backItem)  { _, _ in loadImage(from: backItem,  isFront: false) }
        }
    }

    // MARK: - Load Image

    func loadImage(from item: PhotosPickerItem?, isFront: Bool) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    if isFront { frontImage = uiImage } else { backImage = uiImage }
                    parsedData = DLData()
                    rawLines = []
                }
            }
        }
    }
    
    

    // MARK: - OCR

    func runOCR() {
        isProcessing = true
        Task.detached(priority: .userInitiated) {

            var allLines: [String] = []

            let sides: [UIImage?] = [frontImage, backImage]

            for image in sides {
                guard let image else { continue }
                let processed = preprocessImage(image) ?? image
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

            let result = parseDL(lines: allLines)

            await MainActor.run {
                rawLines = allLines
                parsedData = result
                isProcessing = false
            }
        }
    }

    // MARK: - Image Preprocess

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

    // MARK: - Parser

    func parseDL(lines: [String]) -> DLData {
        var d = DLData()

        let norm: [String] = lines.map {
            $0.uppercased()
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }

        let full = norm.joined(separator: "\n")

        // DL Number
        if let raw = firstMatch(#"[A-Z]{2}[\s\-]?\d{2}[\s\-]?\d{4}[\s\-]?\d{7}"#, in: full) {
            d.dlNumber = raw.replacingOccurrences(of: #"[\s\-]"#, with: "",
                                                   options: .regularExpression)
        }

        // Name
        d.name = extractField(from: norm, keys: [
            "DL HOLDER NAME", "NAME OF DL HOLDER", "NAME", "HOLDER NAME"
        ]) { val in
            let junk = ["GOVERNMENT", "TRANSPORT", "DEPARTMENT",
                        "INDIA", "MINISTRY", "DRIVING", "LICENCE"]
            return val.count >= 3 && !junk.contains(where: { val.contains($0) })
        }

        // DOB
        d.dob = extractField(from: norm, keys: [
            "DATE OF BIRTH", "DOB", "BIRTH DATE"
        ]) ?? allMatches(#"\d{2}[/\-\.]\d{2}[/\-\.]\d{4}"#, in: full).first

        // Vehicle Classes
        let classKeywords = ["MCWG", "LMV", "HMV", "LMVTR"]

        var found: [String] = []
        for line in norm {
            for kw in classKeywords where line.contains(kw) {
                if !found.contains(kw) { found.append(kw) }
            }
        }
        if !found.isEmpty {
            d.vehicleClasses = found.joined(separator: ", ")
        }

        // Dates
        let allDates = allMatches(#"\d{2}[/\-\.]\d{2}[/\-\.]\d{4}"#, in: full)

        // Valid From NT
        d.validFromNT = extractField(from: norm, keys: [
            "VALID FROM (NT)", "NT VALID FROM", "VALID FROM"
        ]) ?? (allDates.count >= 2 ? allDates[1] : nil)

        // ✅ EXPIRY DATE (POSITION BASED)
        // ✅ EXPIRY DATE (FINAL FIX)
        d.expiryDate = getLatestDate(from: allDates)
        return d
    }

    // MARK: - Extract Field

    func extractField(
        from lines: [String],
        keys: [String],
        validate: ((String) -> Bool)? = nil
    ) -> String? {
        for (i, line) in lines.enumerated() {
            guard let key = keys.first(where: { line.contains($0) }) else { continue }

            var remainder = line
            if let range = remainder.range(of: key) {
                remainder = String(remainder[range.upperBound...])
            }

            remainder = remainder.trimmingCharacters(in: CharacterSet(charactersIn: ".:- "))
            remainder = remainder.trimmingCharacters(in: .whitespaces)

            if !remainder.isEmpty, validate?(remainder) ?? true {
                return remainder
            }

            for j in (i+1)..<min(i+3, lines.count) {
                let next = lines[j].trimmingCharacters(in: .whitespaces)
                if next.count > 2 {
                    return next
                }
            }
        }
        return nil
    }

    func getLatestDate(from dates: [String]) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"

        let parsed = dates.compactMap { formatter.date(from: $0) }

        guard let maxDate = parsed.max() else { return nil }

        return formatter.string(from: maxDate)
    }
    
    
    func isLabelLine(_ line: String) -> Bool {
        let tokens = [
            "VALID", "VALIDITY",
            "CLASS", "VEHICLE",
            "NAME", "DOB",
            "BIRTH", "AUTHORITY",
            "RTO", "LICENCE", "LICENSE"
        ]
        return tokens.contains(where: { line.contains($0) })
    }
    // MARK: - Regex

    func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text,
                                           range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else { return nil }
        return String(text[range])
    }

    func allMatches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }
    
    func isValidDate(_ str: String?) -> Bool {
        guard let str = str else { return false }
        return str.range(of: #"^\d{2}[-/\.]\d{2}[-/\.]\d{4}$"#,
                         options: .regularExpression) != nil
    }
    
}

// MARK: - Image Slot

struct DLImageSlot: View {
    let image: UIImage?
    let label: String
    let systemImage: String
    @Binding var pickerItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack {
                        Image(systemName: systemImage)
                        Text(label)
                    }
                }
            }
            .frame(height: 160)
        }
    }
}

// MARK: - Result Row

struct DLResultRow: View {
    var label: String
    var value: String?
    var icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(label)
            Spacer()
            Text(value ?? "—")
        }
    }
}
