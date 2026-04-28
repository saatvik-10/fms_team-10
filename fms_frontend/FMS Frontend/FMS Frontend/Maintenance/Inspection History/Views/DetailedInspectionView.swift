//
//  DetailedInspectionView.swift
//  FMS Frontend
//

import SwiftUI
import PDFKit


// MARK: - Main View
struct DetailedInspectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    @State var inspection: TripInspection
    @State private var showingPDFPreview = false
    @State private var reportURL: URL?
    @State private var isGenerating = false

    @State private var showingDoneAlert = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingProofSource = false
    @State private var newNoteText: String = ""
    @State private var showingPartPicker = false
    @State private var partSearchText = ""
    @State private var recentlyUpdatedPartId: String?
    @State private var pendingSelectedPartIds: Set<String> = []

    private var taskPoints: [String] {
        inspection.taskDetails.components(separatedBy: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { "\($0)." }
    }

    private var reportTitle: String {
        let initials = inspection.unitName.components(separatedBy: " ")
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        let dateStr = formatter.string(from: Date())
        
        return "\(initials) - \(dateStr)"
    }

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
                            // Text("VIN: \(inspection.unitVIN)")
                            //     .font(.caption)
                            //     .foregroundColor(.secondary)
                            
                            HStack {
                                Text(inspection.type.rawValue)
                                    .font(.caption.bold())
                                    .foregroundColor(AppColors.primary)
                                
                                Text("•")
                                    .foregroundColor(.secondary)
                                
                                Text(inspection.status.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(inspection.status == .completed ? .green : .blue)
                            }
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))

                // ── Parity with WorkOrder Details ──────────────────────────
                
                // 1. Audit Scope Card
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "AUDIT SCOPE", icon: "doc.text.fill")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(inspection.title)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                }
                
                // 2. Driver Notes Card
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "DRIVER NOTES", icon: "person.wave.2.fill")
                    driverNotesContent
                }
                
                // 3. Driver Media Card
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "MEDIA", icon: "photo.on.rectangle.angled")
                    driverMediaContent
                }

                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(title: "AUDIT RESULTS", icon: "checklist")
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach($inspection.items, id: \.id) { $item in
                            InspectionListItem(item: $item)
                                .padding()
                                .disabled(inspection.status == .completed)
                                .background(Color(.secondarySystemGroupedBackground))

                            if item.id != inspection.items.last?.id {
                                Divider().padding(.leading, 16)
                            }
                        }
                        
                        if inspection.status != .completed {
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
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                }

                // 4. Technician Notes
                // VStack(alignment: .leading, spacing: 12) {
                //     SectionHeader(title: "AUDITOR NOTES", icon: "wrench.and.screwdriver.fill")
                //     technicianNotesContent
                // }
                
                // 5. Parts Consumed (Optional for Inspection but added for parity)
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "PARTS REPLACED", icon: "shippingbox.fill")
                    partsConsumedContent
                }
                
                // // 6. Media Gallery
                // VStack(alignment: .leading, spacing: 12) {
                //     SectionHeader(title: "EVIDENCE MEDIA", icon: "camera.fill")
                //     mediaGalleryContent
                // }

                Spacer(minLength: 120)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Inspection Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if inspection.status != .completed {
                    Button(action: { showingDoneAlert = true }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .confirmationDialog("Evidence Source", isPresented: $showingProofSource) {
            Button("Camera") { showingCamera = true }
            Button("Photo Library") { showingImagePicker = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoPicker(images: Binding(
                get: { [] },
                set: { images in
                    inspection.imagesData.append(contentsOf: images.compactMap { $0.jpegData(compressionQuality: 0.7) })
                    store.updateInspection(inspection)
                }
            ))
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(image: Binding(
                get: { nil },
                set: { if let img = $0 {
                    inspection.imagesData.append(img.jpegData(compressionQuality: 0.7)!)
                    store.updateInspection(inspection)
                } }
            ))
        }
        .sheet(isPresented: $showingPartPicker) {
            NavigationStack {
                List {
                    ForEach(filteredInventoryParts, id: \.id) { part in
                        Button {
                            if pendingSelectedPartIds.contains(part.partId) {
                                pendingSelectedPartIds.remove(part.partId)
                            } else {
                                pendingSelectedPartIds.insert(part.partId)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "shippingbox.fill")
                                    .foregroundColor(AppColors.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(part.partName)
                                        .foregroundColor(.primary)
                                    Text("\(part.partId) • In stock: \(part.stockQty)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if pendingSelectedPartIds.contains(part.partId) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Select Parts")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $partSearchText, prompt: "Search by part name or ID")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { showingPartPicker = false }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            for partId in pendingSelectedPartIds {
                                if !inspection.consumedParts.contains(where: { $0.inventoryPartId == partId }) {
                                    inspection.consumedParts.append(WorkOrderPartUsage(inventoryPartId: partId, quantity: 1))
                                }
                            }
                            store.updateInspection(inspection)
                            showingPartPicker = false
                        } label: {
                            Image(systemName: "checkmark").font(.system(size: 16, weight: .bold))
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingPDFPreview) {
            if let url = reportURL {
                PDFPreviewView(url: url, title: reportTitle)
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var driverNotesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let transcript = inspection.voiceTranscript, !transcript.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "waveform").foregroundColor(AppColors.primary)
                        Text("VOICE TRANSCRIPT").font(.caption.weight(.black)).foregroundColor(AppColors.primary)
                    }
                    Text("\"\(transcript)\"").font(.subheadline.italic()).foregroundColor(.secondary).lineSpacing(4)
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.5)).cornerRadius(12)
            } else {
                Text("No driver notes available.").font(.subheadline).foregroundColor(.secondary).padding(.vertical, 4)
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white).cornerRadius(16).shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var driverMediaContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if inspection.imageUrls.isEmpty && inspection.driverMediaImages.isEmpty {
                Text("No media uploaded.").font(.subheadline).foregroundColor(.secondary).padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<inspection.driverMediaImages.count, id: \.self) { index in
                            if let uiImage = UIImage(data: inspection.driverMediaImages[index]) {
                                Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill).frame(width: 100, height: 100).cornerRadius(12).clipped()
                            }
                        }
                        ForEach(inspection.imageUrls, id: \.self) { urlString in
                            if let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else if phase.error != nil {
                                        Color.red.overlay(Image(systemName: "photo").foregroundColor(.white))
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .frame(width: 100, height: 100).cornerRadius(12).clipped()
                            }
                        }
                    }
                }
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white).cornerRadius(16).shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var technicianNotesContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if inspection.taskDetails.isEmpty {
                Text("No auditor notes yet.").font(.body).foregroundColor(.secondary)
            } else {
                Text(inspection.taskDetails).font(.body).foregroundColor(.primary)
            }
            Divider().padding(.vertical, 4)
            HStack(alignment: .top, spacing: 10) {
                TextField("Add a new note...", text: $newNoteText, axis: .vertical).font(.body).textFieldStyle(.plain).lineLimit(1...5)
                Button(action: {
                    let trimmed = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        inspection.taskDetails = inspection.taskDetails.isEmpty ? trimmed : inspection.taskDetails + "\n" + trimmed
                        store.updateInspection(inspection)
                        newNoteText = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(newNoteText.isEmpty ? .secondary : AppColors.primary)
                }
                .disabled(newNoteText.isEmpty)
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white).cornerRadius(16).shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var partsConsumedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if inspection.consumedParts.isEmpty {
                Text("No parts replaced during audit.").font(.subheadline).foregroundColor(.secondary)
            } else {
                ForEach(inspection.consumedParts) { usage in
                    if let part = store.inventoryParts.first(where: { $0.partId == usage.inventoryPartId }) {
                        HStack {
                            Image(systemName: "shippingbox.fill").foregroundColor(AppColors.primary).frame(width: 32, height: 32).background(AppColors.primary.opacity(0.1)).cornerRadius(8)
                            VStack(alignment: .leading) {
                                Text(part.partName).font(.system(size: 14, weight: .bold))
                                Text(part.partId).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("x\(usage.quantity)").font(.system(size: 14, weight: .bold))
                        }
                    }
                }
            }
            Button {
                pendingSelectedPartIds = Set(inspection.consumedParts.map { $0.inventoryPartId })
                showingPartPicker = true
            } label: {
                HStack { Image(systemName: "plus"); Text("Link Part") }.font(.subheadline.weight(.semibold)).foregroundColor(AppColors.primary)
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white).cornerRadius(16).shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var mediaGalleryContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<inspection.imagesData.count, id: \.self) { index in
                    Image(uiImage: UIImage(data: inspection.imagesData[index]) ?? UIImage()).resizable().aspectRatio(contentMode: .fill).frame(width: 90, height: 90).cornerRadius(12).clipped()
                }
                ForEach(inspection.imageUrls, id: \.self) { urlString in
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else if phase.error != nil {
                                Color.red.overlay(Image(systemName: "photo").foregroundColor(.white))
                            } else {
                                ProgressView()
                            }
                        }
                        .frame(width: 90, height: 90).cornerRadius(12).clipped()
                    }
                }
                Button(action: { showingProofSource = true }) {
                    VStack(spacing: 4) { Image(systemName: "plus.circle.fill").font(.title3); Text("Capture").font(.caption2.weight(.bold)) }
                    .frame(width: 90, height: 90).background(Color(.systemGray6)).foregroundColor(AppColors.primary).cornerRadius(12)
                }
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white).cornerRadius(16).shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private var filteredInventoryParts: [InventoryPart] {
        let sorted = store.inventoryParts.sorted { $0.partName < $1.partName }
        guard !partSearchText.isEmpty else { return sorted }
        return sorted.filter { $0.partName.localizedCaseInsensitiveContains(partSearchText) || $0.partId.localizedCaseInsensitiveContains(partSearchText) }
    }

    private func submitAndGeneratePDF() {
        inspection.status = .completed
        store.updateInspection(inspection)
        isGenerating = true
        DispatchQueue.global(qos: .userInitiated).async {
            let url = PDFService.shared.generateInspectionReport(inspection: inspection)
            DispatchQueue.main.async {
                isGenerating = false
                reportURL = url
                showingPDFPreview = url != nil
            }
        }
    }
}

// MARK: - Inspection List Item (Optional Images)

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
