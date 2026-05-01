//
//  api.trips.swift
//  Created by Kunal Khude
//

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
  let distance: String?
}

struct TripVehicleInfo: Decodable {
  let id: String
  let registrationNumber: String
  let model: String?
  let status: String?
}

struct TripDriverInfo: Decodable {
  let id: String
  let name: String
  let phone: String?
  let status: String?
}

struct TripItem: Decodable {
  let id: String?
  let sourceLocation: String?
  let destinationLocation: String?
  let productType: String?
  let unit: String?
  let amount: Int?
  let vehicleId: String?
  let driverId: String?
  
  let vehicle: TripVehicleInfo?
  let driver: TripDriverInfo?
  
  let departureTime: String?
  let status: String?
  let loadAmount: String?
  let tripDate: String?
  let tripDistance: String?
  let distanceKm: String?
  let vehicleRegistrationNumber: String?
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

struct CompleteTripRequest: Encodable {
  let tripId: String
}

struct CompleteTripResponse: Decodable {
  let message: String
}

struct StartTripRequest: Encodable {
  let tripId: String
}

struct StartTripResponse: Decodable {
  let message: String
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

  func getDriverTrips() async throws -> GetTripsResponse {
    try await client.request(
      path: "/trip/get-driver-trips",
      method: .get,
      requiresAuth: true
    )
  }

  func completeTripForDriver(tripId: String) async throws -> CompleteTripResponse {
    try await client.request(
      path: "/trip/complete-trip",
      method: .patch,
      body: CompleteTripRequest(tripId: tripId),
      requiresAuth: true
    )
  }

  func startTripForDriver(tripId: String) async throws -> StartTripResponse {
    try await client.request(
      path: "/trip/start-trip",
      method: .patch,
      body: StartTripRequest(tripId: tripId),
      requiresAuth: true
    )
  }

  func deleteTrip(id: String) async throws -> BasicMessageResponse {
    try await client.request(
      path: "/trip/delete-trip?id=\(id)",
      method: .delete,
      requiresAuth: true
    )
  }
}
