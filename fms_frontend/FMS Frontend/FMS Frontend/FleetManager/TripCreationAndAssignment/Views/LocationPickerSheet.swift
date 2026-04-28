import SwiftUI
import GoogleMaps
import CoreLocation
import MapKit

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - Models

struct PickedLocation: Equatable {
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: PickedLocation, rhs: PickedLocation) -> Bool {
        return lhs.name == rhs.name &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct PlaceSuggestion: Identifiable {
    let id = UUID()
    let primaryText: String
    let secondaryText: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - LocationPickerSheet

struct LocationPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let title: String
    @Binding var selectedLocation: PickedLocation?
    var geofenceRadius: Double = 1000.0 // Default 1km
    
    @State private var searchQuery: String = ""
    @State private var suggestions: [PlaceSuggestion] = []
    
    // Default to New Delhi coordinates
    @State private var mapCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090)
    @State private var isMapMoving: Bool = false
    
    @State private var selectedPlaceName: String = "Fetching location..."
    
    // Prevent reverse geocoding when map moves due to an autocomplete selection
    @State private var isProgrammaticMove: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search for a place...", text: $searchQuery)
                            .onChange(of: searchQuery) { _, newValue in
                                fetchSuggestions(for: newValue)
                            }
                        if !searchQuery.isEmpty {
                            Button(action: {
                                searchQuery = ""
                                suggestions = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.white)
                .zIndex(3)
                
                // Map Area with Overlay Suggestions
                ZStack(alignment: .top) {
                    LocationPickerMapView(coordinate: $mapCoordinate, isMoving: $isMapMoving, isSource: title.contains("Source"), geofenceRadius: geofenceRadius)
                        .edgesIgnoringSafeArea(.bottom)
                        .onChange(of: mapCoordinate) { _, newCoord in
                            if !isProgrammaticMove {
                                reverseGeocode(coordinate: newCoord)
                            }
                        }
                        .onChange(of: isMapMoving) { _, moving in
                            if !moving && isProgrammaticMove {
                                isProgrammaticMove = false // Reset after move completes
                            }
                        }
                    
                    // Fixed Center Pin
                    VStack {
                        Spacer()
                        Image(systemName: "mappin")
                            .font(.system(size: 45))
                            .foregroundColor(.red)
                            .shadow(radius: 3)
                            .padding(.bottom, 45) // Offset to make the pin point to center
                        Spacer()
                    }
                    
                    if isMapMoving {
                        Color.white.opacity(0.1) // Slight indicator
                    }
                    
                    // Suggestions List (Overlay)
                    if !suggestions.isEmpty {
                        List(suggestions) { suggestion in
                            Button(action: {
                                selectSuggestion(suggestion)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(suggestion.primaryText)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    if !suggestion.secondaryText.isEmpty {
                                        Text(suggestion.secondaryText)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .listStyle(.plain)
                        .frame(maxHeight: 250)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .zIndex(2)
                    }
                }
                .zIndex(1)
                
                // Bottom Confirmation Bar
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        
                        Text(selectedPlaceName)
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                    
                    Button(action: {
                        selectedLocation = PickedLocation(name: selectedPlaceName, coordinate: mapCoordinate)
                        dismiss()
                    }) {
                        Text("Confirm Location")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 10/255, green: 48/255, blue: 58/255)) // AppColors.primary
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white)
                .shadow(radius: 5)
                .zIndex(2)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                // Initial reverse geocode if needed
                reverseGeocode(coordinate: mapCoordinate)
            }
        }
    }
    
    // MARK: - Native MapKit Implementations
    
    private func fetchSuggestions(for query: String) {
        guard query.count > 0, query != selectedPlaceName else {
            suggestions = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        
        Task {
            do {
                let response = try await search.start()
                await MainActor.run {
                    self.suggestions = response.mapItems.map { item in
                        PlaceSuggestion(
                            primaryText: item.name ?? "Unknown Place",
                            secondaryText: item.placemark.title ?? "",
                            coordinate: item.placemark.coordinate
                        )
                    }
                }
            } catch {
                print("Search error: \(error)")
                await MainActor.run { self.suggestions = [] }
            }
        }
    }
    
    private func selectSuggestion(_ suggestion: PlaceSuggestion) {
        let fullName = suggestion.secondaryText.isEmpty ? suggestion.primaryText : suggestion.secondaryText
        self.searchQuery = suggestion.primaryText
        self.selectedPlaceName = fullName
        self.suggestions = []
        self.isProgrammaticMove = true
        self.mapCoordinate = suggestion.coordinate
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    let name = placemark.name ?? ""
                    let locality = placemark.locality ?? ""
                    let adminArea = placemark.administrativeArea ?? ""
                    let country = placemark.country ?? ""
                    
                    var components = [String]()
                    if !name.isEmpty { components.append(name) }
                    if !locality.isEmpty && locality != name { components.append(locality) }
                    if !adminArea.isEmpty && adminArea != locality && adminArea != name { components.append(adminArea) }
                    if !country.isEmpty { components.append(country) }
                    
                    let address = components.joined(separator: ", ")
                    
                    await MainActor.run {
                        self.selectedPlaceName = address.isEmpty ? "Unknown Location" : address
                        // Only update search bar if it already has content (user typing) or is non-initial
                        // This prevents pre-filling "Kartavya Path" on the very first load.
                        if !self.searchQuery.isEmpty {
                            self.searchQuery = name.isEmpty ? address : name
                        }
                    }
                } else {
                    await MainActor.run {
                        self.selectedPlaceName = "Unknown Location"
                    }
                }
            } catch {
                print("Reverse geocode error: \(error)")
                await MainActor.run {
                    self.selectedPlaceName = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                }
            }
        }
    }
}

// MARK: - LocationPickerMapView

struct LocationPickerMapView: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var isMoving: Bool
    var isSource: Bool = true
    var geofenceRadius: Double = 1000.0
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 14)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.delegate = context.coordinator
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        
        let circle = GMSCircle(position: coordinate, radius: geofenceRadius)
        let circleColor = isSource ? UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1) : UIColor(red: 10/255, green: 48/255, blue: 58/255, alpha: 1)
        circle.fillColor = circleColor.withAlphaComponent(0.2)
        circle.strokeColor = circleColor.withAlphaComponent(0.8)
        circle.strokeWidth = 2
        circle.map = mapView
        context.coordinator.geofenceCircle = circle
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Only update camera if we are not actively dragging it
        if !context.coordinator.isUserDragging {
            let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: uiView.camera.zoom)
            uiView.animate(to: camera)
            context.coordinator.geofenceCircle?.position = coordinate
        }
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: LocationPickerMapView
        var isUserDragging: Bool = false
        var geofenceCircle: GMSCircle?
        
        init(_ parent: LocationPickerMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            isUserDragging = gesture
            if gesture {
                parent.isMoving = true
            }
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            geofenceCircle?.position = position.target
        }
        
        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            isUserDragging = false
            parent.isMoving = false
            geofenceCircle?.position = position.target
            // Update the bound coordinate to the new map center
            DispatchQueue.main.async {
                self.parent.coordinate = position.target
            }
        }
    }
}
