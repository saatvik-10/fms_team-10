//
//  TodayInspectionsView.swift
//  FMS Frontend
//
//  Detail view showing all scheduled inspections for today and their completion status.
//

import SwiftUI

struct TodayInspectionsView: View {
    @EnvironmentObject var store: MaintenanceStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                let todayInspections = store.inspections.filter { Calendar.current.isDateInToday($0.timestamp) }
                
                if todayInspections.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary.opacity(0.3))
                            .padding(.top, 60)
                        
                        Text("No scheduled inspections for today.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text("DAILY COMPLIANCE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    LazyVStack(spacing: 16) {
                        ForEach(todayInspections, id: \.id) { inspection in
                            NavigationLink(destination: DetailedInspectionView(inspection: inspection)) {
                                InspectionTaskCard(inspection: inspection)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Compliance Details")
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

#Preview {
    NavigationStack {
        TodayInspectionsView()
            .environmentObject(MaintenanceStore())
    }
}
