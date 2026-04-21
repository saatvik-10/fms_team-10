//
//  TodayInspectionsView.swift
//  FMS Frontend
//
//  Detail view showing all scheduled inspections for today and their completion status.
//

import SwiftUI

struct TodayInspectionsView: View {
    @EnvironmentObject var store: MaintenanceStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        List {
            Section(header: Text("Today's Inspections")) {
                let todayInspections = store.inspections.filter { Calendar.current.isDateInToday($0.timestamp) }
                
                if todayInspections.isEmpty {
                    Text("No scheduled inspections for today.")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(todayInspections, id: \.id) { inspection in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Vehicle: \(inspection.vehicleId)")
                                    .font(.headline)
                                Text("Inspector: \(inspection.maintenanceStaffId)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if inspection.status == .completed {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "circle.dashed")
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Compliance Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TodayInspectionsView()
            .environmentObject(MaintenanceStore())
    }
}
