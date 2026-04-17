//
//  VehicleInspectionsListView.swift
//  FMS Frontend
//
//  Created by Antigravity on 17/04/26.
//

import SwiftUI

struct VehicleInspectionsListView: View {
    let unitName: String
    let inspections: [TripInspection]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(inspections.sorted(by: { $0.timestamp > $1.timestamp })) { inspection in
                NavigationLink(destination: DetailedInspectionView(inspection: inspection)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(inspection.type.rawValue)
                                .font(.headline)
                            Text(inspection.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        StatusBadge(text: inspection.status.rawValue, color: inspection.status == .completed ? .green : .orange)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(unitName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
