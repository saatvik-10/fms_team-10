import Foundation

struct CreateMaintenanceRequest: Encodable {
  let name: String
  let dob: String
  let email: String
  let phone: String
}

struct UpdateMaintenancePersonnelRequest: Encodable {
  let name: String?
  let email: String?
  let phone: String?
  let dob: String?
}

struct WorkOrderVehicleItem: Decodable, Identifiable {
  let id: String
  let make: String
  let model: String
  let type: String
  let status: String
  let year: String?
  let color: String?
  let chassisNumber: String
  let registrationNumber: String
  let displayName: String

  var pickerName: String {
    model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? displayName : model
  }

  init(
    id: String,
    make: String,
    model: String,
    type: String,
    status: String,
    year: String?,
    color: String?,
    chassisNumber: String,
    registrationNumber: String,
    displayName: String
  ) {
    self.id = id
    self.make = make
    self.model = model
    self.type = type
    self.status = status
    self.year = year
    self.color = color
    self.chassisNumber = chassisNumber
    self.registrationNumber = registrationNumber
    self.displayName = displayName
  }

  init(vehicle: VehicleItem) {
    self.init(
      id: vehicle.id,
      make: vehicle.make,
      model: vehicle.model,
      type: vehicle.type,
      status: vehicle.status,
      year: vehicle.year,
      color: vehicle.color,
      chassisNumber: vehicle.chassisNumber,
      registrationNumber: vehicle.registrationNumber,
      displayName: vehicle.model
    )
  }
}

struct CreateWorkOrderRequest: Encodable {
  let vehicleId: String
  let title: String
  let serviceType: String?
  let priority: String
  let date: String
  let taskDetails: String
  let mediaImages: [String]
}

struct WorkOrderAPIItem: Decodable {
  let id: String
  let vehicleName: String
  let vehicleNum: String
  let vehicleId: String?
  let title: String
  let serviceType: String?
  let priority: String
  let date: Date
  let taskDetails: String
  let workOrderMedia: [String]
  let maintenanceId: String
  let mediaUrls: [String]?
  let createdAt: Date?
  let updatedAt: Date?
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

struct GetMaintenancesResponse: Decodable {
  let maintenances: [MaintenanceItem]
}

struct UpdateMaintenancePersonnelResponse: Decodable {
  let message: String
  let maintenance: MaintenanceItem
}

struct GetWorkOrderVehiclesResponse: Decodable {
  let vehicles: [WorkOrderVehicleItem]
}

struct CreateWorkOrderResponse: Decodable {
  let message: String
  let workOrder: WorkOrderAPIItem
}

struct GetWorkOrdersResponse: Decodable {
  let workOrders: [WorkOrderAPIItem]
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

  func getMaintenances() async throws -> GetMaintenancesResponse {
    try await client.request(
      path: "/maintenance/get-maintenances",
      method: .get,
      requiresAuth: true
    )
  }

  func deleteMaintenance(id: String) async throws -> BasicMessageResponse {
    try await client.request(
      path: "/maintenance/\(id)",
      method: .delete,
      requiresAuth: true
    )
  }

  func updateMaintenance(id: String, request: UpdateMaintenancePersonnelRequest) async throws -> UpdateMaintenancePersonnelResponse {
    try await client.request(
      path: "/maintenance/update-maintenance/\(id)",
      method: .patch,
      body: request,
      requiresAuth: true
    )
  }

  func getWorkOrderVehicles() async throws -> GetWorkOrderVehiclesResponse {
    try await client.request(
      path: "/maintenance/work-orders/vehicles",
      method: .get,
      requiresAuth: true
    )
  }

  func createWorkOrder(_ request: CreateWorkOrderRequest) async throws -> CreateWorkOrderResponse {
    try await client.request(
      path: "/maintenance/work-orders",
      method: .post,
      body: request,
      requiresAuth: true
    )
  }

  func getWorkOrders() async throws -> GetWorkOrdersResponse {
    try await client.request(
      path: "/maintenance/work-orders",
      method: .get,
      requiresAuth: true
    )
  }
}
