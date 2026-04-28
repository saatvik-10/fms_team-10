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
    @State private var scheduledDate: Date = Date()
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
            Form {
                Section(header: Text("Location Details")) {
                    Button(action: { showingSourcePicker = true }) {
                        HStack {
                            Text("Source Location")
                            Spacer()
                            Text(sourceLocation?.name ?? "Tap to select")
                                .foregroundColor(sourceLocation == nil ? .gray : AppColors.primary)
                                .lineLimit(1)
                        }
                    }
                    
                    Button(action: { showingDestinationPicker = true }) {
                        HStack {
                            Text("Destination Location")
                            Spacer()
                            Text(destinationLocation?.name ?? "Tap to select")
                                .foregroundColor(destinationLocation == nil ? .gray : AppColors.primary)
                                .lineLimit(1)
                        }
                    }
                    
                    // ✅ Geofence Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Geofence Radius")
                            Spacer()
                            Text("\(Int(geofenceRadius)) m")
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.primary)
                        }
                        
                        Slider(value: $geofenceRadius, in: 100...5000, step: 100)
                        
                        Text("Triggers alerts when entering/exiting this zone.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Cargo Details"), footer: Text("Enter total cargo weight in kg or tons.")) {
                    TextField("Product Type", text: $productName)
                    
                    HStack {
                        TextField("Amount", text: $loadAmount)
                            .keyboardType(.decimalPad)
                            .onChange(of: loadAmount) { oldValue, newValue in
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                if filtered != newValue {
                                    loadAmount = filtered
                                }
                            }
                        
                        Divider().frame(height: 20)
                        
                        Picker("Unit", selection: $loadUnit) {
                            ForEach(unitOptions, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section(header: Text("Assignment")) {
                    Picker("Vehicle", selection: $selectedVehicleID) {
                        Text("Select Vehicle").tag("")
                        ForEach(dataManager.vehicles.filter { v in
                            let amount = Double(loadAmount) ?? 0
                            let weightInKG = convertToKG(amount: amount, unit: loadUnit)
                            return v.status == .idle && weightInKG <= v.capacityInKG
                        }) { v in
                            Text("\(v.model) (Max: \(Int(v.maxLoadCapacity)) \(v.capacityUnit))").tag(v.backendId ?? v.id)
                        }
                    }
                    
                    Picker("Driver", selection: $selectedDriverID) {
                        Text("Select Driver").tag("")
                        Text("Auto Assign (Random)").tag("AUTO_ASSIGN")
                        ForEach(dataManager.drivers.filter { $0.status == .active }) { d in
                            Text(d.name).tag(d.backendId ?? d.id)
                        }
                    }
                }
                
                Section(header: Text("Schedule")) {
                    DatePicker("Departure Time", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                if estimatedCost > 0 || isCalculatingRoute {
                    Section(header: Text("Cost Estimation")) {
                        if isCalculatingRoute {
                            ProgressView("Calculating...")
                        } else {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("₹\(String(format: "%.2f", estimatedCost))")
                                        .font(.headline)
                                        .foregroundColor(AppColors.primary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(Int(estimatedDistance)) km")
                                    Text("\(Int(estimatedDuration)) hrs")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: { createTrip() }) {
                        Text("Create Trip")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.bold)
                            .foregroundColor(canCreate ? .white : .gray)
                    }
                    .listRowBackground(canCreate ? AppTheme.primary : Color(.systemGroupedBackground))
                    .disabled(!canCreate)
                }
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
                
                let dist = Double(result.distance.replacingOccurrences(of: " km", with: "")) ?? 50
                let hours = dist / 60
                
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
                try? await dataManager.refreshVehicles()
                try? await dataManager.refreshDrivers()
                isPresented = false
            } catch {
                print(error)
            }
        }
    }
}
