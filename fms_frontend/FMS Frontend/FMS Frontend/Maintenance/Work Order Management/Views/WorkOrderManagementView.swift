//
//  WorkOrderManagementView.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI

struct WorkOrderManagementView: View {
    @EnvironmentObject var store: MaintenanceStore
    @State private var showingCreateModal = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Task List Section Label (Optional, but keeping it clean)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monitoring current maintenance lifecycle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                VStack(spacing: 16) {
                    ForEach(store.workOrders) { order in
                        NavigationLink(destination: WorkOrderDetailsView(workOrder: order)) {
                            WorkOrderTaskCard(order: order)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Work Orders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateModal = true }) {
                    Image(systemName: "plus")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $showingCreateModal) {
            CreateWorkOrderModal()
        }
    }
}

