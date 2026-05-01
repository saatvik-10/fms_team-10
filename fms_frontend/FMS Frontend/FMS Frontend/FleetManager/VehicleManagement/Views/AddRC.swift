//
//  AddRC.swift
//  Created by Akhilesh Mykalwar
//

import SwiftUI
import PhotosUI

struct AddRC: View {
    @StateObject private var viewModel = AddRCViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        ContentUnavailableView(
                            "No RC Selected",
                            systemImage: "card.text",
                            description: Text("Pick an image to begin")
                        )
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1.58, contentMode: .fit)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
                
                HStack(spacing: 16) {
                    PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                        Label("Pick Photo", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { viewModel.runOCR() }) {
                        Group {
                            if viewModel.isProcessing {
                                ProgressView().tint(.white)
                            } else {
                                Label("Scan RC", systemImage: "barcode.viewfinder")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.selectedImage == nil || viewModel.isProcessing)
                }
                .padding()
                
                List {
                    Section("Vehicle") {
                        ResultRow(label: "Reg Number", value: viewModel.parsedData.regNumber, icon: "number.circle.fill")
                        ResultRow(label: "Chassis No", value: viewModel.parsedData.chassis, icon: "barcode")
                        ResultRow(label: "Engine No", value: viewModel.parsedData.engineNumber, icon: "gear")
                        ResultRow(label: "Model", value: viewModel.parsedData.model, icon: "car.circle")
                        ResultRow(label: "Vehicle Class", value: viewModel.parsedData.vehicleClass, icon: "tag.fill")
                        ResultRow(label: "Fuel Type", value: viewModel.parsedData.fuel, icon: "fuelpump.fill")
                        ResultRow(label: "Seating", value: viewModel.parsedData.seatingCapacity, icon: "person.2.fill")
                        ResultRow(label: "Mfg Year", value: viewModel.parsedData.mfgYear, icon: "wrench.fill")
                    }
                    
                    Section("Owner") {
                        ResultRow(label: "Owner Name", value: viewModel.parsedData.owner, icon: "person.fill")
                        ResultRow(label: "Address", value: viewModel.parsedData.address, icon: "location.fill")
                    }
                    
                    Section("Validity") {
                        ResultRow(label: "Reg Date", value: viewModel.parsedData.regDate, icon: "calendar")
                        ResultRow(label: "Valid Till", value: viewModel.parsedData.validity, icon: "checkmark.seal.fill")
                    }
                    
                    if !viewModel.rawLines.isEmpty {
                        Section {
                            DisclosureGroup("Raw OCR (\(viewModel.rawLines.count) lines)") {
                                ForEach(Array(viewModel.rawLines.enumerated()), id: \.offset) { i, line in
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
            .onChange(of: viewModel.selectedItem) { _, newItem in
                Task { await viewModel.loadImage(from: newItem) }
            }
        }
    }
}

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
                Text(value ?? "")
                    .font(.subheadline)
                    .fontWeight(value != nil ? .medium : .regular)
                    .foregroundColor(value != nil ? .primary : .secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
