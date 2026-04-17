//
//  MaintenanceReportsView.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI

struct ReportRecord: Identifiable {
    let id = UUID()
    let url: URL
    let date: Date
    let vehicleId: String
}

struct MaintenanceReportsView: View {
    @State private var reports: [ReportRecord] = []
    
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if reports.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 64))
                            .foregroundColor(AppColors.secondaryText.opacity(0.3))
                        
                        VStack(spacing: 8) {
                            Text("No reports generated yet")
                                .font(.headline)
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text("Complete an inspection to see your generated reports here.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        Button(action: generateMockReport) {
                            Label("Generate Sample Report", systemImage: "wand.and.stars")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(AppColors.primary)
                                .cornerRadius(12)
                        }
                    }
                } else {
                    List {
                        Section {
                            ForEach(reports) { report in
                                NavigationLink(destination: ReportDetailView(report: report)) {
                                    ReportRow(report: report)
                                }
                                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteReport)
                        } header: {
                            Text("RECENTLY GENERATED")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppColors.secondaryText)
                                .padding(.bottom, 8)
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Reports")
        .onAppear(perform: loadReports)
    }
    
    func loadReports() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            
            let pdfs = fileURLs.filter { $0.pathExtension == "pdf" }
            
            self.reports = pdfs.compactMap { url -> ReportRecord? in
                let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                let date = attributes?[.creationDate] as? Date ?? Date()
                
                let filename = url.lastPathComponent
                let components = filename.components(separatedBy: "_")
                let vehicleId = components.count > 1 ? components[1] : "Unknown"
                
                return ReportRecord(url: url, date: date, vehicleId: vehicleId)
            }.sorted(by: { $0.date > $1.date })
            
        } catch {
            print("Error loading reports: \(error)")
        }
    }
    
    func generateMockReport() {
        let mockItems = [
            InspectionItem(name: "Front Brakes", verificationCriteria: "Pads > 4mm. No squeal.", isFulfilled: true, isImageRequired: true),
            InspectionItem(name: "Tire Pressure", verificationCriteria: "All tires at 32 PSI.", isFulfilled: true, isImageRequired: false),
            InspectionItem(name: "Engine Coolant", verificationCriteria: "Level at MAX. Pink color.", isFulfilled: false, isImageRequired: true)
        ]
        
        let mockInspection = TripInspection(
            vehicleId: "V-SAMPLE-99",
            driverId: "D-SIMULATOR",
            timestamp: Date(),
            type: .preTrip,
            vehicleType: .truck,
            status: .completed,
            items: mockItems,
            maintenanceStaffId: "M-1"
        )
        
        if let tempURL = PDFService.shared.generateInspectionReport(inspection: mockInspection) {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let permanentURL = documentsURL.appendingPathComponent(tempURL.lastPathComponent)
            
            try? fileManager.moveItem(at: tempURL, to: permanentURL)
            loadReports()
        }
    }
    
    func deleteReport(at offsets: IndexSet) {
        for index in offsets {
            let report = reports[index]
            try? FileManager.default.removeItem(at: report.url)
        }
        reports.remove(atOffsets: offsets)
    }
}

struct ReportRow: View {
    let report: ReportRecord
    
    var body: some View {
        HStack(spacing: 16) {
            // Native-style Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "doc.richtext.fill")
                    .foregroundColor(AppColors.primary)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Inspection Report")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                HStack(spacing: 8) {
                    Text(report.vehicleId)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.secondaryText.opacity(0.8))
                        .cornerRadius(4)
                    
                    Text(report.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct ReportDetailView: View {
    let report: ReportRecord
    @Environment(\.presentationMode) var presentationMode
    @State private var showingShareSheet = false
    
    var body: some View {
        PDFKitView(url: report.url)
            .navigationTitle(report.vehicleId)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [report.url])
            }
    }
}
