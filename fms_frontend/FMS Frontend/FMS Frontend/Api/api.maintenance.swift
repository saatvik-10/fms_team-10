import Foundation

struct CreateMaintenanceRequest: Encodable {
  let name: String
  let dob: String
  let email: String
  let phone: String
}

struct MaintenanceCredentials: Decodable {
  let username: String
  let password: String
}

struct MaintenanceItem: Decodable {
  let id: String?
  let name: String?
  let email: String?
  let username: String?
  let phone: String?
  let dob: Date?
  let age: Int?
  let createdAt: Date?
}

struct CreateMaintenanceResponse: Decodable {
  let message: String
  let credentials: MaintenanceCredentials
  let mail: MailStatus
  let maintenance: MaintenanceItem
}

final class MaintenanceAPI {
  static let shared = MaintenanceAPI()

  private let client: APIClient

  init(client: APIClient = .shared) {
    self.client = client
  }

  func createMaintenanceProfile(_ request: CreateMaintenanceRequest) async throws -> CreateMaintenanceResponse {
    try await client.request(
      path: "/maintenance/create-maintenance-profile",
      method: .post,
      body: request,
      requiresAuth: true
    )
  }
}
