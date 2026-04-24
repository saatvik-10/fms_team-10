import Foundation

struct CreateVehicleRequest: Encodable {
  let ownerName: String
  let vehicleModel: String
  let registrationNum: String
  let chassisNum: String
  let odometerReading: String
}

struct VehicleItem: Decodable {
  let id: String
  let ownerName: String
  let vehicleModel: String
  let registrationNum: String
  let chassisNum: String
  let odometerReading: String
  let createdById: String?
  let createdAt: Date?
  let updatedAt: Date?
}

struct CreateVehicleResponse: Decodable {
  let message: String
  let vehicle: VehicleItem
}

struct GetVehiclesResponse: Decodable {
  let vehicles: [VehicleItem]
}

final class VehicleAPI {
  static let shared = VehicleAPI()

  private let client: APIClient

  init(client: APIClient = .shared) {
    self.client = client
  }

  func createVehicleProfile(_ request: CreateVehicleRequest) async throws -> CreateVehicleResponse {
    try await client.request(
      path: "/vehicle/create-vehicle-profile",
      method: .post,
      body: request,
      requiresAuth: true
    )
  }

  func getVehicles() async throws -> GetVehiclesResponse {
    try await client.request(
      path: "/vehicle/get-vehicles",
      method: .get,
      requiresAuth: true
    )
  }
}
