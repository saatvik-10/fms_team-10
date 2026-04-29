import Foundation
import CoreLocation

// MARK: - Fleet Directions Result

struct FleetDirectionsResult {
    let eta: String         // e.g. "45 mins"
    let distance: String    // e.g. "32.4 km"
    let polyline: String    // Encoded overview polyline
    let originCoord: CLLocationCoordinate2D
    let destCoord: CLLocationCoordinate2D
    let originName: String
    let destName: String
}

// MARK: - Fleet Directions Service

/// Fetches route data from Google Directions API for the Fleet-side trip detail view.
/// This is a self-contained service scoped to FleetManager — does NOT depend on Driver-side services.
actor FleetDirectionsService {

    static let shared = FleetDirectionsService()

    private let apiKey = "AIzaSyBblB9O0UzmpYM8b9MISNVODw3yvxOnD0g"

    // MARK: - Coordinate Mapping for known locations
    private let placeCoordinates: [String: CLLocationCoordinate2D] = [
        "DEL": CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
        "BLR": CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946),
        "MYS": CLLocationCoordinate2D(latitude: 12.2958, longitude: 76.6394),
        "Infosys Mysore": CLLocationCoordinate2D(latitude: 12.522, longitude: 76.895),
        "Coorg": CLLocationCoordinate2D(latitude: 12.4244, longitude: 75.7382),
        "Madikeri": CLLocationCoordinate2D(latitude: 12.4244, longitude: 75.7382)
    ]

    private let commonAbbreviations: [String: String] = [
        "DEL": "Delhi, India",
        "JAI": "Jaipur, Rajasthan, India",
        "BLR": "Bangalore, India",
        "MUM": "Mumbai, India",
        "PUN": "Pune, India",
        "AMD": "Ahmedabad, India",
        "SUR": "Surat, India",
        "AGR": "Agra, India",
        "HYD": "Hyderabad, India",
        "MAA": "Chennai, India",
        "KOR": "Koramangala, Bangalore",
        "HSR": "HSR Layout, Bangalore",
        "HSR Lyt": "HSR Layout, Bangalore",
        "BLR Hub": "Bangalore, India"
    ]

    // MARK: - Helper to resolve a place to a coordinate
    private func resolveCoordinate(for place: String) async -> CLLocationCoordinate2D? {
        // 1. Check hardcoded mapping
        if let hardcoded = placeCoordinates[place] {
            return hardcoded
        }
        
        // 2. Try geocoding safely
        do {
            return try await geocode(placeName: place)
        } catch {
            print("[FleetDirections] Geocoding failed for \(place): \(error.localizedDescription)")
            return nil
        }
    }

    private func geocode(placeName: String) async throws -> CLLocationCoordinate2D {
        let lookupName = commonAbbreviations[placeName] ?? placeName
        let escaped = lookupName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? lookupName
        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?address=\(escaped)&key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)

        struct GeoResponse: Decodable {
            let results: [GeoResult]
            let status: String
        }
        struct GeoResult: Decodable {
            let geometry: GeoGeometry
        }
        struct GeoGeometry: Decodable {
            let location: GeoLocation
        }
        struct GeoLocation: Decodable {
            let lat: Double
            let lng: Double
        }

        let decoded = try JSONDecoder().decode(GeoResponse.self, from: data)
        guard decoded.status == "OK", let first = decoded.results.first else {
            throw NSError(domain: "FleetDirectionsService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Geocoding failed for: \(placeName), status: \(decoded.status)"])
        }
        return CLLocationCoordinate2D(latitude: first.geometry.location.lat,
                                       longitude: first.geometry.location.lng)
    }

    // MARK: - Fetch directions between two place names

    func fetchDirections(origin: String, destination: String, waypointCoord: CLLocationCoordinate2D? = nil) async throws -> FleetDirectionsResult {
        let originAddress = commonAbbreviations[origin] ?? origin
        let destinationAddress = commonAbbreviations[destination] ?? destination

        print("[FleetDirections] Requesting address route: \(originAddress) -> \(destinationAddress)")

        var urlString =
            "https://maps.googleapis.com/maps/api/directions/json" +
            "?origin=\(originAddress)" +
            "&destination=\(destinationAddress)"

        if let wp = waypointCoord {
            urlString += "&waypoints=\(wp.latitude),\(wp.longitude)"
        }

        urlString += "&mode=driving&key=\(apiKey)"

        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            throw URLError(.badURL)
        }

        print("[FleetDirections] Requesting: \(encoded)")

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse {
            print("[FleetDirections] HTTP status: \(http.statusCode)")
        }

        struct DResponse: Decodable {
            let routes: [DRoute]
            let status: String
            let error_message: String?
        }
        struct DRoute: Decodable {
            let legs: [DLeg]
            let overview_polyline: DPolyline
        }
        struct DLeg: Decodable {
            let duration: DItem
            let distance: DItem
            let start_location: DLocation
            let end_location: DLocation
        }
        struct DItem: Decodable {
            let text: String
            let value: Int
        }
        struct DLocation: Decodable {
            let lat: Double
            let lng: Double
        }
        struct DPolyline: Decodable {
            let points: String
        }

        let decoded = try JSONDecoder().decode(DResponse.self, from: data)

        print("[FleetDirections] Directions API Status: \(decoded.status)")
        if let msg = decoded.error_message {
            print("[FleetDirections] API Error Message: \(msg)")
        }

        guard decoded.status == "OK",
              let route = decoded.routes.first,
              let leg = route.legs.first else {
            throw NSError(
                domain: "FleetDirectionsService",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Directions failed: \(decoded.status)\(decoded.error_message.map { " - \($0)" } ?? "")"
                ]
            )
        }

        return FleetDirectionsResult(
            eta: leg.duration.text,
            distance: leg.distance.text,
            polyline: route.overview_polyline.points,
            originCoord: CLLocationCoordinate2D(latitude: leg.start_location.lat, longitude: leg.start_location.lng),
            destCoord: CLLocationCoordinate2D(latitude: leg.end_location.lat, longitude: leg.end_location.lng),
            originName: origin,
            destName: destination
        )
    }

    // MARK: - Fetch directions between two coordinates

    func fetchDirections(
        originCoord: CLLocationCoordinate2D,
        destCoord: CLLocationCoordinate2D,
        waypointCoord: CLLocationCoordinate2D? = nil,
        originName: String = "",
        destName: String = ""
    ) async throws -> FleetDirectionsResult {
        
        print("[FleetDirections] Origin: (\(originCoord.latitude), \(originCoord.longitude))")
        print("[FleetDirections] Destination: (\(destCoord.latitude), \(destCoord.longitude))")
        if let wp = waypointCoord {
            print("[FleetDirections] Waypoint: (\(wp.latitude), \(wp.longitude))")
        }
        
        var urlString =
            "https://maps.googleapis.com/maps/api/directions/json" +
            "?origin=\(originCoord.latitude),\(originCoord.longitude)" +
            "&destination=\(destCoord.latitude),\(destCoord.longitude)"
        
        if let wp = waypointCoord {
            urlString += "&waypoints=via:\(wp.latitude),\(wp.longitude)"
        }
        
        urlString += "&key=\(apiKey)"

        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            throw URLError(.badURL)
        }

        print("[FleetDirections] Requesting: \(encoded)")

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse {
            print("[FleetDirections] HTTP status: \(http.statusCode)")
        }

        // MARK: - Response models
        struct DResponse: Decodable {
            let routes: [DRoute]
            let status: String
            let error_message: String?
        }
        struct DRoute: Decodable {
            let legs: [DLeg]
            let overview_polyline: DPolyline
        }
        struct DLeg: Decodable {
            let duration: DItem
            let distance: DItem
        }
        struct DItem: Decodable {
            let text: String
            let value: Int
        }
        struct DPolyline: Decodable {
            let points: String
        }

        let decoded = try JSONDecoder().decode(DResponse.self, from: data)
        
        print("[FleetDirections] Directions API Status: \(decoded.status)")
        if let msg = decoded.error_message {
            print("[FleetDirections] API Error Message: \(msg)")
        }

        guard decoded.status == "OK",
              let route = decoded.routes.first,
              let leg = route.legs.first else {
            return FleetDirectionsResult(
                eta: "TBD",
                distance: "TBD",
                polyline: "",
                originCoord: originCoord,
                destCoord: destCoord,
                originName: originName.isEmpty ? "Unknown Origin" : originName,
                destName: destName.isEmpty ? "Unknown Destination" : destName
            )
        }

        print("[FleetDirections] ETA: \(leg.duration.text), Distance: \(leg.distance.text)")

        return FleetDirectionsResult(
            eta: leg.duration.text,
            distance: leg.distance.text,
            polyline: route.overview_polyline.points,
            originCoord: originCoord,
            destCoord: destCoord,
            originName: originName.isEmpty ? "Unknown Origin" : originName,
            destName: destName.isEmpty ? "Unknown Destination" : destName
        )
    }
}
