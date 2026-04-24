//
//  WorkOrderDetailsView.swift
//  FMS Frontend
//

import SwiftUI

struct WorkOrderDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    @State var workOrder: WorkOrder
    
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    @State private var showingScheduleSuccess = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingProofSource = false
    @State private var newNoteText: String = ""
    @State private var showingPartPicker = false
    @State private var partSearchText = ""
    @State private var showingScheduleValidationAlert = false
    @State private var showingChecklistIncompleteAlert = false
    @State private var recentlyUpdatedPartId: String?
    @State private var pendingSelectedPartIds: Set<String> = []
    
    private var taskPoints: [String] {
        workOrder.taskDetails.components(separatedBy: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { "\($0)." }
    }

    private var canReschedule: Bool {
        !workOrder.hasBeenRescheduled && workOrder.status != .completed
    }

    private var isChecklistComplete: Bool {
        workOrder.checklist.allSatisfy { $0.result != .pending }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 1. Hero Section
                    ZStack(alignment: .center) {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray6)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        if let assetName = workOrder.imageAsset, !assetName.isEmpty {
                            Image(assetName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 240)
                                .clipped()
                        } else {
                            Image(systemName: "truck.box.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 140)
                                .foregroundColor(AppColors.primary.opacity(0.8))
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    
                    // 2. Content Section
                    VStack(alignment: .leading, spacing: 28) {
                        // Vehicle Info Header
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Work ID: \(workOrder.orderID)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(AppColors.primary.opacity(0.1))
                                    .cornerRadius(6)
                                
                                Spacer()
                            }
                            
                            Text(workOrder.vehicleName)
                                .font(.largeTitle.weight(.heavy))
                                .foregroundColor(.primary)
                            
                            // Scheduled Date Subtitle
                            Text("Scheduled for: \(workOrder.scheduledDate.formatted(date: .long, time: .shortened))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                             
                            HStack(spacing: 12) {
                                StatusBadge(text: workOrder.status.rawValue, color: .blue)
                                PriorityBadge(priority: workOrder.priority.rawValue)
                            }
                            .padding(.top, 8)
                        }
                        
                        Divider().padding(.vertical, 12)
                        
                        // Task Details Card
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "TASK DETAILS", icon: "doc.text.fill")
                            
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(taskPoints, id: \.self) { point in
                                    Text(point)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        }
                        
                        // Driver Notes Card
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "DRIVER NOTES", icon: "person.wave.2.fill")
                            driverNotesContent
                        }
                        
                        // System Checklist
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "SYSTEM CHECKLIST", icon: "checklist")
                                .padding(.horizontal)
                            checklistContent
                        }
                        
                        // Technician Notes
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "TECHNICIAN NOTES", icon: "wrench.and.screwdriver.fill")
                            technicianNotesContent
                        }
                        
                        // Resource Link: Parts Consumed
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "PARTS CONSUMED", icon: "shippingbox.fill")
                            
                            VStack(alignment: .leading, spacing: 16) {
                                if workOrder.consumedParts.isEmpty {
                                    Text("No parts consumed yet.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(workOrder.consumedParts) { usage in
                                        if let inventoryPart = store.inventoryParts.first(where: { $0.partId == usage.inventoryPartId }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "shippingbox.fill")
                                                    .foregroundColor(AppColors.primary)
                                                    .frame(width: 32, height: 32)
                                                    .background(AppColors.primary.opacity(0.1))
                                                    .cornerRadius(8)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(inventoryPart.partName)
                                                        .font(.system(size: 15, weight: .bold))
                                                    Text(inventoryPart.partId)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }

                                                Spacer()

                                                HStack(spacing: 8) {
                                                    Button {
                                                        updateConsumedQuantity(partId: usage.inventoryPartId, quantity: usage.quantity - 1)
                                                    } label: {
                                                        Image(systemName: "minus.circle.fill")
                                                            .font(.title3)
                                                            .foregroundColor(.secondary)
                                                    }

                                                     Text("\(usage.quantity)")
                                                         .font(.system(size: 14, weight: .bold, design: .rounded))
                                                         .frame(minWidth: 22)

                                                     if recentlyUpdatedPartId == usage.inventoryPartId {
                                                         Image(systemName: "checkmark.circle.fill")
                                                             .font(.subheadline)
                                                             .foregroundColor(.green)
                                                             .transition(.scale.combined(with: .opacity))
                                                     }

                                                    Button {
                                                        updateConsumedQuantity(partId: usage.inventoryPartId, quantity: usage.quantity + 1)
                                                    } label: {
                                                        Image(systemName: "plus.circle.fill")
                                                            .font(.title3)
                                                            .foregroundColor(AppColors.primary)
                                                    }

                                                    Button {
                                                        removeConsumedPart(partId: usage.inventoryPartId)
                                                    } label: {
                                                        Image(systemName: "trash")
                                                            .font(.subheadline)
                                                            .foregroundColor(.red)
                                                    }
                                                    .padding(.leading, 2)
                                                }
                                            }
                                        }
                                    }
                                }

                                Button {
                                    pendingSelectedPartIds = Set(workOrder.consumedParts.map { $0.inventoryPartId })
                                    showingPartPicker = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus")
                                        Text("Add Part")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppColors.primary)
                                }

                                if !workOrder.consumedParts.isEmpty {
                                    Text("Stock updates automatically when quantities change.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        }
                        
                        // Service Media Gallery
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "MEDIA", icon: "camera.fill")
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(0..<workOrder.proofOfWorkImages.count, id: \.self) { index in
                                        Image(uiImage: UIImage(data: workOrder.proofOfWorkImages[index]) ?? UIImage())
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 90, height: 90)
                                            .cornerRadius(12)
                                            .clipped()
                                    }
                                    
                                    Button(action: { showingProofSource = true }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title3)
                                            Text("Capture")
                                                .font(.caption2.weight(.bold))
                                        }
                                        .frame(width: 90, height: 90)
                                        .background(Color(.systemGray6))
                                        .foregroundColor(AppColors.primary)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        }
                        
                        // Action Buttons (Now part of the scroll content)
                        HStack(spacing: 16) {
                            if canReschedule {
                                Button(action: { showingDatePicker = true }) {
                                    Text("Schedule Later")
                                        .font(.system(size: 15, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.white)
                                        .foregroundColor(.primary)
                                        .cornerRadius(14)
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                }
                            }
                            
                            Button(action: {
                                guard isChecklistComplete else {
                                    showingChecklistIncompleteAlert = true
                                    return
                                }
                                var updated = workOrder
                                updated.status = .completed
                                store.updateWorkOrder(updated)
                                workOrder = updated
                                dismiss()
                            }) {
                                Text("Complete Task")
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppColors.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                                    .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(!isChecklistComplete)
                            .opacity(isChecklistComplete ? 1 : 0.55)
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .confirmationDialog("Proof of Work", isPresented: $showingProofSource) {
            Button("Camera") { showingCamera = true }
            Button("Photo Library") { showingImagePicker = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoPicker(images: Binding(
                get: { [] },
                set: { images in
                    workOrder.proofOfWorkImages.append(contentsOf: images.compactMap { $0.jpegData(compressionQuality: 0.7) })
                    store.updateWorkOrder(workOrder)
                }
            ))
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(image: Binding(
                get: { nil },
                set: { if let img = $0 {
                    workOrder.proofOfWorkImages.append(img.jpegData(compressionQuality: 0.7)!)
                    store.updateWorkOrder(workOrder)
                } }
            ))
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                VStack {
                    DatePicker("Select New Date", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .padding()
                    Spacer()
                }
                .navigationTitle("Schedule Task")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: { showingDatePicker = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {
                            let now = Date()
                            guard selectedDate >= now else {
                                selectedDate = now
                                showingScheduleValidationAlert = true
                                return
                            }

                            var updated = workOrder
                            updated.scheduledDate = selectedDate
                            updated.hasBeenRescheduled = true
                            store.updateWorkOrder(updated)
                            workOrder = updated
                            showingDatePicker = false
                            showingScheduleSuccess = true
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
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
                        Button("Cancel") {
                            showingPartPicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            // Apply selected parts
                            for partId in pendingSelectedPartIds {
                                if !workOrder.consumedParts.contains(where: { $0.inventoryPartId == partId }) {
                                    workOrder.consumedParts.append(WorkOrderPartUsage(inventoryPartId: partId, quantity: 1))
                                }
                            }
                            // Remove parts that were unselected (optional, usually "Select" means add)
                            // For now, we only ADD new ones as per typical "Select Parts" behavior.
                            
                            store.updateWorkOrder(workOrder)
                            showingPartPicker = false
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                }
            }
        }
        .alert("Success", isPresented: $showingScheduleSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Work order for \(workOrder.vehicleName) has been rescheduled to \(selectedDate.formatted(date: .abbreviated, time: .shortened)).")
        }
        .alert("Invalid Schedule", isPresented: $showingScheduleValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Scheduled date and time cannot be before the current time.")
        }
        .alert("Checklist Incomplete", isPresented: $showingChecklistIncompleteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Complete all checklist items before completing this work order.")
        }
        .navigationTitle(workOrder.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var driverNotesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let transcript = workOrder.voiceTranscript, !transcript.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(AppColors.primary)
                        Text("VOICE TRANSCRIPT")
                            .font(.caption.weight(.black))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Text("\"\(transcript)\"")
                        .font(.subheadline.italic())
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
            } else {
                Text("No driver notes available.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var checklistContent: some View {
        VStack(spacing: 0) {
            ForEach($workOrder.checklist, id: \.id) { $item in
                InspectionListItem(item: $item)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                
                if item.id != workOrder.checklist.last?.id {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        .onChange(of: workOrder.checklist) { _ in
            store.updateWorkOrder(workOrder)
        }
    }

    @ViewBuilder
    private var technicianNotesContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            let notesPoints = workOrder.technicianNotes.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            
            if notesPoints.isEmpty {
                Text("No technician notes yet.")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                ForEach(notesPoints, id: \.self) { point in
                    Text(point)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            
            Divider().padding(.vertical, 4)
            
            HStack(alignment: .top, spacing: 10) {
                TextField("Add a new note...", text: $newNoteText, axis: .vertical)
                    .font(.body)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                
                Button(action: {
                    let trimmed = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        let newNotes = workOrder.technicianNotes.isEmpty ? trimmed : workOrder.technicianNotes + "\n" + trimmed
                        workOrder.technicianNotes = newNotes
                        store.updateWorkOrder(workOrder)
                        newNoteText = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : AppColors.primary)
                }
                .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }

    private var filteredInventoryParts: [InventoryPart] {
        let sortedParts = store.inventoryParts.sorted { $0.partName.localizedCaseInsensitiveCompare($1.partName) == .orderedAscending }
        guard !partSearchText.isEmpty else { return sortedParts }
        return sortedParts.filter {
            $0.partName.localizedCaseInsensitiveContains(partSearchText) ||
            $0.partId.localizedCaseInsensitiveContains(partSearchText)
        }
    }

    private func addOrIncrementConsumedPart(_ part: InventoryPart) {
        if let idx = workOrder.consumedParts.firstIndex(where: { $0.inventoryPartId == part.partId }) {
            workOrder.consumedParts[idx].quantity += 1
        } else {
            workOrder.consumedParts.append(WorkOrderPartUsage(inventoryPartId: part.partId, quantity: 1))
        }
        store.updateWorkOrder(workOrder)
    }

    private func updateConsumedQuantity(partId: String, quantity: Int) {
        guard let idx = workOrder.consumedParts.firstIndex(where: { $0.inventoryPartId == partId }) else { return }
        if quantity <= 0 {
            workOrder.consumedParts.remove(at: idx)
            recentlyUpdatedPartId = nil
        } else {
            workOrder.consumedParts[idx].quantity = quantity
            markPartUpdated(partId)
        }
        store.updateWorkOrder(workOrder)
    }

    private func markPartUpdated(_ partId: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            recentlyUpdatedPartId = partId
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            if recentlyUpdatedPartId == partId {
                withAnimation(.easeInOut(duration: 0.2)) {
                    recentlyUpdatedPartId = nil
                }
            }
        }
    }

    private func removeConsumedPart(partId: String) {
        guard let idx = workOrder.consumedParts.firstIndex(where: { $0.inventoryPartId == partId }) else { return }
        workOrder.consumedParts.remove(at: idx)
        store.updateWorkOrder(workOrder)
    }
}
