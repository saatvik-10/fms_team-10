//
//  VehicleInspectionsListView.swift
//  FMS Frontend
//
//  Created by Antigravity on 17/04/26.
//

import SwiftUI

struct VehicleInspectionsListView: View {
    let unitName: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: MaintenanceStore
    
    private var inspections: [TripInspection] {
        store.inspections.filter { $0.unitName == unitName }
    }
    
    @State private var filter: InspectionFilter = .all
    
    enum InspectionFilter: String, CaseIterable {
        case all = "All"
        case preTrip = "Pre-Trip"
        case postTrip = "Post-Trip"
        case maintenance = "Maintenance"
    }

    @State private var selectedSegment = 0 // 0: Inspection, 1: History
    @State private var showPDF = false
    @State private var selectedPDFURL: URL?
    @State private var selectedReportTitle: String = ""

    private var filteredInspections: [TripInspection] {
        inspections.filter { inspection in
            // Filter by segment - Inspection segment only shows completed as per request
            if selectedSegment == 0 {
                guard inspection.status == .completed else { return false }
            }
            
            switch filter {
            case .all: return true
            case .preTrip: return inspection.type == .preTrip
            case .postTrip: return inspection.type == .postTrip
            case .maintenance: return inspection.type == .maintenance
            }
        }
    }
    
    private var filteredHistory: [HistoryEntry] {
        viewModel.mockHistoryEntries.filter { entry in
            switch filter {
            case .all: return true
            case .preTrip: return entry.inspection.type == .preTrip
            case .postTrip: return entry.inspection.type == .postTrip
            case .maintenance: return entry.inspection.type == .maintenance
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segmented Control
            Picker("Selection", selection: $selectedSegment) {
                Text("Inspection").tag(0)
                Text("History").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))

            ScrollView {
                if selectedSegment == 0 {
                    // INSPECTION SEGMENT
                    LazyVStack(spacing: 12) {
                        if filteredInspections.isEmpty {
                            EmptyStateView(
                                icon: "doc.text.magnifyingglass",
                                title: "No \(filter.rawValue) Audits",
                                message: "There are no completed inspection records."
                            )
                            .padding(.top, 60)
                        } else {
                            ForEach(filteredInspections.sorted(by: { $0.timestamp > $1.timestamp })) { inspection in
                                NavigationLink(destination: DetailedInspectionView(inspection: inspection)) {
                                    InspectionTaskCard(inspection: inspection, showUnitName: false)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            store.deleteInspection(inspection)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                } else {
                    // HISTORY SEGMENT (Separate Cards)
                    LazyVStack(spacing: 12) {
                        if filteredHistory.isEmpty {
                            EmptyStateView(
                                icon: "doc.text.magnifyingglass",
                                title: "No History Records",
                                message: "No archived reports found for this vehicle."
                            )
                            .padding(.top, 60)
                        } else {
                            ForEach(filteredHistory) { entry in
                                Button(action: {
                                    if let url = PDFService.shared.generateInspectionReport(inspection: entry.inspection) {
                                        selectedPDFURL = url
                                        selectedReportTitle = entry.title
                                        showPDF = true
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.primary.opacity(0.1))
                                                .frame(width: 48, height: 48)
                                            Image(systemName: "doc.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(AppColors.primary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.title)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.primary)
                                            
                                            Text(entry.inspection.timestamp.formatted(date: .abbreviated, time: .shortened))
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color(.systemGray4))
                                    }
                                    .padding(16)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(unitName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Filter", selection: $filter) {
                        ForEach(InspectionFilter.allCases, id: \.self) { Text($0.rawValue) }
                    }
                } label: {
                    Image(systemName: filter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .fullScreenCover(isPresented: $showPDF) {
            if let url = selectedPDFURL {
                PDFPreviewView(url: url, title: selectedReportTitle)
            }
        }
    }
    
    // History Entry with real inspection data
    struct HistoryEntry: Identifiable {
        let id = UUID()
        let title: String
        let inspection: TripInspection
    }
    
    struct ViewModel {
        let mockHistoryEntries: [HistoryEntry]
        
        init(unitName: String) {
            self.mockHistoryEntries = [
                HistoryEntry(title: "Monthly Brake System Audit", inspection: TripInspection(
                    title: "Monthly Brake System Audit",
                    vehicleId: "V-HIST-1",
                    unitName: unitName,
                    unitVIN: "VIN-BRAKE-01",
                    driverId: "SYSTEM",
                    timestamp: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
                    type: .maintenance,
                    vehicleType: .truck,
                    status: .completed,
                    priority: .high,
                    items: TripInspection.mockItems(for: .truck),
                    maintenanceStaffId: "STAFF-01"
                )),
                HistoryEntry(title: "Annual Safety Certification", inspection: TripInspection(
                    title: "Annual Safety Certification",
                    vehicleId: "V-HIST-2",
                    unitName: unitName,
                    unitVIN: "VIN-SAFETY-02",
                    driverId: "SYSTEM",
                    timestamp: Calendar.current.date(byAdding: .day, value: -90, to: Date())!,
                    type: .maintenance,
                    vehicleType: .truck,
                    status: .completed,
                    priority: .critical,
                    items: TripInspection.mockItems(for: .truck),
                    maintenanceStaffId: "STAFF-02"
                )),
                HistoryEntry(title: "Engine Performance Report", inspection: TripInspection(
                    title: "Engine Performance Report",
                    vehicleId: "V-HIST-3",
                    unitName: unitName,
                    unitVIN: "VIN-ENGINE-03",
                    driverId: "SYSTEM",
                    timestamp: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
                    type: .maintenance,
                    vehicleType: .truck,
                    status: .completed,
                    priority: .medium,
                    items: TripInspection.mockItems(for: .truck),
                    maintenanceStaffId: "STAFF-03"
                ))
            ]
        }
    }
    
    @State private var viewModel: ViewModel
    
    init(unitName: String) {
        self.unitName = unitName
        self._viewModel = State(initialValue: ViewModel(unitName: unitName))
    }
    
    private func deleteItems(at offsets: IndexSet) {
        let sorted = filteredInspections.sorted(by: { $0.timestamp > $1.timestamp })
        for index in offsets {
            let inspectionToDelete = sorted[index]
            withAnimation {
                store.deleteInspection(inspectionToDelete)
            }
        }
    }
}
