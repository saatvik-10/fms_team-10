import Foundation

struct CreateManagerRequest: Encodable {
  let name: String
  let phone: String
  let address: String
  let email: String
}

struct ManagerCredentials: Decodable {
  let username: String
  let password: String
}

struct ManagerBasic: Decodable {
  let id: String?
  let name: String?
}

struct ManagerDetail: Decodable {
  let id: String
  let name: String
  let email: String?
  let username: String?
  let phone: String?
  let address: String?
  let role: UserRole
  let createdAt: Date?
}

struct CreateManagerResponse: Decodable {
  let message: String
  let credentials: ManagerCredentials
  let manager: ManagerBasic
}

struct GetManagerResponse: Decodable {
  let manager: ManagerDetail
}

final class ManagerAPI {
  static let shared = ManagerAPI()

  private let client: APIClient

  init(client: APIClient = .shared) {
    self.client = client
  }

  func createManagerProfile(_ request: CreateManagerRequest) async throws -> CreateManagerResponse {
    try await client.request(
      path: "/manager/create-manager-profile",
      method: .post,
      body: request,
      requiresAuth: true
    )
  }

  func getManager(id: String) async throws -> GetManagerResponse {
    try await client.request(
      path: "/manager/\(id)",
      method: .get,
      requiresAuth: true
    )
  }
}
