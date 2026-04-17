import MapKit
import SwiftUI
import Combine

// MARK: - Premium Modal Components

struct OCRUploadArea: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.primary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Button(action: action) {
                HStack {
                    Image(systemName: "plus")
                    Text(buttonTitle)
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(AppTheme.primary)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(Color.gray.opacity(0.4))
        )
    }
}

struct ModalFormField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            
            HStack {
                TextField("", text: $text)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Image(systemName: "pencil")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

struct ModalSearchField: View {
    let label: String
    @Binding var text: String
    @StateObject private var completer = LocationSearchCompleter()
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search location...", text: $text, onEditingChanged: { editing in
                        isEditing = editing
                        if editing { completer.searchQuery = text }
                    })
                    .onChange(of: text) { newValue in
                        completer.searchQuery = newValue
                    }
                    .font(.system(size: 15, weight: .medium))
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                if isEditing && !completer.completions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(completer.completions, id: \.title) { completion in
                                Button(action: {
                                    text = "\(completion.title), \(completion.subtitle)"
                                    isEditing = false
                                    // hide keyboard
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }) {
                                    VStack(alignment: .leading) {
                                        Text(completion.title).font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                                        if !completion.subtitle.isEmpty {
                                            Text(completion.subtitle).font(.system(size: 12)).foregroundColor(.gray)
                                        }
                                        Divider()
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .background(Color.white)
                    .cornerRadius(10)
                    .modifier(AppTheme.cardShadow())
                    .offset(y: 5)
                }
            }
            .zIndex(isEditing ? 1 : 0)
        }
    }
}

