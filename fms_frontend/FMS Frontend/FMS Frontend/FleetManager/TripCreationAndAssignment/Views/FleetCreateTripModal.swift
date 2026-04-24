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
    @State private var loadUnit: String = "Tons"
    
    private let unitOptions = ["Tons", "KG", "Liters", "Units", "Pallets"]
    
    @State private var estimatedCost: Double = 0.0
    @State private var estimatedDistance: Double = 0.0
    @State private var estimatedDuration: Double = 0.0
    
    // Enterprise Constants
    private let baseFee: Double = 1500.0 // INR
    private let ratePerKM: Double = 18.0 // INR
    private let hourlyRate: Double = 250.0 // INR
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Location Details")) {
                    Button(action: { showingSourcePicker = true }) {
                        HStack {
                            Text("Source Location")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(sourceLocation?.name ?? "Tap to select")
                                .foregroundColor(sourceLocation == nil ? .gray : AppColors.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    
                    Button(action: { showingDestinationPicker = true }) {
                        HStack {
                            Text("Destination Location")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(destinationLocation?.name ?? "Tap to select")
                                .foregroundColor(destinationLocation == nil ? .gray : AppColors.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
                
                Section(header: Text("Cargo Details")) {
                    TextField("Product Type (e.g. Steel Coils)", text: $productName)
                    
                    HStack {
                        TextField("Amount", text: $loadAmount)
                            .keyboardType(.decimalPad)
                        
                        Divider()
                            .frame(height: 20)
                        
                        Picker("Unit", selection: $loadUnit) {
                            ForEach(unitOptions, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section(header: Text("Assignment")) {
                    Picker("Vehicle", selection: $selectedVehicleID) {
                        Text("Select Vehicle").tag("")
                        ForEach(dataManager.vehicles.filter { $0.status == .idle }) { vehicle in
                            Text("\(vehicle.id) - \(vehicle.model)").tag(vehicle.id)
                        }
                    }
                    
                    Picker("Driver", selection: $selectedDriverID) {
                        Text("Select Driver").tag("")
                        ForEach(dataManager.drivers.filter { $0.status == .active }) { driver in
                            Text(driver.name).tag(driver.id)
                        }
                    }
                }
                
                Section(header: Text("Schedule")) {
                    DatePicker("Departure Time", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                if estimatedCost > 0 || isCalculatingRoute {
                    Section(header: Text("Cost Estimation (INR)")) {
                        if isCalculatingRoute {
                            HStack {
                                Spacer()
                                ProgressView("Calculating route...")
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Estimated Cost")
                                        .font(AppFonts.caption1)
                                        .foregroundColor(.gray)
                                    Text("₹\(String(format: "%.2f", estimatedCost))")
                                        .font(AppFonts.headline)
                                        .foregroundColor(AppColors.primary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(Int(estimatedDistance)) km")
                                        .font(AppFonts.headline)
                                    Text("Est. \(Int(estimatedDuration)) hrs")
                                        .font(AppFonts.caption1)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        createTrip()
                    }) {
                        Text("Create Trip")
                            .font(AppFonts.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(canCreate ? AppColors.primary : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!canCreate)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .sheet(isPresented: $showingSourcePicker) {
            LocationPickerSheet(title: "Select Source", selectedLocation: $sourceLocation)
        }
        .sheet(isPresented: $showingDestinationPicker) {
            LocationPickerSheet(title: "Select Destination", selectedLocation: $destinationLocation)
        }
        .onChange(of: sourceLocation) { _, _ in fetchRealRoute() }
        .onChange(of: destinationLocation) { _, _ in fetchRealRoute() }
    }
    
    private var canCreate: Bool {
        sourceLocation != nil && destinationLocation != nil && !selectedVehicleID.isEmpty && !selectedDriverID.isEmpty
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
                
                // Parse distance and duration to numbers for cost calculation
                // Distance string like "32.4 km"
                let distStr = result.distance.replacingOccurrences(of: " km", with: "").replacingOccurrences(of: ",", with: "")
                let dist = Double(distStr) ?? 50.0
                
                // Duration string like "45 mins" or "2 hours 15 mins"
                var hours = 0.0
                let durationParts = result.eta.components(separatedBy: " ")
                if result.eta.contains("hour") {
                    if let hrIndex = durationParts.firstIndex(where: { $0.contains("hour") }), hrIndex > 0 {
                        hours += Double(durationParts[hrIndex - 1]) ?? 0.0
                    }
                    if let minIndex = durationParts.firstIndex(where: { $0.contains("min") }), minIndex > 0 {
                        hours += (Double(durationParts[minIndex - 1]) ?? 0.0) / 60.0
                    }
                } else if let minIndex = durationParts.firstIndex(where: { $0.contains("min") }), minIndex > 0 {
                    hours += (Double(durationParts[minIndex - 1]) ?? 0.0) / 60.0
                }
                if hours == 0 { hours = dist / 60.0 } // fallback
                
                await MainActor.run {
                    self.estimatedDistance = dist
                    self.estimatedDuration = hours
                    self.estimatedCost = baseFee + (dist * ratePerKM) + (hours * hourlyRate)
                    self.isCalculatingRoute = false
                }
            } catch {
                await MainActor.run {
                    print("Route fetch error: \(error)")
                    // Fallback to mock if API fails
                    let dist = 100.0
                    let hours = dist / 60.0
                    self.estimatedDistance = dist
                    self.estimatedDuration = hours
                    self.estimatedCost = baseFee + (dist * ratePerKM) + (hours * hourlyRate)
                    self.isCalculatingRoute = false
                }
            }
        }
    }
    
    private func createTrip() {
        guard let src = sourceLocation, let dst = destinationLocation else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let newTrip = VehicleTrip(
            vehicleID: selectedVehicleID,
            origin: src.name,
            destination: dst.name,
            progress: 0.0,
            eta: formatter.string(from: scheduledDate.addingTimeInterval(estimatedDuration * 3600)),
            date: "Today",
            distance: "\(Int(estimatedDistance)) KM",
            duration: "\(Int(estimatedDuration)) HRS",
            costEstimate: "₹\(String(format: "%.2f", estimatedCost))",
            startTime: Date(),
            status: .scheduled,
            productType: productName,
            loadAmount: "\(loadAmount) \(loadUnit)"
        )
        
        if let vIndex = dataManager.vehicles.firstIndex(where: { $0.id == selectedVehicleID }) {
            dataManager.vehicles[vIndex].currentTrip = newTrip
            dataManager.vehicles[vIndex].status = .inTransit
        }
        
        isPresented = false
    }
}
