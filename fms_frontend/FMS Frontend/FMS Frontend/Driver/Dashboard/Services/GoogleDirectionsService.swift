import Foundation
import CoreLocation

// Define the response structures for Google Directions API
struct DirectionsResponse: Codable {
    let routes: [Route]
    let status: String
}

struct Route: Codable {
    let legs: [Leg]
    let overview_polyline: Polyline
}

struct Leg: Codable {
    let duration: DurationItem
}

struct DurationItem: Codable {
    let text: String
    let value: Int
}

struct Polyline: Codable {
    let points: String
}

class GoogleDirectionsService {
    static let shared = GoogleDirectionsService()
    
    // API KEY found in Frontend.swift
    private let apiKey = "AIzaSyBblB9O0UzmpYM8b9MISNVODw3yvxOnD0g"
    
    // Validate coordinate helper
    private func isValidCoordinate(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude != 0.0 && coord.longitude != 0.0 &&
               coord.latitude >= -90 && coord.latitude <= 90 &&
               coord.longitude >= -180 && coord.longitude <= 180
    }
    
    func fetchDirections(trip: Trip) async throws -> (eta: String, polyline: String) {
        print("--- DEBUG Directions API ---")
        
        // 1. Validate Input Data
        if !isValidCoordinate(trip.pickup.coordinate) {
            print("Directions API error: Invalid pickup coordinate (0,0 or out of bounds)")
            throw NSError(domain: "GoogleDirectionsAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid pickup coordinate"])
        }
        if !isValidCoordinate(trip.destination.coordinate) {
            print("Directions API error: Invalid destination coordinate (0,0 or out of bounds)")
            throw NSError(domain: "GoogleDirectionsAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid destination coordinate"])
        }
        for (index, stop) in trip.stops.enumerated() {
            if !isValidCoordinate(stop.coordinate) {
                print("Directions API error: Invalid stop coordinate at index \(index)")
                throw NSError(domain: "GoogleDirectionsAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid stop coordinate"])
            }
        }
        print("Step 1: Input data validated")
        
        // 2 & 3. Validate API Key & Build URL
        if apiKey.isEmpty {
            print("Directions API error: API Key is missing")
            throw NSError(domain: "GoogleDirectionsAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "API Key missing"])
        }
        
        let originParams = "\(trip.pickup.coordinate.latitude),\(trip.pickup.coordinate.longitude)"
        let destParams = "\(trip.destination.coordinate.latitude),\(trip.destination.coordinate.longitude)"
        
        var waypoints = ""
        if !trip.stops.isEmpty {
            // Using via: to avoid splitting into separate legs, or if you need separate legs, remove via:
            let wpStrings = trip.stops.map { "via:\($0.coordinate.latitude),\($0.coordinate.longitude)" }
            waypoints = "&waypoints=" + wpStrings.joined(separator: "|")
        }
        
        // Ensure the URL is properly encoded
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originParams)&destination=\(destParams)\(waypoints)&key=\(apiKey)"
        
        // Use allowed characters for URL query avoiding issues with '|' and other characters
        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString) else {
            print("Directions API error: Failed to construct valid URL")
            throw URLError(.badURL)
        }
        
        print("Step 2: URL Constructed")
        print("Request URL:", encodedURLString)
        
        // 4. Network Call
        let data: Data
        let response: URLResponse
        do {
            let result = try await URLSession.shared.data(from: url)
            data = result.0
            response = result.1
        } catch {
            print("Directions API error:", error.localizedDescription)
            throw error
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response status code:", httpResponse.statusCode)
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON response:", jsonString)
        }
        print("Step 3: Network call successful")

        // 5. JSON Parsing
        let decoder = JSONDecoder()
        let decodedResponse: DirectionsResponse
        do {
            decodedResponse = try decoder.decode(DirectionsResponse.self, from: data)
        } catch {
            print("Directions API error during JSON parsing:", error)
            throw error
        }
        
        if decodedResponse.status != "OK" {
            print("Directions API error: status was \(decodedResponse.status)")
            throw NSError(domain: "GoogleDirectionsAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "API returned status: \(decodedResponse.status)"])
        }
        
        guard let route = decodedResponse.routes.first else {
            print("Directions API error: No routes found in response")
            throw NSError(domain: "GoogleDirectionsAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "No route returned"])
        }
        
        if route.legs.isEmpty {
            print("Directions API error: Route has no legs")
            throw NSError(domain: "GoogleDirectionsAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Route has no legs"])
        }
        
        // Sum the duration values to get total ETA
        var totalDurationSeconds = 0
        for leg in route.legs {
            totalDurationSeconds += leg.duration.value
        }
        
        let hours = totalDurationSeconds / 3600
        let minutes = (totalDurationSeconds % 3600) / 60
        
        let totalDurationText: String
        if hours > 0 {
            totalDurationText = "\(hours) hrs \(minutes) min"
        } else {
            totalDurationText = "\(minutes) min"
        }
        
        print("Step 4: Parsed ETA successfully -> \(totalDurationText)")
        return (eta: totalDurationText, polyline: route.overview_polyline.points)
    }
}
