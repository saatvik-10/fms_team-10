import SwiftUI

struct FleetMaintenanceAlertDetailView: View {
    let alert: FleetMaintenanceAlert
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: FleetDataManager
    
    var body: some View {
        NavigationView {
            List {
                // Header (Title & Subtitle)
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(alert.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.primary)
                        Text(alert.detail)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
                .listRowSeparator(.hidden)
                
                // Vehicle & Driver Details (Compact Redesign)
                Section(header: Text("Involved Assets").font(.system(size: 14, weight: .bold))) {
                    if let vehicle = dataManager.vehicles.first(where: { $0.id == alert.vehicleID }) {
                        VStack(spacing: 12) {
                            // Vehicle Card
                            HStack(spacing: 15) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.1))
                                    Image(vehicle.imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .padding(8)
                                }
                                .frame(width: 50, height: 50)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(vehicle.id)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(AppColors.primary)
                                    Text("\(vehicle.make) \(vehicle.model)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .padding(.vertical, 4)
                            
                            Divider()
                                .opacity(0.5)
                            
                            // Driver Card (Compact)
                            if let driver = vehicle.assignedDriver {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.primary.opacity(0.08))
                                        Text(String(driver.name.prefix(1)))
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(AppColors.primary)
                                    }
                                    .frame(width: 50, height: 50)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(driver.name)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(AppColors.primary)
                                        Text(driver.title)
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray.opacity(0.3))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } else {
                        Text("Asset information unavailable")
                            .foregroundColor(.gray)
                    }
                }
                
                // Task Details
                Section(header: Text("Task Details").font(.system(size: 14, weight: .bold))) {
                    Text(alert.taskDetails)
                        .font(.system(size: 15))
                        .padding(.vertical, 4)
                }
                
                // Notes
                Section(header: Text("Notes").font(.system(size: 14, weight: .bold))) {
                    Text(alert.notes)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
                
                // Media
                Section(header: Text("Media").font(.system(size: 14, weight: .bold))) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(alert.media, id: \.self) { imageName in
                                Image(imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .cornerRadius(12)
                                    .clipped()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            
                            // Placeholder for "Add Image"
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                                Text("Add Photo")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 120, height: 120)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Actions
                Section {
                    Button(action: {
                        acceptAlert()
                    }) {
                        Text("Accept & Send to Maintenance")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.primary)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Decline")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Alert Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func acceptAlert() {
        // Logic to update vehicle status
        if let vIndex = dataManager.vehicles.firstIndex(where: { $0.id == alert.vehicleID }) {
            dataManager.vehicles[vIndex].status = .maintenance
        }
        
        // Remove alert or mark as accepted
        if let aIndex = dataManager.maintenanceAlerts.firstIndex(where: { $0.id == alert.id }) {
            dataManager.maintenanceAlerts[aIndex].isAccepted = true
            // In a real app, we might remove it or move to a "Processing" state
        }
        
        dismiss()
    }
}
