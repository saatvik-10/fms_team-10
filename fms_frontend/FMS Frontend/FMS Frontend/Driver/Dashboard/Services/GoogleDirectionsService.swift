import Foundation
import CoreLocation
internal import UIKit

// MARK: - API Response Models

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
    let distance: DurationItem
    let steps: [DirectionStep]
}

struct DirectionStep: Codable {
    let html_instructions: String
    let distance: DurationItem
    let duration: DurationItem
    let end_location: LocationCoordinate
}

struct LocationCoordinate: Codable {
    let lat: Double
    let lng: Double
}

struct DurationItem: Codable {
    let text: String
    let value: Int
}

struct Polyline: Codable {
    let points: String
}

// MARK: - Clean Navigation Instruction Model

struct NavigationInstruction {
    let instruction: String           // Clean plain text e.g. "Turn right onto MG Road"
    let distanceText: String          // e.g. "300 m" or "1.2 km"
    let fullText: String              // Combined: "Turn right onto MG Road in 300 m"
    let endLocation: CLLocationCoordinate2D
}

// MARK: - Service

class GoogleDirectionsService {
    static let shared = GoogleDirectionsService()

    private let apiKey = "AIzaSyBblB9O0UzmpYM8b9MISNVODw3yvxOnD0g"

    // MARK: - Coordinate Validation

    private func isValidCoordinate(_ coord: CLLocationCoordinate2D) -> Bool {
        return coord.latitude != 0.0 && coord.longitude != 0.0 &&
               coord.latitude >= -90 && coord.latitude <= 90 &&
               coord.longitude >= -180 && coord.longitude <= 180
    }

    // MARK: - HTML Stripping (service layer only — not in ViewModel)

    func stripHTML(from string: String) -> String {
        guard let data = string.data(using: .utf8) else {
            return string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    // MARK: - DirectionStep → NavigationInstruction

    private func makeInstruction(from step: DirectionStep) -> NavigationInstruction {
        let clean = stripHTML(from: step.html_instructions)
        let distance = step.distance.text
        let full = "\(clean) in \(distance)"
        let coord = CLLocationCoordinate2D(
            latitude: step.end_location.lat,
            longitude: step.end_location.lng
        )
        return NavigationInstruction(
            instruction: clean,
            distanceText: distance,
            fullText: full,
            endLocation: coord
        )
    }

    // MARK: - Full Trip Directions (used by TripDetailView preview)

    func fetchDirections(trip: Trip) async throws -> (eta: String, polyline: String, steps: [NavigationInstruction]) {
        print("--- DEBUG Directions API ---")

        guard isValidCoordinate(trip.pickup.coordinate) else {
            throw NSError(domain: "GoogleDirectionsAPI", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid pickup coordinate"])
        }
        guard isValidCoordinate(trip.destination.coordinate) else {
            throw NSError(domain: "GoogleDirectionsAPI", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid destination coordinate"])
        }
        for (index, stop) in trip.stops.enumerated() {
            guard isValidCoordinate(stop.coordinate) else {
                throw NSError(domain: "GoogleDirectionsAPI", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid stop coordinate at index \(index)"])
            }
        }

        let originParams  = "\(trip.pickup.coordinate.latitude),\(trip.pickup.coordinate.longitude)"
        let destParams    = "\(trip.destination.coordinate.latitude),\(trip.destination.coordinate.longitude)"

        var waypoints = ""
        if !trip.stops.isEmpty {
            let wpStrings = trip.stops.map { "via:\($0.coordinate.latitude),\($0.coordinate.longitude)" }
            waypoints = "&waypoints=" + wpStrings.joined(separator: "|")
        }

        let urlString = "https://maps.googleapis.com/maps/api/directions/json"
            + "?origin=\(originParams)&destination=\(destParams)\(waypoints)&key=\(apiKey)"

        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            throw URLError(.badURL)
        }

        print("[Directions] Request URL:", encoded)

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse {
            print("[Directions] HTTP status:", http.statusCode)
        }

        let decoded = try JSONDecoder().decode(DirectionsResponse.self, from: data)

        guard decoded.status == "OK" else {
            throw NSError(domain: "GoogleDirectionsAPI", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "API status: \(decoded.status)"])
        }
        guard let route = decoded.routes.first, !route.legs.isEmpty else {
            throw NSError(domain: "GoogleDirectionsAPI", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "No route returned"])
        }

        var totalSeconds = 0
        var allInstructions: [NavigationInstruction] = []
        for leg in route.legs {
            totalSeconds += leg.duration.value
            allInstructions.append(contentsOf: leg.steps.map { makeInstruction(from: $0) })
        }

        let hours   = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let etaText = hours > 0 ? "\(hours) hrs \(minutes) min" : "\(minutes) min"

        print("[Directions] ETA: \(etaText), steps: \(allInstructions.count)")
        return (eta: etaText, polyline: route.overview_polyline.points, steps: allInstructions)
    }

    // MARK: - Segment Directions (used by NavigationViewModel — origin = user location)

    func fetchSegmentDirections(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D
    ) async throws -> (eta: String, distance: String, polyline: String, steps: [NavigationInstruction]) {

        guard isValidCoordinate(origin) && isValidCoordinate(destination) else {
            throw NSError(domain: "GoogleDirectionsAPI", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid coordinate passed to segment request"])
        }

        let urlString = "https://maps.googleapis.com/maps/api/directions/json"
            + "?origin=\(origin.latitude),\(origin.longitude)"
            + "&destination=\(destination.latitude),\(destination.longitude)"
            + "&key=\(apiKey)"

        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            throw URLError(.badURL)
        }

        print("[Segment] Request URL:", encoded)

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded   = try JSONDecoder().decode(DirectionsResponse.self, from: data)

        guard decoded.status == "OK",
              let route = decoded.routes.first,
              let leg   = route.legs.first else {
            throw NSError(domain: "GoogleDirectionsAPI", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Segment request empty or failed"])
        }

        let instructions = leg.steps.map { makeInstruction(from: $0) }

        print("[Segment] dist=\(leg.distance.text) eta=\(leg.duration.text) steps=\(instructions.count)")
        return (
            eta:      leg.duration.text,
            distance: leg.distance.text,
            polyline: route.overview_polyline.points,
            steps:    instructions
        )
    }
}
