import SwiftUI

struct FleetCreateTripModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dataManager: FleetDataManager
    
    @State private var source: String = ""
    @State private var destination: String = ""
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
                    ModalSearchField(label: "Source Location", text: $source)
                        .onChange(of: source) { _, _ in calculateCost() }
                    
                    ModalSearchField(label: "Destination Location", text: $destination)
                        .onChange(of: destination) { _, _ in calculateCost() }
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
                
                if estimatedCost > 0 {
                    Section(header: Text("Cost Estimation (INR)")) {
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
    }
    
    private var canCreate: Bool {
        !source.isEmpty && !destination.isEmpty && !selectedVehicleID.isEmpty && !selectedDriverID.isEmpty
    }
    
    private func calculateCost() {
        guard !source.isEmpty && !destination.isEmpty else {
            estimatedCost = 0
            return
        }
        
        // Mock calculation based on string lengths to simulate varied distances
        let seed = Double(source.count + destination.count)
        estimatedDistance = (seed * 15.0).truncatingRemainder(dividingBy: 800) + 50.0
        estimatedDuration = estimatedDistance / 60.0 // Average 60km/h
        
        estimatedCost = baseFee + (estimatedDistance * ratePerKM) + (estimatedDuration * hourlyRate)
    }
    
    private func createTrip() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let newTrip = VehicleTrip(
            vehicleID: selectedVehicleID,
            origin: source,
            destination: destination,
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
