import SwiftUI
import MapKit

struct FleetTripDetailView: View {
    @Binding var vehicle: Vehicle
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
                    
                    Text("Trip Details")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                    
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
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Map View
                        Map(coordinateRegion: $region)
                            .frame(height: 300)
                            .cornerRadius(16)
                            .overlay(
                                VStack {
                                    Spacer()
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(AppColors.primary)
                                            .clipShape(Circle())
                                        Text("TRK-9042 is on Highway 44")
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.white)
                                            .cornerRadius(20)
                                    }
                                    .padding(.bottom, 20)
                                }
                            )
                        
                        // MARK: - Details Section
                        if let trip = vehicle.currentTrip {
                            HStack(spacing: 15) {
                                // Vehicle Card
                                NavigationLink(destination: FleetManagerVehicleDetailView(vehicle: vehicle)) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text("Vehicle")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Image(vehicle.imageName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 40)
                                        
                                        Text(vehicle.id)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(AppColors.primary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Driver Card
                                if let driver = vehicle.assignedDriver {
                                    NavigationLink(destination: DriverDetailView(driver: driver)) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack {
                                                Text("Driver")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.gray)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Image(systemName: "person.crop.circle.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(AppColors.primary.opacity(0.2))
                                            
                                            Text(driver.name)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(AppColors.primary)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // Route Details
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Route Information")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppColors.primary)
                                
                                VStack(spacing: 20) {
                                    RoutePointView(title: "Source", location: trip.origin, time: "Start", image: "mappin.circle.fill", color: .green, isEditable: canEditSource, text: $source)
                                    
                                    RoutePointView(title: "Destination", location: trip.destination, time: trip.eta, image: "mappin.circle.fill", color: .red, isEditable: true, text: $destination)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
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
    
    private var canEditSource: Bool {
        guard let trip = vehicle.currentTrip else { return false }
        return trip.progress == 0 // Only editable if trip hasn't started
    }
}

struct RoutePointView: View {
    let title: String
    let location: String
    let time: String
    let image: String
    let color: Color
    let isEditable: Bool
    @Binding var text: String
    
    @State private var isEditingLocal: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            VStack {
                Image(systemName: image)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                
                if title == "Source" {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 2, height: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                
                if isEditable && isEditingLocal {
                    TextField("Enter location", text: $text, onCommit: { isEditingLocal = false })
                        .font(.system(size: 16, weight: .semibold))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    HStack {
                        Text(text.isEmpty ? location : text)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                        
                        if isEditable {
                            Button(action: { isEditingLocal = true }) {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Text(time)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}
