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
                        VStack(alignment: .leading, spacing: 10) {
                            Text(workOrder.vehicleName)
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Text("VIN:")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.secondary)
                                Text(workOrder.vehicleVIN)
                                    .font(.caption.monospaced())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(6)
                            }
                            
                            HStack(spacing: 12) {
                                StatusBadge(text: workOrder.status.rawValue, color: .blue)
                                PriorityBadge(priority: workOrder.priority.rawValue)
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                    Text(workOrder.scheduledDate.formatted(date: .abbreviated, time: .omitted))
                                }
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            }
                            .padding(.top, 6)
                        }
                        
                        Divider()
                        
                        // Task Details Card
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "TASK DETAILS", icon: "doc.text.fill")
                            
                            Text(workOrder.taskDetails)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(6)
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        }
                        
                        // Driver Notes Card
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "DRIVER NOTES", icon: "person.wave.2.fill")
                            
                            VStack(alignment: .leading, spacing: 16) {
                                if let transcript = workOrder.voiceTranscript, !transcript.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "waveform")
                                                .foregroundColor(AppColors.primary)
                                            Text("VOICE TRANSCRIPT")
                                                .font(.system(size: 11, weight: .black))
                                                .foregroundColor(AppColors.primary)
                                        }
                                        
                                        Text("\"\(transcript)\"")
                                            .font(.system(size: 15).italic())
                                            .foregroundColor(.secondary)
                                            .lineSpacing(4)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6).opacity(0.5))
                                    .cornerRadius(12)
                                }
                                
                                // Image Gallery
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(0..<3) { _ in
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemGray6))
                                                .frame(width: 90, height: 90)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.secondary.opacity(0.5))
                                                        .font(.system(size: 24))
                                                )
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        }
                        
                        // Technician Notes
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "TECHNICIAN NOTES", icon: "wrench.and.screwdriver.fill")
                            
                            TextEditor(text: Binding(
                                get: { workOrder.technicianNotes },
                                set: { workOrder.technicianNotes = $0 }
                            ))
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        }

                        // Proof of Work Gallery
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "PROOF OF WORK", icon: "camera.fill")
                            
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
                                                .font(.system(size: 20))
                                            Text("Capture")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .frame(width: 90, height: 90)
                                        .background(Color(.systemGray6))
                                        .foregroundColor(AppColors.primary)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                        
                        Spacer(minLength: 160) // Extra space for sticky footer + tab bar
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
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
            
            // Sticky Footer
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 16) {
                    Button(action: { showingDatePicker = true }) {
                        Text("Schedule Later")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                    
                    Button(action: {
                        var updated = workOrder
                        updated.status = .completed
                        store.updateWorkOrder(updated)
                        workOrder = updated
                        dismiss()
                    }) {
                        Text("Complete Task")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 34) // Standard safe area padding
                .background(.ultraThinMaterial)
            }
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
                            var updated = workOrder
                            updated.scheduledDate = selectedDate
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
        .alert("Success", isPresented: $showingScheduleSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Work order for \(workOrder.vehicleName) has been rescheduled to \(selectedDate.formatted(date: .abbreviated, time: .shortened)).")
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
}

// Reusable Sub-component for Section Headers
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
            Text(title)
                .font(.system(size: 11, weight: .black))
                .tracking(1)
        }
        .foregroundColor(AppColors.primary.opacity(0.7))
        .padding(.leading, 4)
    }
}

