import SwiftUI

struct FleetCreateTripModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dataManager: FleetDataManager
    
    @State private var sourceLocation: PickedLocation? = nil
    @State private var destinationLocation: PickedLocation? = nil
    
    @State private var showingSourcePicker = false
    @State private var showingDestinationPicker = false
    @State private var isCalculatingRoute = false
    
    @State private var selectedVehicleID: String = ""
    @State private var selectedDriverID: String = ""
    @State private var scheduledDate: Date = Date().addingTimeInterval(2 * 3600)
    @State private var productName: String = ""
    @State private var loadAmount: String = ""
    @State private var loadUnit: String = "KG"
    
    private let unitOptions = ["KG", "Tons"]
    
    @State private var estimatedCost: Double = 0.0
    @State private var estimatedDistance: Double = 0.0
    @State private var estimatedDuration: Double = 0.0
    
    // ✅ NEW: Geofence
    @State private var geofenceRadius: Double = 500
    
    // Enterprise Constants
    private let baseFee: Double = 1500.0
    private let ratePerKM: Double = 18.0
    private let hourlyRate: Double = 250.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("LOCATION DETAILS")
                            .font(AppFonts.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        Button(action: { showingSourcePicker = true }) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("SOURCE LOCATION")
                                    .font(AppFonts.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    Text(sourceLocation?.name ?? "Tap to select source")
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(sourceLocation == nil ? .gray : AppTheme.primary)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.primary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        
                        Button(action: { showingDestinationPicker = true }) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("DESTINATION LOCATION")
                                    .font(AppFonts.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    Text(destinationLocation?.name ?? "Tap to select destination")
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(destinationLocation == nil ? .gray : AppTheme.primary)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.primary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("GEOFENCE RADIUS")
                                    .font(AppFonts.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(geofenceRadius)) m")
                                    .font(AppFonts.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.primary)
                            }
                            
                            Slider(value: $geofenceRadius, in: 100...5000, step: 100)
                                .accentColor(AppTheme.primary)
                            
                            Text("Triggers alerts when entering/exiting this zone.")
                                .font(AppFonts.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("CARGO DETAILS")
                            .font(AppFonts.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        ModalFormField(label: "Product Type", text: $productName)
                        
                        HStack(spacing: 15) {
                            ModalFormField(label: "Amount", text: $loadAmount)
                                .frame(maxWidth: .infinity)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("UNIT")
                                    .font(AppFonts.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                
                                Picker("Unit", selection: $loadUnit) {
                                    ForEach(unitOptions, id: \.self) {
                                        Text($0)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(height: 45)
                            }
                            .frame(width: 120)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("ASSIGNMENT")
                            .font(AppFonts.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SELECT VEHICLE")
                                .font(AppFonts.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            Picker("Vehicle", selection: $selectedVehicleID) {
                                Text("Select Vehicle").tag("")
                                ForEach(dataManager.vehicles.filter { v in
                                    let amount = Double(loadAmount) ?? 0
                                    let weightInKG = convertToKG(amount: amount, unit: loadUnit)
                                    return v.status == .idle && (v.capacityInKG <= 0 || weightInKG <= v.capacityInKG)
                                }) { v in
                                    let capacityText = v.maxLoadCapacity > 0 ? " (Max: \(Int(v.maxLoadCapacity)) \(v.capacityUnit))" : ""
                                    Text("\(v.model)\(capacityText)").tag(v.backendId ?? v.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SELECT DRIVER")
                                .font(AppFonts.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            Picker("Driver", selection: $selectedDriverID) {
                                Text("Select Driver").tag("")
                                Text("Auto Assign (Random)").tag("AUTO_ASSIGN")
                                ForEach(dataManager.drivers.filter { $0.status == .active }) { d in
                                    Text(d.name).tag(d.backendId ?? d.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("SCHEDULE")
                            .font(AppFonts.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        DatePicker("Departure Time", selection: $scheduledDate, in: Date().addingTimeInterval(2 * 3600)..., displayedComponents: [.date, .hourAndMinute])
                            .font(AppFonts.subheadline)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    if estimatedCost > 0 || isCalculatingRoute {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("COST ESTIMATION")
                                .font(AppFonts.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            if isCalculatingRoute {
                                ProgressView("Calculating...")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                            } else {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("₹\(String(format: "%.2f", estimatedCost))")
                                            .font(AppFonts.title3)
                                            .foregroundColor(AppTheme.primary)
                                        Text("Total Estimated Fee")
                                            .font(AppFonts.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("\(Int(estimatedDistance)) km")
                                            .font(AppFonts.headline)
                                        Text(formatDuration(estimatedDuration))
                                            .font(AppFonts.caption1)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(AppTheme.primary.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.primary.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                .padding(25)
                .padding(.bottom, 100)
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: createTrip) {
                    Text("Create Trip")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.bold)
                        .padding()
                        .foregroundColor(canCreate ? .white : .gray)
                        .background(canCreate ? AppTheme.primary : Color(.systemGray4))
                        .cornerRadius(12)
                }
                .disabled(!canCreate)
                .padding()
                .background(Color.white.shadow(color: Color.black.opacity(0.05), radius: 5, y: -5))
            }
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .sheet(isPresented: $showingSourcePicker) {
            LocationPickerSheet(
                title: "Select Source",
                selectedLocation: $sourceLocation,
                geofenceRadius: geofenceRadius
            )
        }
        .sheet(isPresented: $showingDestinationPicker) {
            LocationPickerSheet(
                title: "Select Destination",
                selectedLocation: $destinationLocation,
                geofenceRadius: geofenceRadius
            )
        }
        .onChange(of: sourceLocation) { _, _ in fetchRealRoute() }
        .onChange(of: destinationLocation) { _, _ in fetchRealRoute() }
    }
    
    private var canCreate: Bool {
        sourceLocation != nil &&
        destinationLocation != nil &&
        !selectedVehicleID.isEmpty &&
        !selectedDriverID.isEmpty &&
        !productName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !(Double(loadAmount) ?? 0 <= 0) &&
        !loadAmount.isEmpty
    }
    
    private func convertToKG(amount: Double, unit: String) -> Double {
        switch unit {
        case "Tons": return amount * 1000.0
        case "KG": return amount
        default: return amount
        }
    }
    
    private func formatDuration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 {
            return "\(h) hrs \(m) mins"
        } else {
            return "\(m) mins"
        }
    }
    
    private func fetchRealRoute() {
        guard let src = sourceLocation, let dst = destinationLocation else {
            estimatedCost = 0
            return
        }
        
        isCalculatingRoute = true
        
        Task {
            do {
                let result = try await FleetDirectionsService.shared.fetchDirections(
                    originCoord: src.coordinate,
                    destCoord: dst.coordinate,
                    originName: src.name,
                    destName: dst.name
                )
                
                let distStr = result.distance
                    .replacingOccurrences(of: " km", with: "")
                    .replacingOccurrences(of: ",", with: "")
                let dist = Double(distStr) ?? 50.0
                
                let drivingHours = dist / 60.0 // Assume 60km/h avg
                // Logic: 45 min break for every 4 hours. 8 hours driving = 2 breaks = 90 mins = 9.5h total.
                let breaks = floor(drivingHours / 4.0)
                let hours = drivingHours + (breaks * 0.75)
                
                await MainActor.run {
                    estimatedDistance = dist
                    estimatedDuration = hours
                    estimatedCost = baseFee + (dist * ratePerKM) + (hours * hourlyRate)
                    isCalculatingRoute = false
                }
            } catch {
                isCalculatingRoute = false
            }
        }
    }
    
    private func createTrip() {
        guard let src = sourceLocation, let dst = destinationLocation else { return }
        
        var finalDriverID = selectedDriverID
        if finalDriverID == "AUTO_ASSIGN" {
            let activeDrivers = dataManager.drivers.filter { $0.status == .active }
            finalDriverID = activeDrivers.randomElement()?.backendId ?? activeDrivers.randomElement()?.id ?? ""
        }
        
        let request = CreateTripRequest(
            sourceLocation: src.name,
            destinationLocation: dst.name,
            productType: productName,
            unit: loadUnit,
            amount: Int(Double(loadAmount) ?? 0),
            vehicle: selectedVehicleID,
            driver: finalDriverID,
            departureTime: ISO8601DateFormatter().string(from: scheduledDate),
            distance: "\(estimatedDistance) km"
        )
        
        Task {
            do {
                _ = try await TripAPI.shared.createTrip(request)
                
                await MainActor.run {
                    if let vIndex = dataManager.vehicles.firstIndex(where: { $0.id == selectedVehicleID || $0.backendId == selectedVehicleID }) {
                        dataManager.vehicles[vIndex].status = .inTransit
                    }
                    
                    if let dIndex = dataManager.drivers.firstIndex(where: { $0.id == finalDriverID || $0.backendId == finalDriverID }) {
                        // Create a modified copy of the driver
                        var updatedDriver = dataManager.drivers[dIndex]
                        // We can't directly mutate status if it's a let, we should check if it's var.
                        // For now, let's just refresh from backend to ensure data consistency.
                    }
                }
                
                try? await dataManager.refreshVehicles()
                try? await dataManager.refreshDrivers()
                isPresented = false
            } catch {
                print(error)
            }
        }
    }
}
