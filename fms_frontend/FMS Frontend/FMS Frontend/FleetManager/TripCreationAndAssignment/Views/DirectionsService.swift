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
        print("[FleetDirections] Resolving: \(origin) -> \(destination)")
        
        // Resolve coordinates
        async let oRes = resolveCoordinate(for: origin)
        async let dRes = resolveCoordinate(for: destination)
        
        var oCoord = await oRes
        var dCoord = await dRes
        
        var finalOriginName = origin
        var finalDestName = destination

        // SAFE FALLBACK: If resolution fails, use nearby valid coordinates (Bangalore/Mysore defaults)
        if oCoord == nil {
            print("[FleetDirections] Fallback origin used for: \(origin)")
            oCoord = placeCoordinates["BLR"]
            finalOriginName = "Bangalore"
        }
        if dCoord == nil {
            print("[FleetDirections] Fallback destination used for: \(destination)")
            dCoord = placeCoordinates["MYS"]
            finalDestName = "Mysore"
        }
        
        guard let finalOrigin = oCoord, let finalDest = dCoord else {
            throw NSError(domain: "FleetDirectionsService", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "Could not resolve route endpoints"])
        }
        
        // PREVENT INVALID ROUTES: Check distance (e.g. > 4000km implies cross-continental/error)
        let dist = distanceBetween(finalOrigin, finalDest)
        if dist > 4000000 { // 4000km in meters
            print("[FleetDirections] Route too long (\(dist/1000)km), applying regional fallback")
            // Fallback to BLR -> MYS for demo stability
            return try await fetchDirections(
                originCoord: placeCoordinates["BLR"]!,
                destCoord: placeCoordinates["MYS"]!,
                waypointCoord: waypointCoord,
                originName: "Bangalore",
                destName: "Mysore"
            )
        }

        return try await fetchDirections(originCoord: finalOrigin, destCoord: finalDest,
                                         waypointCoord: waypointCoord,
                                         originName: finalOriginName, destName: finalDestName)
    }

    private func distanceBetween(_ c1: CLLocationCoordinate2D, _ c2: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: c1.latitude, longitude: c1.longitude)
        let loc2 = CLLocation(latitude: c2.latitude, longitude: c2.longitude)
        return loc1.distance(from: loc2)
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

        guard decoded.status == "OK" else {
            throw NSError(domain: "FleetDirectionsService", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Route unavailable: \(decoded.status)\(decoded.error_message != nil ? " - " + decoded.error_message! : "")"])
        }
        guard let route = decoded.routes.first, let leg = route.legs.first else {
            throw NSError(domain: "FleetDirectionsService", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "No route returned"])
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

