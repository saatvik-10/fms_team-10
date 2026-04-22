import SwiftUI

struct FleetManagerVehicleDetailView: View {
    let vehicle: Vehicle
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: FleetDataManager
    @State private var showingEditModal = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                HStack(spacing: 20) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Text(vehicle.id)
                        .font(AppFonts.title3)
                    Spacer()
                    
                    Menu {
                        Button(action: { showingEditModal = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 25)
                .background(Color.white)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // MARK: - Hero Row
                        HStack(alignment: .top, spacing: 30) {
                            // Vehicle Hero Image
                            ZStack(alignment: .bottomLeading) {
                                Image(vehicle.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(20)
                                    .clipped()
                                
                                // Overlay Status & Name
                                VStack(alignment: .leading, spacing: 8) {
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(vehicle.id)
                                            .font(AppFonts.largeTitle)
                                            .fontWeight(.black)
                                        Text("\(vehicle.year) \(vehicle.make) \(vehicle.model) • \(vehicle.color)")
                                            .font(AppFonts.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(30)
                            }
                            
                            // Odometer & Status Side Card
                            VStack(alignment: .leading, spacing: 25) {
                                VStack(alignment: .leading, spacing: 15) {
                                    HStack {
                                        Text("ODOMETER")
                                            .font(AppFonts.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Image(systemName: "gauge.with.dots.needle.bottom.100percent")
                                            .foregroundColor(.gray)
                                    }
                                    
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text(vehicle.odometer)
                                            .font(AppFonts.largeTitle)
                                            .fontWeight(.black)
                                        Text("MILES")
                                            .font(AppFonts.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(30)
                                .frame(width: 280)
                                .background(Color.white)
                                .cornerRadius(20)
                                
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("STATUS")
                                        .font(AppFonts.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    
                                    Text(vehicle.status == .inTransit ? "IN TRANSIT" : 
                                         vehicle.status == .idle ? "IDLE" : "MAINTENANCE")
                                        .font(AppFonts.callout)
                                        .fontWeight(.bold)
                                        .foregroundColor(vehicle.status == .inTransit ? AppColors.activeGreen : 
                                                        vehicle.status == .maintenance ? AppColors.criticalRed : .gray)
                                }
                                .padding(30)
                                .frame(width: 280, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(20)
                            }
                        }
                        
                        // MARK: - Assessment Spotlight (Emphasized Reason)
                        if let reason = vehicle.assessmentReason {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("ASSESSMENT INSIGHT")
                                    .font(AppFonts.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 15) {
                                    Circle()
                                        .fill(AppColors.primary)
                                        .frame(width: 40, height: 40)
                                        .overlay(Image(systemName: "sparkles").foregroundColor(.white))
                                    
                                    Text(reason)
                                        .font(AppFonts.title3)
                                        .fontWeight(.black)
                                }
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.primary.opacity(0.03))
                            .cornerRadius(20)
                        }

                        // MARK: - Transit & Driver Row
                        HStack(alignment: .top, spacing: 30) {
                            // Current Transit
                            VStack(alignment: .leading, spacing: 35) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("CURRENT TRANSIT")
                                            .font(AppFonts.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                        Text(vehicle.currentTrip != nil ? "Active Trip" : "No Active Journey")
                                            .font(AppFonts.title2)
                                            .fontWeight(.bold)
                                    }
                                    Spacer()
                                    if let trip = vehicle.currentTrip {
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("ETA")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.gray)
                                            Text(trip.eta)
                                                .font(.system(size: 20, weight: .bold))
                                        }
                                    }
                                }
                                
                                if let trip = vehicle.currentTrip {
                                    // Origin -> Destination Progress
                                    HStack(spacing: 30) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("ORIGIN")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(.gray)
                                            Text(trip.origin)
                                                .font(.system(size: 18, weight: .black))
                                        }
                                        
                                        // Progress Bar
                                        VStack(spacing: 8) {
                                            Text("\(Int(trip.progress * 100))%")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(AppColors.primary)
                                            
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(height: 8)
                                                    
                                                    Capsule()
                                                        .fill(AppColors.primary)
                                                        .frame(width: geo.size.width * CGFloat(trip.progress), height: 8)
                                                }
                                            }
                                            .frame(height: 8)
                                        }
                                        .frame(maxWidth: .infinity)
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("DESTINATION")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(.gray)
                                            Text(trip.destination)
                                                .font(.system(size: 18, weight: .black))
                                                .multilineTextAlignment(.trailing)
                                        }
                                    }
                                } else {
                                    HStack {
                                        Spacer()
                                        Text("Vehicle is currently idle")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                }
                                Spacer()
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .background(Color.white)
                            .cornerRadius(20)
                            
                            // Assigned Driver
                            if let driver = vehicle.assignedDriver {
                                VStack(alignment: .leading, spacing: 25) {
                                        Text("ASSIGNED DRIVER")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.gray)
                                    
                                    HStack(spacing: 15) {
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                            .overlay(Image(systemName: "person.fill").foregroundColor(.gray).font(.system(size: 25)))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(driver.name)
                                                .font(AppFonts.title3)
                                                .fontWeight(.bold)
                                            Text("\(driver.id) • \(driver.title.uppercased())")
                                                .font(AppFonts.caption1)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    HStack(spacing: 15) {
                                        Button(action: { }) {
                                            Label("Call Driver", systemImage: "phone.fill")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(AppColors.primary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 15)
                                                .background(Color.gray.opacity(0.05))
                                                .cornerRadius(12)
                                        }
                                        
                                        Button(action: { }) {
                                            Label("Message", systemImage: "envelope.fill")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(AppColors.primary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 15)
                                                .background(Color.gray.opacity(0.05))
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(35)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .background(Color.white)
                                .cornerRadius(20)
                            }
                        }
                        
                        // MARK: - Maintenance & History
                        HStack(spacing: 30) {
                            // Maintenance Status
                            VStack(alignment: .leading, spacing: 25) {
                                HStack {
                                    Text("MAINTENANCE STATUS")
                                        .font(AppFonts.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 20) {
                                    HStack(spacing: 20) {
                                        Image(systemName: "calendar.badge.checkmark")
                                            .foregroundColor(AppColors.primary)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("NEXT SERVICE")
                                                .font(AppFonts.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.gray)
                                            Text(vehicle.maintenance.nextService)
                                                .font(AppFonts.headline)
                                        }
                                    }
                                    
                                    HStack(spacing: 20) {
                                        Image(systemName: "checklist")
                                            .foregroundColor(AppColors.primary)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("PRE-TRIP INSPECTION")
                                                .font(AppFonts.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.gray)
                                            Text(vehicle.maintenance.inspectionStatus)
                                                .font(AppFonts.headline)
                                                .foregroundColor(AppColors.activeGreen)
                                        }
                                    }
                                    
                                    if let alert = vehicle.maintenance.alerts.first {
                                        HStack(spacing: 15) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(AppColors.criticalRed)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(alert.title)
                                                    .font(AppFonts.headline)
                                                    .foregroundColor(AppColors.criticalRed)
                                                Text(alert.detail)
                                                    .font(AppFonts.caption2)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding(20)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(AppColors.criticalRed.opacity(0.05))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(35)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .background(Color.white)
                            .cornerRadius(20)
                            
                            // Recent History
                            VStack(alignment: .leading, spacing: 25) {
                                Text("RECENT HISTORY")
                                    .font(AppFonts.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                
                                VStack(spacing: 0) {
                                    if vehicle.history.isEmpty {
                                        Text("No history yet")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .padding(.vertical, 20)
                                    } else {
                                    ForEach(vehicle.history) { trip in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(trip.date ?? "")
                                                    .font(AppFonts.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.gray)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("\(trip.origin) → \(trip.destination)")
                                                        .font(AppFonts.headline)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                    Text("\(trip.distance ?? "") • \(trip.duration ?? "")")
                                                        .font(AppFonts.caption1)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.gray.opacity(0.3))
                                        }
                                        .padding(.vertical, 15)
                                        
                                        if trip.id != vehicle.history.last?.id {
                                            Divider()
                                        }
                                    }
                                    }
                                }
                                
                                NavigationLink(destination: VehicleLogView(vehicle: vehicle)) {
                                    Text("VIEW FULL LOG")
                                        .font(AppFonts.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                                }
                            }
                            .padding(35)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .background(Color.white)
                            .cornerRadius(20)
                        }
                        
                        // MARK: - Past Reports
                        VStack(alignment: .leading, spacing: 25) {
                            Text("PAST REPORTS")
                                .font(AppFonts.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            if vehicle.reports.isEmpty {
                                Text("No reports yet")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 20)
                            } else {
                            HStack(spacing: 20) {
                                ForEach(vehicle.reports) { report in
                                    HStack(spacing: 15) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8).fill(AppColors.criticalRed.opacity(0.1))
                                                .frame(width: 45, height: 45)
                                            Image(systemName: "doc.fill")
                                                .foregroundColor(AppColors.criticalRed)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(report.title)
                                                .font(AppFonts.headline)
                                            Text(report.subtitle)
                                                .font(AppFonts.caption2)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.down.to.line")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(20)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.03))
                                    .cornerRadius(12)
                                }
                            }
                            }
                            
                            NavigationLink(destination: ArchiveListView(vehicle: vehicle)) {
                                Text("VIEW ARCHIVE")
                                    .font(AppFonts.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                            }
                        }
                        .padding(35)
                        .background(Color.white)
                        .cornerRadius(20)
                        
                    }
                    .padding(40)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEditModal) {
            AddVehicleModalView(vehicleToEdit: vehicle)
        }
        .alert("Confirm Delete", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let index = dataManager.vehicles.firstIndex(where: { $0.id == vehicle.id }) {
                    dataManager.vehicles.remove(at: index)
                }
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this vehicle?")
        }
    }
}
