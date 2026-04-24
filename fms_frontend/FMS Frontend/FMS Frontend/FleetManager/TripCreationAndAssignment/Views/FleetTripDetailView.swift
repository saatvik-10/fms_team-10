import SwiftUI
import GoogleMaps
import CoreLocation

struct FleetTripDetailView: View {
    @Binding var vehicle: Vehicle
    var tripOverride: VehicleTrip? = nil // New: Allow showing a specific past trip
    
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var isEditing = false
    
    @StateObject private var locationManager = FleetLocationManager()
    
    // Google Maps / Directions State
    @State private var encodedPolyline: String = ""
    @State private var apiEta: String = "Loading..."
    @State private var apiDistance: String = "..."
    @State private var originCoord: CLLocationCoordinate2D? = nil
    @State private var destCoord: CLLocationCoordinate2D? = nil
    @State private var routeError: String? = nil
    @State private var isLoadingRoute: Bool = false
    @State private var originName: String = ""
    @State private var destName: String = ""
    
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
                        
                        // MARK: - Map View
                        ZStack {
                            FleetGoogleMapView(
                                encodedPolyline: encodedPolyline,
                                originCoord: originCoord,
                                destCoord: destCoord,
                                originLabel: displayTrip?.origin ?? "Origin",
                                destLabel: displayTrip?.destination ?? "Destination",
                                geofenceRadius: displayTrip?.geofenceRadius ?? 1000.0
                            )
                            .frame(height: 300)
                            .cornerRadius(16)
                            
                            if let error = routeError {
                                Color.black.opacity(0.4)
                                    .cornerRadius(16)
                                VStack {
                                    Image(systemName: "exclamationmark.map.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                    Text(error)
                                        .font(AppFonts.caption1)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            VStack {
                                Spacer()
                                HStack {
                                    Image(systemName: tripOverride != nil ? "clock.fill" : "location.fill")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(tripOverride != nil ? Color.gray : AppColors.primary)
                                        .clipShape(Circle())
                                    Text(tripStatusText)
                                        .font(AppFonts.caption2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white)
                                        .cornerRadius(20)
                                }
                                .padding(.bottom, 20)
                            }
                        }
                        
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
                            VStack(spacing: 20) {
                                LogisticsTicketCard(
                                    title: "ROUTE SUMMARY",
                                    icon: "truck.box.fill",
                                    sourceLabel: "FROM",
                                    sourceValue: originName.isEmpty ? trip.origin : originName,
                                    destLabel: "TO",
                                    destValue: destName.isEmpty ? trip.destination : destName,
                                    footerLabel: "Trip Duration",
                                    footerValue: routeError != nil ? (trip.duration ?? "TBD") : apiEta
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
        .task {
            locationManager.requestPermission()
            await loadRouteData()
        }
        .onChange(of: locationManager.lastLocation?.latitude) { _ in
            // Re-fetch route if current location significantly changes and it is an active trip
            if tripOverride == nil {
                Task { await loadRouteData() }
            }
        }
    }
    
    private var tripStatusText: String {
        if let trip = tripOverride {
            return "Trip Completed on \(trip.date ?? "Past")"
        }
        if let trip = vehicle.currentTrip {
            switch trip.status {
            case .scheduled: return "Scheduled: \(trip.origin) to \(trip.destination)"
            case .inTransit: return "\(vehicle.id) is currently In Transit"
            case .completed: return "Trip Completed"
            }
        }
        return "Vehicle is currently Idle"
    }
    
    private func loadRouteData() async {
        guard let trip = displayTrip, !isLoadingRoute else { return }
        
        isLoadingRoute = true
        routeError = nil
        
        // If the trip already has precise coordinates and polyline saved (from Trip Creation), use them!
        if let polyline = trip.encodedPolyline, let oCoord = trip.originCoordinate, let dCoord = trip.destCoordinate {
            await MainActor.run {
                self.encodedPolyline = polyline
                self.originCoord = oCoord
                self.destCoord = dCoord
                self.originName = trip.origin
                self.destName = trip.destination
                self.apiEta = trip.duration ?? "TBD"
                self.apiDistance = trip.distance ?? "TBD"
                self.isLoadingRoute = false
            }
            return
        }
        
        do {
            let result: FleetDirectionsResult
            
            // Fallback for older mock trips
            if tripOverride == nil {
                result = try await FleetDirectionsService.shared.fetchDirections(
                    origin: "Bangalore",
                    destination: "Coorg",
                    waypointCoord: locationManager.lastLocation
                )
            } else {
                result = try await FleetDirectionsService.shared.fetchDirections(
                    origin: trip.origin,
                    destination: trip.destination
                )
            }
            
            await MainActor.run {
                self.encodedPolyline = result.polyline
                self.apiEta = result.eta
                self.apiDistance = result.distance
                self.originCoord = result.originCoord
                self.destCoord = result.destCoord
                self.originName = result.originName
                self.destName = result.destName
                self.isLoadingRoute = false
            }
        } catch {
            await MainActor.run {
                self.routeError = "Route unavailable: \(error.localizedDescription)"
                self.isLoadingRoute = false
                print("Route fetch error: \(error.localizedDescription)")
            }
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
                                .frame(width: 50) // Fixed width for arrow connector to keep alignment stable
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(AppColors.primary)
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    // Right Side
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(destLabel.uppercased())
                            .font(AppFonts.caption2)
                            .foregroundColor(.gray)
                        Text(destValue)
                            .font(AppFonts.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primary)
                            .multilineTextAlignment(.trailing)
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
