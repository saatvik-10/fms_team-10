//
//  TripInspectionView.swift
//  FMS Frontend
//

import SwiftUI

struct TripInspectionView: View {
    @EnvironmentObject var store: MaintenanceStore
    @State private var selectedTab = "All"
    @State private var showingCreateModal = false
    
    let tabs = ["All", "Pending", "Completed"]
    
    // Group inspections by vehicle unit
    private var vehicleGroups: [String: [TripInspection]] {
        Dictionary(grouping: store.inspections, by: { $0.unitName })
    }
    
    private var sortedUnitNames: [String] {
        vehicleGroups.keys.sorted()
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inspections")
                        .font(.system(size: 34, weight: .bold))
                    
                    Text("\(store.inspections.count) inspection records found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                List {
                    Section {
                        ForEach(sortedUnitNames, id: \.self) { unitName in
                            let inspections = vehicleGroups[unitName] ?? []
                            
                            NavigationLink(
                                destination: VehicleInspectionsListView(
                                    unitName: unitName,
                                    inspections: inspections
                                )
                            ) {
                                HStack(spacing: 12) {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(AppColors.primary)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(unitName)
                                            .font(.headline)
                                        
                                        Text("\(inspections.count) items")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("VEHICLE FOLDERS")
                            .font(.caption2.bold())
                    }
                }
                .listStyle(.insetGrouped)
            }
            
            // Floating Button
            Button(action: {
                showingCreateModal = true
            }) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: AppColors.primary.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreateModal) {
            CreateInspectionModal(isEmergency: false)
        }
    }
}
