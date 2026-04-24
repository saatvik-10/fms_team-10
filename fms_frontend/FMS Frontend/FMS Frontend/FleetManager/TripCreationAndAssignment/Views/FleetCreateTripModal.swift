import SwiftUI

struct FleetCreateTripModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var dataManager: FleetDataManager
    
    @StateObject private var viewModel = FleetCreateTripViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Location Details")) {
                    Button(action: { viewModel.showingSourcePicker = true }) {
                        HStack {
                            Text("Source Location")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(viewModel.sourceLocation?.name ?? "Tap to select")
                                .foregroundColor(viewModel.sourceLocation == nil ? .gray : AppColors.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    
                    Button(action: { viewModel.showingDestinationPicker = true }) {
                        HStack {
                            Text("Destination Location")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(viewModel.destinationLocation?.name ?? "Tap to select")
                                .foregroundColor(viewModel.destinationLocation == nil ? .gray : AppColors.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    
                    // Geofence Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Geofence Radius")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(Int(viewModel.geofenceRadius)) m")
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.primary)
                        }
                        Slider(value: $viewModel.geofenceRadius, in: 100...5000, step: 100)
                            .accentColor(AppColors.primary)
                        Text("Triggers alerts when entering/exiting this zone.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Cargo Details")) {
                    TextField("Product Type (e.g. Steel Coils)", text: $viewModel.productName)
                    
                    HStack {
                        TextField("Amount", text: $viewModel.loadAmount)
                            .keyboardType(.decimalPad)
                        
                        Divider()
                            .frame(height: 20)
                        
                        Picker("Unit", selection: $viewModel.loadUnit) {
                            ForEach(viewModel.unitOptions, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section(header: Text("Assignment")) {
                    Picker("Vehicle", selection: $viewModel.selectedVehicleID) {
                        Text("Select Vehicle").tag("")
                        ForEach(dataManager.vehicles.filter { $0.status == .idle }) { vehicle in
                            Text("\(vehicle.id) - \(vehicle.model)").tag(vehicle.id)
                        }
                    }
                    
                    Picker("Driver", selection: $viewModel.selectedDriverID) {
                        Text("Select Driver").tag("")
                        ForEach(dataManager.drivers.filter { $0.status == .active }) { driver in
                            Text(driver.name).tag(driver.id)
                        }
                    }
                }
                
                Section(header: Text("Schedule")) {
                    DatePicker("Departure Time", selection: $viewModel.scheduledDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                if viewModel.estimatedCost > 0 || viewModel.isCalculatingRoute {
                    Section(header: Text("Cost Estimation (INR)")) {
                        if viewModel.isCalculatingRoute {
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
                                    Text("₹\(String(format: "%.2f", viewModel.estimatedCost))")
                                        .font(AppFonts.headline)
                                        .foregroundColor(AppColors.primary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(Int(viewModel.estimatedDistance)) km")
                                        .font(AppFonts.headline)
                                    Text("Est. \(Int(viewModel.estimatedDuration)) hrs")
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
                        viewModel.createTrip(dataManager: dataManager) {
                            isPresented = false
                        }
                    }) {
                        Text("Create Trip")
                            .font(AppFonts.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(viewModel.canCreate ? AppColors.primary : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!viewModel.canCreate)
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
        .sheet(isPresented: $viewModel.showingSourcePicker) {
            LocationPickerSheet(title: "Select Source", selectedLocation: $viewModel.sourceLocation, geofenceRadius: viewModel.geofenceRadius)
        }
        .sheet(isPresented: $viewModel.showingDestinationPicker) {
            LocationPickerSheet(title: "Select Destination", selectedLocation: $viewModel.destinationLocation, geofenceRadius: viewModel.geofenceRadius)
        }
        .onChange(of: viewModel.sourceLocation) { _, _ in viewModel.fetchRealRoute() }
        .onChange(of: viewModel.destinationLocation) { _, _ in viewModel.fetchRealRoute() }
    }
}
