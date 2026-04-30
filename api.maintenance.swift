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
  let status: String?
  let date: Date
  let taskDetails: String
  let workOrderMedia: [String]
  let maintenanceId: String
  let mediaUrls: [String]?
  let tripId: String?
  let totalCost: Double?   // populated once work order is completed
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

struct InspectionAPIItem: Decodable {
  let id: String
  let workOrderId: String?
  let title: String
  let vehicleId: String
  let unitName: String
  let unitVIN: String
  let driverId: String
  let timestamp: Date
  let type: String
  let vehicleType: String
  let status: String
  let priority: String
  let items: [InspectionItem]
  let notes: String?
  let maintenanceStaffId: String
  let isEmergency: Bool
  let odometer: String
  let fuelLevel: String
  let imageUrls: [String]?
  let reportUrl: String?
  let consumedParts: [WorkOrderPartUsage]?
  let taskDetails: String?
}

struct GetInspectionsResponse: Decodable {
  let inspections: [InspectionAPIItem]
}

struct UpdateInspectionRequest: Encodable {
  let notes: String?
  let items: [InspectionItem]?
  let reportUrl: String?
}

struct MaintenanceIssueReportItem: Decodable {
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

struct GetMaintenanceIssueReportsResponse: Decodable {
  let issues: [MaintenanceIssueReportItem]
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

  func getWorkOrders(status: String? = nil) async throws -> GetWorkOrdersResponse {
    var path = "/maintenance/work-orders"
    if let status = status {
        path += "?status=\(status)"
    }
    
    return try await client.request(
      path: path,
      method: .get,
      requiresAuth: true
    )
  }

  func completeWorkOrder(id: String, request: CompleteWorkOrderRequest) async throws -> BasicMessageResponse {
    try await client.request(
      path: "/maintenance/work-orders/\(id)/complete",
      method: .patch,
      body: request,
      requiresAuth: true
    )
  }

  func getInspections() async throws -> GetInspectionsResponse {
    try await client.request(
      path: "/maintenance/inspections",
      method: .get,
      requiresAuth: true
    )
  }

  func getIssueReports(limit: Int = 50) async throws -> GetMaintenanceIssueReportsResponse {
    try await client.request(
      path: "/issue/maintenance-reports?limit=\(limit)",
      method: .get,
      requiresAuth: true
    )
  }

  func updateInspection(id: String, request: UpdateInspectionRequest) async throws -> BasicMessageResponse {
    try await client.request(
      path: "/maintenance/inspections/\(id)",
      method: .patch,
      body: request,
      requiresAuth: true
    )
  }
}

struct CompleteWorkOrderRequest: Encodable {
  let totalCost: Double
  let technicianNotes: String?
  let checklist: [InspectionItem]?
  let consumedParts: [WorkOrderPartUsage]?
  let workOrderMedia: [String]?
  let isEmergency: Bool?
  let odometer: String?
  let fuelLevel: String?
  let taskDetails: String?
}
