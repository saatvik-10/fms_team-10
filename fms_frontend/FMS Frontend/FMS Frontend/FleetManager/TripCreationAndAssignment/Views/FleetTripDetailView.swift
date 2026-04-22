import SwiftUI
import MapKit

struct FleetTripDetailView: View {
    @Binding var vehicle: Vehicle
    var tripOverride: VehicleTrip? = nil // New: Allow showing a specific past trip
    
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var isEditing = false
    
    // For editable fields
    @State private var source: String = ""
    @State private var destination: String = ""
    
    // Mock Map data
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090), // Delhi
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // Effective trip to display
    private var displayTrip: VehicleTrip? {
        tripOverride ?? vehicle.currentTrip
    }
    
    var body: some View {
        ZStack {
            AppColors.secondaryBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Spacer()
                    
                    Text(tripOverride != nil ? "Past Trip Details" : "Trip Details")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                    
                    if tripOverride == nil {
                        Menu {
                            Button(action: { 
                                isEditing = true
                                source = vehicle.currentTrip?.origin ?? ""
                                destination = vehicle.currentTrip?.destination ?? ""
                            }) {
                                Label("Edit Trip", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: {
                                showingDeleteAlert = true
                            }) {
                                Label("Delete Trip", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.primary)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    } else {
                        Spacer().frame(width: 40) // Balance the chevron to center title
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Map View (Static/History view doesn't show live location in same way)
                        Map(coordinateRegion: $region)
                            .frame(height: 300)
                            .cornerRadius(16)
                            .overlay(
                                VStack {
                                    Spacer()
                                    HStack {
                                        Image(systemName: tripOverride != nil ? "clock.fill" : "location.fill")
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(tripOverride != nil ? Color.gray : AppColors.primary)
                                            .clipShape(Circle())
                                        Text(tripOverride != nil ? "Trip Completed on \(tripOverride?.date ?? "Past")" : "\(vehicle.id) is on Highway 44")
                                            .font(AppFonts.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.white)
                                            .cornerRadius(20)
                                    }
                                    .padding(.bottom, 20)
                                }
                            )
                        
                        // MARK: - Details Section
                        if let trip = displayTrip {
                            HStack(alignment: .top, spacing: 20) {
                                // Vehicle Details Row-based Card
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack {
                                        Text("VEHICLE INFORMATION")
                                            .font(AppFonts.caption2)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Image(systemName: "truck.box.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.primary.opacity(0.5))
                                    }
                                    .padding(.bottom, 15)
                                    
                                    VStack(spacing: 0) {
                                        FleetDetailItemRow(icon: "tag", label: "Name", value: "\(vehicle.make) \(vehicle.model)", iconColor: .blue)
                                        Divider()
                                        FleetDetailItemRow(icon: "number", label: "Plate", value: vehicle.plateNumber, iconColor: .orange)
                                        Divider()
                                        FleetDetailItemRow(icon: "doc.text", label: "Reg", value: vehicle.registrationNumber, iconColor: .purple)
                                        Divider()
                                        FleetDetailItemRow(icon: "car.side", label: "Year", value: vehicle.year, iconColor: .green)
                                    }
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .background(Color.white)
                                .cornerRadius(16)
                                .modifier(AppColors.cardShadow())
                                
                                // Driver Details Row-based Card
                                if let driver = vehicle.assignedDriver {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack {
                                            Text("DRIVER INFORMATION")
                                                .font(AppFonts.caption2)
                                                .foregroundColor(.gray)
                                            Spacer()
                                            
                                            Button(action: { /* Message action */ }) {
                                                Image(systemName: "message.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white)
                                                    .padding(5)
                                                    .background(AppColors.primary)
                                                    .clipShape(Circle())
                                            }
                                        }
                                        .padding(.bottom, 15)
                                        
                                        VStack(spacing: 0) {
                                            FleetDetailItemRow(icon: "person.fill", label: "Name", value: driver.name, iconColor: .blue)
                                            Divider()
                                            FleetDetailItemRow(icon: "card.fill", label: "License", value: driver.licenseNum, iconColor: .red)
                                            Divider()
                                            FleetDetailItemRow(icon: "phone.fill", label: "Contact", value: driver.phone, iconColor: .green)
                                            Divider()
                                            FleetDetailItemRow(icon: "star.fill", label: "Rating", value: String(format: "%.1f ★", driver.rating), iconColor: .yellow)
                                        }
                                    }
                                    .padding(20)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .modifier(AppColors.cardShadow())
                                }
                            }
                            .padding(.horizontal, 2)
                            
                            // Logistics Overview Section
                            HStack(alignment: .top, spacing: 20) {
                                // Route Summary Card (Ticket Style)
                                LogisticsTicketCard(
                                    title: "ROUTE SUMMARY",
                                    icon: "truck.box.fill",
                                    sourceLabel: "FROM",
                                    sourceValue: trip.origin,
                                    destLabel: "TO",
                                    destValue: trip.destination,
                                    footerLabel: "Trip Duration",
                                    footerValue: trip.duration ?? "TBD"
                                )
                                
                                // Load Information Card (Ticket Style)
                                LogisticsTicketCard(
                                    title: "LOAD INFORMATION",
                                    icon: "shippingbox.fill",
                                    sourceLabel: "PRODUCT",
                                    sourceValue: trip.productType ?? "General",
                                    destLabel: "NET WEIGHT",
                                    destValue: trip.loadAmount ?? "TBD",
                                    footerLabel: "Transit Category",
                                    footerValue: (trip.productType ?? "GEN").prefix(3).uppercased()
                                )
                            }
                            .padding(.horizontal, 2)
                        } else {
                            VStack(spacing: 15) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                Text("No trip data available")
                                    .font(AppFonts.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                        }
                        
                        Spacer().frame(height: 50)
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("End Trip", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Trip", role: .destructive) {
                vehicle.currentTrip = nil
                vehicle.status = .idle
                dismiss()
            }
        } message: {
            Text("Are you sure you want to end this trip? The vehicle will be marked as idle.")
        }
    }
}

struct FleetDetailItemRow: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
            }
            
            Text(label)
                .font(AppFonts.body)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
        }
        .padding(.vertical, 12)
    }
}

struct LogisticsTicketCard: View {
    let title: String
    let icon: String
    let sourceLabel: String
    let sourceValue: String
    let destLabel: String
    let destValue: String
    let footerLabel: String
    let footerValue: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(AppFonts.caption2)
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppColors.primary.opacity(0.9))
            
            // Ticket Body
            VStack(spacing: 15) {
                HStack(alignment: .center) {
                    // Left Side
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sourceLabel.uppercased())
                            .font(AppFonts.caption2)
                            .foregroundColor(.gray)
                        Text(sourceValue)
                            .font(AppFonts.title3)
                            .foregroundColor(AppColors.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    
                    Spacer()
                    
                    // Center Connector
                    VStack(spacing: 0) {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.primary)
                        
                        HStack(spacing: 0) {
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 4, height: 4)
                            Rectangle()
                                .fill(AppColors.primary.opacity(0.2))
                                .frame(height: 1)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(AppColors.primary)
                        }
                        .frame(width: sourceValue.count > 10 ? 40 : 60)
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    // Right Side
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(destLabel.uppercased())
                            .font(AppFonts.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        Text(destValue)
                            .font(AppFonts.title2)
                            .fontWeight(.black)
                            .foregroundColor(AppColors.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                
                Divider()
                
                // Footer
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: title == "ROUTE SUMMARY" ? "clock.fill" : "scalemass.fill")
                            .font(AppFonts.caption2)
                        Text(footerLabel)
                            .font(AppFonts.caption2)
                    }
                    .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(footerValue)
                        .font(AppFonts.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(20)
            .background(Color.white)
        }
        .cornerRadius(16)
        .modifier(AppColors.cardShadow())
    }
}
