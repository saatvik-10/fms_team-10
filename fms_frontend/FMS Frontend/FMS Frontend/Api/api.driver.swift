import Foundation

struct CreateDriverRequest: Encodable {
  let fullName: String
  let email: String
  let phone: String
  let address: String?
  let licenseNumber: String
  let expiryDate: String
  let classes: [String]
}

struct DriverCredentials: Decodable {
  let username: String
  let password: String
}

struct DriverItem: Decodable {
  let id: String?
  let name: String?
  let email: String?
  let username: String?
  let phone: String?
  let address: String?
  let licenceNumber: String?
  let expiryDate: String?
  let classes: [String]?
  let createdAt: Date?
}

struct CreateDriverResponse: Decodable {
  let message: String
  let credentials: DriverCredentials
  let mail: MailStatus
  let driver: DriverItem
}

struct GetDriversResponse: Decodable {
  let drivers: [DriverItem]
}

final class DriverAPI {
  static let shared = DriverAPI()

  private let client: APIClient

  init(client: APIClient = .shared) {
    self.client = client
  }

  func createDriverProfile(_ request: CreateDriverRequest) async throws -> CreateDriverResponse {
    try await client.request(
      path: "/driver/create-driver-profile",
      method: .post,
      body: request,
      requiresAuth: true
    )
  }

  func getDrivers() async throws -> GetDriversResponse {
    try await client.request(
      path: "/driver/get-drivers",
      method: .get,
      requiresAuth: true
    )
  }
}
