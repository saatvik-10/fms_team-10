//
//  WorkOrderDetailsView.swift
//  FMS Frontend
//

import SwiftUI

struct WorkOrderDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    var workOrder: WorkOrder
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Image
                    ZStack(alignment: .bottomLeading) {
                        Image(systemName: "truck.box.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .background(Color(.systemGray6))
                        
                        // Overlay info could go here but image shows it below
                    }
                    .padding(.horizontal, -16) // Bleed to edges
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workOrder.vehicleName)
                                .font(.system(size: 24, weight: .bold))
                            Text("VIN: \(workOrder.vehicleVIN)")
                                .font(.caption2)
                                .monospaced()
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 12) {
                            StatusBadge(text: workOrder.status.rawValue, color: .blue)
                            PriorityBadge(priority: workOrder.priority.rawValue)
                            
                            Label(workOrder.scheduledDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Task Details
                    InfoSection(title: "TASK DETAILS") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(workOrder.taskDetails)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    // Driver Notes
                    InfoSection(title: "DRIVER NOTES") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "waveform.and.mic")
                                        .foregroundColor(AppColors.primary)
                                    Text("VOICE TRANSCRIPT")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(AppColors.primary)
                                }
                                
                                Text("\"\(workOrder.voiceTranscript ?? "")\"")
                                    .font(.system(size: 14).italic())
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6).opacity(0.5))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                            
                            // Image Gallery
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 80, height: 80)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 80, height: 80)
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 80, height: 80)
                                    Text("+2")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                    }
                    
                    // Technician Notes
                    InfoSection(title: "TECHNICIAN NOTES") {
                        TextEditor(text: .constant(workOrder.technicianNotes))
                            .frame(height: 120)
                            .font(.system(size: 14))
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    }
                    
                    Spacer(minLength: 120)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            
            // Sticky Footer
            VStack {
                Divider()
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Text("Schedule for Later")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    }
                    
                    Button(action: {
                        var updated = workOrder
                        updated.status = .completed
                        store.updateWorkOrder(updated)
                        dismiss()
                    }) {
                        Text("Completed")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .padding(.top, 10)
                .background(.ultraThinMaterial)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
            // Custom Header overlay for translucency
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.headline)
                        .padding(10)
                        .background(Circle().fill(.ultraThinMaterial))
                        .foregroundColor(.primary)
                }
                Spacer()
                Text(workOrder.title)
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.ultraThinMaterial))
                Spacer()
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .padding(10)
                        .background(Circle().fill(.ultraThinMaterial))
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
    }
}

