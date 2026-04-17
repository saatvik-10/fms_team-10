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
    
    func fetchDirections(trip: Trip) async throws -> (eta: String, polyline: String) {
        let originParams = "\(trip.pickup.coordinate.latitude),\(trip.pickup.coordinate.longitude)"
        let destParams = "\(trip.destination.coordinate.latitude),\(trip.destination.coordinate.longitude)"
        
        var waypoints = ""
        if !trip.stops.isEmpty {
            let wpStrings = trip.stops.map { "via:\($0.coordinate.latitude),\($0.coordinate.longitude)" }
            waypoints = "&waypoints=" + wpStrings.joined(separator: "|")
        }
        
        // Ensure the URL is properly encoded
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originParams)&destination=\(destParams)\(waypoints)&key=\(apiKey)"
        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(DirectionsResponse.self, from: data)
        
        if response.status != "OK" {
            throw NSError(domain: "GoogleDirectionsAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "API returned status: \(response.status)"])
        }
        
        guard let route = response.routes.first else {
            throw NSError(domain: "GoogleDirectionsAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "No route returned"])
        }
        
        // Sum the duration values to get total ETA
        let totalDurationSeconds = route.legs.reduce(0) { $0 + $1.duration.value }
        
        let hours = totalDurationSeconds / 3600
        let minutes = (totalDurationSeconds % 3600) / 60
        
        let totalDurationText: String
        if hours > 0 {
            totalDurationText = "\(hours) hrs \(minutes) min"
        } else {
            totalDurationText = "\(minutes) min"
        }
        
        return (eta: totalDurationText, polyline: route.overview_polyline.points)
    }
}
