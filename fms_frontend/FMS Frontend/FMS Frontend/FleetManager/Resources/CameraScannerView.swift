import SwiftUI
import Vision
import PhotosUI
import CoreImage

struct CameraScannerView: View {
    @Binding var isPresented: Bool
    var didFinishScanning: (String, String, String, String) -> Void
    
    @State private var frontItem: PhotosPickerItem?
    @State private var backItem: PhotosPickerItem?
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    imageSlot(image: frontImage, label: "Front", pickerItem: $frontItem)
                    imageSlot(image: backImage, label: "Back", pickerItem: $backItem)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Button(action: runOCR) {
                    Group {
                        if isProcessing {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white)
                                Text("Scanning...")
                            }
                        } else {
                            Label("Scan Both Sides", systemImage: "barcode.viewfinder")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled((frontImage == nil && backImage == nil) || isProcessing)
                .padding()
                
                Spacer()
            }
            .navigationTitle("DL Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onChange(of: frontItem) { _, _ in loadImage(from: frontItem, isFront: true) }
            .onChange(of: backItem) { _, _ in loadImage(from: backItem, isFront: false) }
        }
    }
    
    @ViewBuilder
    private func imageSlot(image: UIImage?, label: String, pickerItem: Binding<PhotosPickerItem?>) -> some View {
        PhotosPicker(selection: pickerItem, matching: .images) {
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
                        Image(systemName: label == "Front" ? "person.crop.rectangle.fill" : "rectangle.on.rectangle")
                        Text(label)
                    }
                    .foregroundColor(.gray)
                }
            }
            .frame(height: 160)
        }
    }
    
    func loadImage(from item: PhotosPickerItem?, isFront: Bool) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    if isFront { frontImage = uiImage } else { backImage = uiImage }
                }
            }
        }
    }
    
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
                isPresented = false
                self.didFinishScanning(
                    result.name ?? "",
                    result.dlNumber ?? "",
                    result.expiryDate ?? "",
                    result.vehicleClasses ?? ""
                )
            }
        }
    }
    
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
    
    func parseDL(lines: [String]) -> DLData {
        var d = DLData()
        
        let norm = lines.map {
            $0.uppercased()
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }
        
        let full = norm.joined(separator: "\n")
        
        if let raw = firstMatch(#"[A-Z]{2}[\s\-]?\d{2}[\s\-]?\d{4}[\s\-]?\d{7}"#, in: full) {
            d.dlNumber = raw.replacingOccurrences(of: #"[\s\-]"#, with: "", options: .regularExpression)
        }
        
        d.name = extractField(from: norm, keys: [
            "DL HOLDER NAME", "NAME OF DL HOLDER", "NAME", "HOLDER NAME"
        ]) { val in
            let junk = ["GOVERNMENT", "TRANSPORT", "DEPARTMENT",
                        "INDIA", "MINISTRY", "DRIVING", "LICENCE"]
            return val.count >= 3 && !junk.contains(where: { val.contains($0) })
        }
        
        d.dob = extractField(from: norm, keys: [
            "DATE OF BIRTH", "DOB", "BIRTH DATE"
        ]) ?? allMatches(#"\d{2}[/\-\.]\d{2}[/\-\.]\d{4}"#, in: full).first
        
        let classKeywords = ["MCWG", "LMV", "HMV", "LMVTR", "MGV", "HPV", "HGMV", "HPMV", "HTV", "LPV", "MPV", "TR", "TRANS"]
        var found: [String] = []
        let fullText = norm.joined(separator: " ")
        
        for kw in classKeywords {
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: kw) + "\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: fullText, range: NSRange(fullText.startIndex..., in: fullText))
                if !matches.isEmpty && !found.contains(kw) {
                    found.append(kw)
                }
            }
        }
        if !found.isEmpty {
            d.vehicleClasses = found.joined(separator: ", ")
        }
        
        let allDates = allMatches(#"\d{2}[/\-\.]\d{2}[/\-\.]\d{4}"#, in: full)
        
        d.validFromNT = extractField(from: norm, keys: [
            "VALID FROM (NT)", "NT VALID FROM", "VALID FROM"
        ]) ?? (allDates.count >= 2 ? allDates[1] : nil)
        
        d.expiryDate = getLatestDate(from: allDates)
        return d
    }
    
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
}

struct DLData {
    var dlNumber: String?
    var name: String?
    var dob: String?
    var vehicleClasses: String?
    var validFromNT: String?
    var expiryDate: String?
}

