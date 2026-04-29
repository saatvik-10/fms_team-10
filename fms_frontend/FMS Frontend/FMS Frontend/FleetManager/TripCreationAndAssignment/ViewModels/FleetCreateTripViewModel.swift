import SwiftUI
import CoreLocation
import Combine

@MainActor
class FleetCreateTripViewModel: ObservableObject {
    @Published var sourceLocation: PickedLocation? = nil
    @Published var destinationLocation: PickedLocation? = nil
    
    @Published var showingSourcePicker = false
    @Published var showingDestinationPicker = false
    @Published var isCalculatingRoute = false
    
    @Published var selectedVehicleID: String = ""
    @Published var selectedDriverID: String = ""
    @Published var scheduledDate: Date = Date()
    @Published var productName: String = ""
    @Published var loadAmount: String = ""
    @Published var loadUnit: String = "Tons"
    
    // Geofencing (New)
    @Published var geofenceRadius: Double = 1000.0 // Default 1km
    @Published var encodedPolyline: String = "" // Save polyline for detail view
    
    @Published var estimatedCost: Double = 0.0
    @Published var estimatedDistance: Double = 0.0
    @Published var estimatedDuration: Double = 0.0
    
    let unitOptions = ["Tons", "KG", "Liters", "Units", "Pallets"]
    
    // Enterprise Constants
    private let baseFee: Double = 1500.0 // INR
    private let ratePerKM: Double = 18.0 // INR
    private let hourlyRate: Double = 250.0 // INR
    
    var canCreate: Bool {
        sourceLocation != nil && destinationLocation != nil && !selectedVehicleID.isEmpty && !selectedDriverID.isEmpty
    }
    
    func fetchRealRoute() {
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
                let distStr = result.distance.replacingOccurrences(of: " km", with: "").replacingOccurrences(of: ",", with: "")
                let dist = Double(distStr) ?? 50.0
                
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
                
                self.encodedPolyline = result.polyline
                self.estimatedDistance = dist
                self.estimatedDuration = hours
                self.estimatedCost = baseFee + (dist * ratePerKM) + (hours * hourlyRate)
                self.isCalculatingRoute = false
            } catch {
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
    
    func createTrip(dataManager: FleetDataManager, onCompletion: () -> Void) {
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
            loadAmount: "\(loadAmount) \(loadUnit)",
            geofenceRadius: geofenceRadius,
            originCoordinate: src.coordinate,
            destCoordinate: dst.coordinate,
            encodedPolyline: encodedPolyline
        )
        
        if let vIndex = dataManager.vehicles.firstIndex(where: { $0.id == selectedVehicleID }) {
            dataManager.vehicles[vIndex].currentTrip = newTrip
            dataManager.vehicles[vIndex].status = .inTransit
        }
        
        // Start Geofence Monitoring
        FleetGeofenceManager.shared.startMonitoring(trip: newTrip)
        
        onCompletion()
    }
}