// MARK: - Add Driver Modal (MATCH IMAGE)
struct DriverModalView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @Environment(\.dismiss) var dismiss
    @State private var fullName = ""
    @State private var licenseNumber = ""
    @State private var expiryDate = ""
    @State private var vehicleClasses = ""
    @State private var showingScanner = false



    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header
            HStack {
                Text("Add Driver")
                    .font(.system(size: 28, weight: .bold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
            }
            .padding(.top, 10)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // Section 1: License Verification
                    VStack(alignment: .leading, spacing: 15) {
                        Text("LICENSE VERIFICATION")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        
                        OCRUploadArea(
                            title: "Upload Driver License",
                            subtitle: "Drag and drop or tap to scan document",
                            buttonTitle: "Upload License",
                            action: { showingScanner = true }
                        )
                    }
                    
                    // Section 2: Review Details
                    VStack(alignment: .leading, spacing: 20) {
                        Text("REVIEW DRIVER DETAILS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            ModalFormField(label: "Full Name", text: $fullName)
                            ModalFormField(label: "License Number", text: $licenseNumber)
                        }
                        
                        HStack(spacing: 20) {
                            ModalFormField(label: "Expiry Date", text: $expiryDate)
                            ModalFormField(label: "Vehicle Classes", text: $vehicleClasses)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            
            // Footer Buttons
            HStack(spacing: 15) {
                Button(action: { 
                    let newDriver = Driver(id: "NEW-\(Int.random(in: 1000...9999))", name: fullName, title: "Driver", licenseNum: licenseNumber, licenseExp: expiryDate, status: .offDuty, rating: 5.0, efficiency: "100%", totalTrips: 0, totalHours: 0, activityLog: [], currentVehicleID: nil, activeRoute: nil, eta: nil)
                    dataManager.addDriver(newDriver)
                    dismiss() 
                }) {
                    HStack {
                        Text("Save Driver")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.primary)
                    .cornerRadius(12)
                }
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 18)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding(30)
        .background(Color.white)
        .sheet(isPresented: $showingScanner) {
            CameraScannerView(isPresented: $showingScanner) { name, id, date, classes in
                self.fullName = name
                self.licenseNumber = id
                self.expiryDate = date
                self.vehicleClasses = classes
            }
        }
    }
}

// MARK: - Add Vehicle Modal (MATCH IMAGE)
struct AddVehicleModalView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @Environment(\.dismiss) var dismiss
    let vehicleToEdit: Vehicle?
    
    @State private var make: String
    @State private var model: String
    @State private var regNumber: String
    @State private var vin: String
    @State private var odometer: String
    @State private var showingScanner = false



    
    init(vehicleToEdit: Vehicle? = nil) {
        self.vehicleToEdit = vehicleToEdit
        _make = State(initialValue: vehicleToEdit?.make ?? "")
        _model = State(initialValue: vehicleToEdit?.model ?? "")
        _regNumber = State(initialValue: vehicleToEdit?.id ?? "")
        _vin = State(initialValue: "4G2BM5...")
        _odometer = State(initialValue: vehicleToEdit?.odometer ?? "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Header
            HStack {
                Text(vehicleToEdit == nil ? "Add Vehicle" : "Update Vehicle")
                    .font(.system(size: 28, weight: .bold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
            }
            .padding(.top, 10)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // Section 1: RC Verification
                    VStack(alignment: .leading, spacing: 15) {
                        Text("VEHICLE REGISTRATION (RC) VERIFICATION")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        
                        OCRUploadArea(
                            title: "Upload RC Document",
                            subtitle: "Drag and drop or tap to scan document",
                            buttonTitle: "Upload Document",
                            action: { showingScanner = true }
                        )
                    }
                    
                    // Section 2: Review Details
                    VStack(alignment: .leading, spacing: 20) {
                        Text("REVIEW VEHICLE DETAILS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            ModalFormField(label: "Vehicle Make", text: $make)
                            ModalFormField(label: "Vehicle Model", text: $model)
                        }
                        
                        HStack(spacing: 20) {
                            ModalFormField(label: "Registration Number", text: $regNumber)
                            ModalFormField(label: "Chassis Number / VIN", text: $vin)
                        }
                        
                        ModalFormField(label: "Total Odometer Run (MI)", text: $odometer)
                    }
                }
                .padding(.bottom, 30)
            }
            
            // Footer Buttons
            HStack(spacing: 15) {
                Button(action: { 
                    let newVehicle = Vehicle(id: regNumber, make: make, model: model, type: "Truck", status: .idle, imageName: "truck_freightliner_m2", year: "2024", color: "White", odometer: odometer, operationalStatus: "OPERATIONAL", currentTrip: nil, assignedDriver: nil, maintenance: VehicleMaintenance(nextService: "TBD", inspectionStatus: "Verified", alerts: []), history: [], reports: [], assessmentReason: nil)
                    dataManager.addVehicle(newVehicle)
                    dismiss() 
                }) {
                    HStack {
                        Text("Save Vehicle")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.primary)
                    .cornerRadius(12)
                }
                
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 18)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding(30)
        .background(Color.white)
        .sheet(isPresented: $showingScanner) {
            CameraScannerView(isPresented: $showingScanner) { make, model, reg, vin in
                self.make = "TATA MOTORS"
                self.model = "PRIMA G.35 K"
                self.regNumber = "MH-12-XY-1234"
                self.vin = "4G2BM5..."
            }
        }
    }
}

// MARK: - New Order / Add Trip Modal (MATCH IMAGE)
struct OrderModalView: View {
    @EnvironmentObject var dataManager: FleetDataManager
    @Environment(\.dismiss) var dismiss
    @State private var fromLocation = ""
    @State private var toLocation = ""
    @State private var selectedVehicleID = ""
    @State private var ownerName = ""
    @State private var phoneNum = ""
    @State private var showingScanner = false

    // Dynamic estimation logic
    private var estimatedDistance: Int {
        if fromLocation.isEmpty && toLocation.isEmpty { return 0 }
        return max(45, (fromLocation.count + toLocation.count) * 12)
    }
    
    private var estimatedCost: Double {
        if estimatedDistance == 0 { return 0.0 }
        return max(75.50, Double(estimatedDistance) * 1.5 + 25.0)
    }

    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Text("New Order")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Button("Create") { dismiss() }
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(25)
            .foregroundColor(AppTheme.primary)
            .background(Color.white)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // 1. Route Details
                    VStack(alignment: .leading, spacing: 15) {
                        Label("ROUTE DETAILS", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            .font(.system(size: 14, weight: .bold))
                        
                        HStack(spacing: 20) {
                            ModalSearchField(label: "FROM", text: $fromLocation)
                            ModalSearchField(label: "TO", text: $toLocation)
                        }
                    }
                    
                    // 2. Vehicle Assignment
                    VStack(alignment: .leading, spacing: 15) {
                        Label("VEHICLE ASSIGNMENT", systemImage: "truck.box.fill")
                            .font(.system(size: 14, weight: .bold))
                        
                        Text("SELECTED VEHICLE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        
                        Menu {
                            ForEach(dataManager.vehicles) { vehicle in
                                Button(action: {
                                    selectedVehicleID = vehicle.id
                                }) {
                                    Text("\(vehicle.id) - \(vehicle.make)")
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "truck.box.fill")
                                    .padding()
                                    .background(AppTheme.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading) {
                                    Text(selectedVehicleID.isEmpty ? "Tap to select vehicle" : selectedVehicleID)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(selectedVehicleID.isEmpty ? .gray : AppTheme.textPrimary)
                                    Text("Available for dispatch")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    // 3. Contact Details
                    VStack(alignment: .leading, spacing: 15) {
                        Label("CONTACT DETAILS", systemImage: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 14, weight: .bold))
                        
                        ModalFormField(label: "PHONE NUMBER", text: $phoneNum)
                    }
                    
                    // 4. Calculation Card
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ESTIMATED FUEL COST")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text(String(format: "$%.2f", estimatedCost))
                                        .font(.system(size: 38, weight: .black))
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 8) {
                                    Text("Dist: 120mi • 8mpg • ₹3.50/gal")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("CO2 IMPACT")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text("0.42 Tons")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("ETA")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text("2h 45m")
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                        }
                        .padding(30)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    // Bottom Button
                    VStack(spacing: 15) {
                        Button(action: { 
                            let trip = VehicleTrip(origin: fromLocation, destination: toLocation, progress: 0.0, eta: "TBD", date: "Now", distance: "0 mi", duration: "0 hrs")
                            dataManager.addOrder(trip: trip, vehicleID: selectedVehicleID)
                            dismiss() 
                        }) {
                            HStack {
                                Image(systemName: "lock.open.fill")
                                Text("Create Order")
                            }
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(fromLocation.isEmpty || selectedVehicleID.isEmpty ? Color.gray : AppTheme.primary)
                            .cornerRadius(12)
                        }
                        .disabled(fromLocation.isEmpty || selectedVehicleID.isEmpty)
                        
                        Text("Complete all mandatory fields to finalize dispatch")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(30)
            }
        }
        .frame(minWidth: 600, minHeight: 700)
        .background(Color.white)
        .sheet(isPresented: $showingScanner) {
            CameraScannerView(isPresented: $showingScanner) { name, doc, _, _ in
                self.ownerName = name
            }
        }
    }
}



class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions: [MKLocalSearchCompletion] = []
    
    private var completer: MKLocalSearchCompleter
    private var cancellable: AnyCancellable?
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        
        cancellable = $searchQuery.debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] query in
                if query.isEmpty {
                    self?.completions = []
                } else {
                    self?.completer.queryFragment = query
                }
            }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle error
    }
}