struct RCScannerView: View {
    @Binding var isPresented: Bool
    var didFinishScanning: (String, String, String, String) -> Void
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Group {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 220)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        VStack {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("Pick an RC image to scan")
                                .foregroundColor(.gray)
                        }
                        .frame(height: 220)
                    }
                }
                .padding(.top)
                
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
                
                Spacer()
            }
            .navigationTitle("RC Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in loadImage(from: newItem) }
        }
    }
    
    func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = uiImage
                }
            }
        }
    }
    
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
            
            let sorted = observations.sorted {
                let dy = $1.boundingBox.minY - $0.boundingBox.minY
                return abs(dy) > 0.015 ? dy > 0 : $0.boundingBox.minX < $1.boundingBox.minX
            }
            
            let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
            let result = parseRC(lines: lines)
            
            await MainActor.run {
                isPresented = false
                self.didFinishScanning(
                    result.owner ?? "",
                    result.regNumber ?? "",
                    result.model ?? "",
                    result.chassis ?? result.engineNumber ?? ""
                )
            }
        }
    }
    
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
    
    func parseRC(lines: [String]) -> RCDataParsed {
        var d = RCDataParsed()
        
        let norm: [String] = lines.map {
            $0.uppercased()
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }
        
        let full = norm.joined(separator: "\n")
        
        if let raw = firstMatch(#"[A-Z]{2}[\s\-]?\d{2}[\s\-]?[A-Z]{1,3}[\s\-]?\d{1,4}"#, in: full) {
            d.regNumber = raw.replacingOccurrences(of: #"[\s\-]"#, with: "", options: .regularExpression)
        }
        
        d.chassis = extractField(from: norm, keys: [
            "CHASSIS NO", "CHASSIS NUMBER", "CHASIS NO", "VIN NO"
        ]) { val in
            val.replacingOccurrences(of: " ", with: "")
                .range(of: #"^[A-Z0-9]{8,20}$"#, options: .regularExpression) != nil
        }
        
        d.engineNumber = extractField(from: norm, keys: [
            "ENGINE NO", "ENGINE NUMBER", "ENG NO"
        ]) { val in
            val.replacingOccurrences(of: " ", with: "")
                .range(of: #"^[A-Z0-9]{6,20}$"#, options: .regularExpression) != nil
        }
        
        d.owner = extractField(from: norm, keys: [
            "OWNER'S NAME", "OWNER S NAME", "NAME OF OWNER",
            "OWNER NAME", "RC OWNER", "REGISTERED OWNER"
        ]) { val in
            let junk = ["GOVERNMENT", "TRANSPORT", "DEPARTMENT", "INDIA", "MINISTRY", "CERTIFICATE"]
            return val.count >= 3 && !junk.contains(where: { val.contains($0) })
        }
        
        d.vehicleClass = extractField(from: norm, keys: [
            "VEHICLE CLASS", "CLASS OF VEHICLE", "VEH CLASS"
        ])
        
        d.fuel = extractField(from: norm, keys: [
            "FUEL TYPE", "TYPE OF FUEL", "FUEL USED", "FUEL"
        ]) ?? firstInText(full, candidates: ["PETROL", "DIESEL", "CNG", "LPG", "ELECTRIC", "EV", "HYBRID"])
        
        if let modelLine = norm.first(where: { $0.contains("MODEL") }) {
            d.model = inlineValue(from: modelLine, key: "MODEL")
            d.mfgYear = inlineValue(from: modelLine, key: "MFG. YEAR")
                ?? inlineValue(from: modelLine, key: "MFG YEAR")
                ?? inlineValue(from: modelLine, key: "MFG")
            d.seatingCapacity = inlineValue(from: modelLine, key: "SEATING CAPACITY")
                ?? inlineValue(from: modelLine, key: "SEATING")
        }
        
        if d.mfgYear == nil {
            d.mfgYear = extractField(from: norm, keys: [
                "MONTH & YEAR OF MFG", "MFG. YEAR", "MFG YEAR",
                "YEAR OF MFG", "MFG DATE", "MANUFACTURING YEAR"
            ]) ?? allMatches(#"\b(19|20)\d{2}\b"#, in: full).last
        }
        
        if d.seatingCapacity == nil {
            d.seatingCapacity = extractField(from: norm, keys: [
                "SEATING CAPACITY", "NO. OF SEATS", "SEATING"
            ])
        }
        
        let allDates = allMatches(#"\d{2}[/\-\.]\d{2}[/\-\.]\d{4}"#, in: full)
        
        d.regDate = extractField(from: norm, keys: [
            "REGISTRATION DATE", "REG DATE", "DATE OF REGISTRATION", "REG. DATE"
        ]) ?? (allDates.count >= 1 ? allDates[0] : nil)
        
        d.validity = extractField(from: norm, keys: [
            "VALID UP TO", "VALID UPTO", "REGISTRATION VALID", "VALIDITY", "VALID TILL"
        ]) ?? (allDates.count >= 2 ? allDates[1] : nil)
        
        return d
    }
    
    func extractField(
        from lines: [String],
        keys: [String],
        validate: ((String) -> Bool)? = nil
    ) -> String? {
        for (i, line) in lines.enumerated() {
            guard let matchedKey = keys.first(where: { line.contains($0) }) else { continue }
            
            var remainder = line
            if let keyRange = remainder.range(of: matchedKey) {
                remainder = String(remainder[keyRange.upperBound...])
            }
            remainder = remainder
                .trimmingCharacters(in: CharacterSet(charactersIn: ".:- "))
                .trimmingCharacters(in: .whitespaces)
            
            if let stopRange = remainder.range(of: #"\s{2,}[A-Z][A-Z\s\.]+:"#,
                                               options: .regularExpression) {
                remainder = String(remainder[..<stopRange.lowerBound])
                    .trimmingCharacters(in: .whitespaces)
            }
            
            if !remainder.isEmpty, validate?(remainder) ?? true {
                return remainder
            }
            
            for j in (i + 1)..<min(i + 4, lines.count) {
                let next = lines[j].trimmingCharacters(in: .whitespaces)
                guard !next.isEmpty else { continue }
                if isLabelLine(next) { break }
                if validate?(next) ?? true { return next }
            }
        }
        return nil
    }
    
    func inlineValue(from line: String, key: String) -> String? {
        guard line.contains(key) else { return nil }
        let escaped = NSRegularExpression.escapedPattern(for: key)
        let pattern = escaped + #"[\.:\s]*([A-Z0-9][A-Z0-9\s\(\)/\-]*)(?:\s{2,}[A-Z]|$)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              match.numberOfRanges > 1,
              let r = Range(match.range(at: 1), in: line) else { return nil }
        return String(line[r]).trimmingCharacters(in: .whitespaces)
    }
    
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
}

struct RCDataParsed {
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
