import Foundation

struct CreateTripRequest: Encodable {
  let sourceLocation: String
  let destinationLocation: String
  let productType: String
  let unit: String
  let amount: Int
  let vehicle: String
  let driver: String
  let departureTime: String
}

struct TripItem: Decodable {
  let id: String?
  let sourceLocation: String?
  let destinationLocation: String?
  let productType: String?
  let unit: String?
  let amount: Int?
  let vehicle: String?
  let driver: String?
  let departureTime: String?
  let createdById: String?
  let createdAt: Date?
  let updatedAt: Date?
}

struct CreateTripResponse: Decodable {
  let message: String
  let trip: TripItem
}

struct GetTripResponse: Decodable {
  let trip: TripItem
}

struct GetTripsResponse: Decodable {
  let trips: [TripItem]
}

final class TripAPI {
  static let shared = TripAPI()

  private let client: APIClient

  init(client: APIClient = .shared) {
    self.client = client
  }

  func createTrip(_ request: CreateTripRequest) async throws -> CreateTripResponse {
    try await client.request(
      path: "/trip/create-trip",
      method: .post,
      body: request,
      requiresAuth: true
    )
  }

  func getTrip(id: String) async throws -> GetTripResponse {
    try await client.request(
      path: "/trip/get-trip?id=\(id)",
      method: .get,
      requiresAuth: true
    )
  }

  func getTrips() async throws -> GetTripsResponse {
    try await client.request(
      path: "/trip/get-trips",
      method: .get,
      requiresAuth: true
    )
  }
}
