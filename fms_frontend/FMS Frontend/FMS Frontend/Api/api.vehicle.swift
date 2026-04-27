import Foundation

struct CreateVehicleRequest: Encodable {
    let make: String
    let model: String
    let type: String
    let status: String?
    let imageName: String?
    let year: String?
    let color: String?
    let operationalStatus: String?
    let assessmentReason: String?
    let chassisNumber: String
    let registrationNumber: String
    let rcDocumentImage: String?
    let vehicleImage: String?
}

struct VehicleItem: Decodable {
    let id: String
    let make: String
    let model: String
    let type: String
    let status: String
    let imageName: String?
    let year: String?
    let color: String?
    let operationalStatus: String?
    let assessmentReason: String?
    let chassisNumber: String
    let registrationNumber: String
    let rcImageUrl: String?
    let vehicleImageUrl: String?
    let assignedDriverId: String?
    let createdAt: Date?
    let updatedAt: Date?

    let currentTrip: VehicleTripItem?
    let maintenance: VehicleMaintenanceItem?
    let assignedDriver: VehicleDriverItem?
}

struct VehicleDriverItem: Decodable {
    let id: String
    let name: String
    let phone: String?
    let status: String?
    let licenceNumber: String?
    let classes: [String]?
}

struct VehicleTripItem: Decodable {
    let id: String
    let vehicleId: String
    let origin: String
    let destination: String
    let progress: Double
    let eta: String?
    let date: String?
    let distance: String?
    let duration: String?
    let costEstimate: String?
    let startTime: Date?
    let status: String
    let productType: String?
    let loadAmount: String?
}

struct VehicleMaintenanceItem: Decodable {
    let id: String
    let vehicleId: String
    let nextService: String?
    let inspectionStatus: String?
    let alerts: String?
}

struct UpdateMaintenanceRequest: Encodable {
    let nextService: String?
    let inspectionStatus: String?
    let alerts: String?
}

struct UpdateMaintenanceResponse: Decodable {
    let message: String
    let maintenance: VehicleMaintenanceItem
}

struct TripHistoryItem: Decodable {
    let id: String
    let vehicleId: String
    let vehicleID: String
    let origin: String
    let destination: String
    let progress: Double
    let eta: String?
    let date: String?
    let distance: String?
    let duration: String?
    let costEstimate: String?
    let startTime: Date?
    let status: String
    let productType: String?
    let loadAmount: String?
    let createdAt: Date?
}

struct CreateVehicleResponse: Decodable {
    let message: String
    let vehicle: VehicleItem
}

struct GetVehiclesResponse: Decodable {
    let vehicles: [VehicleItem]
}

struct GetVehicleResponse: Decodable {
    let vehicle: VehicleItem
    let history: [TripHistoryItem]?
}

struct UpdateVehicleRequest: Encodable {
    let make: String?
    let model: String?
    let type: String?
    let status: String?
    let imageName: String?
    let year: String?
    let color: String?
    let operationalStatus: String?
    let assessmentReason: String?
    let chassisNumber: String?
    let registrationNumber: String?
    let rcDocumentImage: String?
    let vehicleImage: String?
    let assignedDriverId: String?
}

struct UpdateVehicleResponse: Decodable {
    let message: String
    let vehicle: VehicleItem
}

struct DeleteVehicleResponse: Decodable {
    let message: String
}

struct UpdateCurrentTripRequest: Encodable {
    let origin: String
    let destination: String
    let progress: Double
    let eta: String?
    let date: String?
    let distance: String?
    let duration: String?
    let costEstimate: String?
    let startTime: String?
    let status: String?
    let productType: String?
    let loadAmount: String?
}

struct UpdateCurrentTripResponse: Decodable {
    let message: String
    let trip: VehicleTripItem
}

struct UpdateVehicleMaintenanceRequest: Encodable {
    let nextService: String?
    let inspectionStatus: String?
    let alerts: String?
}

struct UpdateVehicleMaintenanceResponse: Decodable {
    let message: String
    let maintenance: VehicleMaintenanceItem
}

struct AddTripHistoryRequest: Encodable {
    let vehicleId: String
    let vehicleID: String
    let origin: String
    let destination: String
    let progress: Double
    let eta: String?
    let date: String?
    let distance: String?
    let duration: String?
    let costEstimate: String?
    let startTime: String?
    let status: String?
    let productType: String?
    let loadAmount: String?
}

struct AddTripHistoryResponse: Decodable {
    let message: String
    let history: TripHistoryItem
}

struct GetTripHistoryResponse: Decodable {
    let history: [TripHistoryItem]
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

    func getVehicleById(id: String) async throws -> GetVehicleResponse {
        try await client.request(
            path: "/vehicle/\(id)",
            method: .get,
            requiresAuth: true
        )
    }

    func updateVehicleProfile(id: String, request: UpdateVehicleRequest) async throws -> UpdateVehicleResponse {
        try await client.request(
            path: "/vehicle/\(id)",
            method: .patch,
            body: request,
            requiresAuth: true
        )
    }

    func deleteVehicle(id: String) async throws -> DeleteVehicleResponse {
        try await client.request(
            path: "/vehicle/\(id)",
            method: .delete,
            requiresAuth: true
        )
    }

    func updateCurrentTrip(vehicleId: String, request: UpdateCurrentTripRequest) async throws -> UpdateCurrentTripResponse {
        try await client.request(
            path: "/vehicle/\(vehicleId)/current-trip",
            method: .patch,
            body: request,
            requiresAuth: true
        )
    }

    func updateMaintenance(vehicleId: String, request: UpdateMaintenanceRequest) async throws -> UpdateMaintenanceResponse {
        try await client.request(
            path: "/vehicle/\(vehicleId)/maintenance",
            method: .patch,
            body: request,
            requiresAuth: true
        )
    }

    func addTripHistory(vehicleId: String, request: AddTripHistoryRequest) async throws -> AddTripHistoryResponse {
        try await client.request(
            path: "/vehicle/\(vehicleId)/history",
            method: .post,
            body: request,
            requiresAuth: true
        )
    }

    func getTripHistory(vehicleId: String) async throws -> GetTripHistoryResponse {
        try await client.request(
            path: "/vehicle/\(vehicleId)/history",
            method: .get,
            requiresAuth: true
        )
    }
}