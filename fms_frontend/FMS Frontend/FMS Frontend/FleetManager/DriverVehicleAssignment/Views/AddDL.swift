//
//  AddDL.swift
//  Created by Monica Rokade
//

import SwiftUI
import PhotosUI

struct AddDL: View {
    @StateObject private var viewModel = AddDLViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    DLImageSlot(image: viewModel.frontImage, label: "Front",
                                systemImage: "person.crop.rectangle.fill",
                                pickerItem: $viewModel.frontItem)

                    DLImageSlot(image: viewModel.backImage, label: "Back",
                                systemImage: "rectangle.on.rectangle",
                                pickerItem: $viewModel.backItem)
                }
                .padding(.horizontal)
                .padding(.top)

                Button(action: { viewModel.runOCR() }) {
                    Group {
                        if viewModel.isProcessing {
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
                .disabled(!viewModel.canScan || viewModel.isProcessing)
                .padding()

                List {
                    Section("Identity") {
                        DLResultRow(label: "DL Number", value: viewModel.parsedData.dlNumber, icon: "number.circle.fill")
                        DLResultRow(label: "Name", value: viewModel.parsedData.name, icon: "person.fill")
                        DLResultRow(label: "Date of Birth", value: viewModel.parsedData.dob, icon: "calendar")
                    }

                    Section("Licence Details") {
                        DLResultRow(label: "Vehicle Classes", value: viewModel.parsedData.vehicleClasses, icon: "car.2.fill")
                        DLResultRow(label: "NT Valid From", value: viewModel.parsedData.validFromNT, icon: "calendar.badge.checkmark")
                        DLResultRow(label: "Expiry Date", value: viewModel.parsedData.expiryDate, icon: "calendar.badge.exclamationmark")
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
            .navigationTitle("DL Scanner")
            .onChange(of: viewModel.frontItem) { _, _ in
                Task { await viewModel.loadImage(from: viewModel.frontItem, isFront: true) }
            }
            .onChange(of: viewModel.backItem) { _, _ in
                Task { await viewModel.loadImage(from: viewModel.backItem, isFront: false) }
            }
        }
    }
}

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
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack {
                        Image(systemName: systemImage)
                        Text(label)
                    }
                }
            }
            .aspectRatio(1.58, contentMode: .fit)
        }
    }
}

struct DLResultRow: View {
    var label: String
    var value: String?
    var icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(label)
            Spacer()
            Text(value ?? "")
        }
    }
}
