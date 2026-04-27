import Foundation

struct CreateDriverRequest: Encodable {
  let fullName: String
  let email: String
  let phone: String
  let licenseNumber: String
  let expiryDate: String
  let classes: [String]
  let licenseFrontImage: Data
  let licenseBackImage: Data
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
  let licenceNumber: String?
  let expiryDate: String?
  let classes: [String]?
  let dlFrontImageUrl: String?
  let dlBackImageUrl: String?
  let dlFrontImageKey: String?
  let dlBackImageKey: String?
  let createdAt: Date?
  let status: String?
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

struct UpdateDriverRequest: Encodable {
  let fullName: String?
  let email: String?
  let phone: String?
  let licenseNumber: String?
  let expiryDate: String?
  let classes: [String]?
}

struct UpdateDriverResponse: Decodable {
  let message: String
  let driver: DriverItem
}

struct DeleteDriverResponse: Decodable {
  let message: String
}

struct CreateIssueReportRequest: Encodable {
  let tripId: String?
  let transcript: String
  let incidentLocation: String
  let vehicleUnit: String
  let images: [Data]
}

struct IssueReportItem: Decodable {
  let id: String
  let driverUserId: String
  let tripId: String?
  let transcript: String
  let incidentLocation: String
  let vehicleUnit: String
  let imageKeys: [String]
  let imageUrls: [String]?
  let status: String
  let createdAt: Date
  let updatedAt: Date
}

struct CreateIssueReportResponse: Decodable {
  let message: String
  let issue: IssueReportItem
}

struct GetIssueReportsResponse: Decodable {
  let issues: [IssueReportItem]
}

struct GetIssueReportResponse: Decodable {
  let issue: IssueReportItem
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

  func updateDriverProfile(id: String, request: UpdateDriverRequest) async throws -> UpdateDriverResponse {
    try await client.request(
      path: "/driver/\(id)",
      method: .patch,
      body: request,
      requiresAuth: true
    )
  }

  func deleteDriver(id: String) async throws -> DeleteDriverResponse {
    try await client.request(
      path: "/driver/\(id)",
      method: .delete,
      requiresAuth: true
    )
  }

  func createIssueReport(_ request: CreateIssueReportRequest) async throws -> CreateIssueReportResponse {
    try await client.request(
      path: "/issue/report",
      method: .post,
      body: request,
      requiresAuth: true
    )
  }

  func getMyIssueReports(limit: Int = 20) async throws -> GetIssueReportsResponse {
    try await client.request(
      path: "/issue/my-reports?limit=\(limit)",
      method: .get,
      requiresAuth: true
    )
  }

  func getIssueReport(id: String) async throws -> GetIssueReportResponse {
    try await client.request(
      path: "/issue/my-reports/\(id)",
      method: .get,
      requiresAuth: true
    )
  }
}
