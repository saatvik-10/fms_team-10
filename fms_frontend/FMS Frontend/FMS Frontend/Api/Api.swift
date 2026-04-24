import Foundation
import Security

enum APIError: LocalizedError {
	case invalidURL
	case invalidResponse
	case unauthorized
	case server(statusCode: Int, message: String)
	case transport(Error)
	case decoding(Error)

	var errorDescription: String? {
		switch self {
		case .invalidURL:
			return "Invalid API URL"
		case .invalidResponse:
			return "Invalid response from server"
		case .unauthorized:
			return "Authentication required"
		case .server(_, let message):
			return message
		case .transport(let error):
			return error.localizedDescription
		case .decoding(let error):
			return "Failed to parse server response: \(error.localizedDescription)"
		}
	}
}

enum HTTPMethod: String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case patch = "PATCH"
	case delete = "DELETE"
}

enum UserRole: String, Codable {
	case superAdmin = "SUPER_ADMIN"
	case manager = "MANAGER"
	case driver = "DRIVER"
	case maintenance = "MAINTENANCE"
}

struct APIConfig {
	static let baseURL: String = {
		if let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
			 !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			return value
		}
		return "https://fms-team-10.onrender.com"
	}()
}

private struct AnyEncodable: Encodable {
	private let encodeFn: (Encoder) throws -> Void

	init<T: Encodable>(_ wrapped: T) {
		self.encodeFn = wrapped.encode
	}

	func encode(to encoder: Encoder) throws {
		try encodeFn(encoder)
	}
}

private struct APIErrorResponse: Decodable {
	let err: String?
	let message: String?
}

struct EmptyResponse: Encodable {}

struct MailStatus: Decodable {
	let sent: Bool
	let details: String?
}

final class TokenStore {
	static let shared = TokenStore()

	private let service = "com.fms.frontend.auth"
	private let account = "jwt_token"

	private init() {}

	func save(token: String) {
		let data = Data(token.utf8)
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
		]

		SecItemDelete(query as CFDictionary)

		let attributes: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
			kSecValueData as String: data,
			kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
		]

		SecItemAdd(attributes as CFDictionary, nil)
	}

	func getToken() -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne,
		]

		var item: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &item)

		guard status == errSecSuccess,
					let data = item as? Data,
					let token = String(data: data, encoding: .utf8) else {
			return nil
		}

		return token
	}

	func clear() {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
		]

		SecItemDelete(query as CFDictionary)
	}
}

final class APIClient {
	static let shared = APIClient()

	private let session: URLSession
	private let encoder: JSONEncoder
	private let decoder: JSONDecoder
	private let tokenStore: TokenStore
	private let iso8601WithFractionalSeconds: ISO8601DateFormatter
	private let iso8601Basic: ISO8601DateFormatter

	private init(
		session: URLSession = .shared,
		tokenStore: TokenStore = .shared
	) {
		self.session = session
		self.tokenStore = tokenStore

		self.encoder = JSONEncoder()
		self.decoder = JSONDecoder()
		self.iso8601WithFractionalSeconds = ISO8601DateFormatter()
		self.iso8601WithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

		self.iso8601Basic = ISO8601DateFormatter()
		self.iso8601Basic.formatOptions = [.withInternetDateTime]

		self.decoder.dateDecodingStrategy = .custom { [iso8601WithFractionalSeconds, iso8601Basic] decoder in
			let container = try decoder.singleValueContainer()
			let value = try container.decode(String.self)

			if let date = iso8601WithFractionalSeconds.date(from: value) ?? iso8601Basic.date(from: value) {
				return date
			}

			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Invalid ISO-8601 date: \(value)"
			)
		}
	}

	func request<T: Decodable>(
		path: String,
		method: HTTPMethod,
		requiresAuth: Bool = true,
		responseType: T.Type = T.self
	) async throws -> T {
		try await request(
			path: path,
			method: method,
			body: Optional<EmptyResponse>.none,
			requiresAuth: requiresAuth,
			responseType: responseType
		)
	}

	func setToken(_ token: String) {
		tokenStore.save(token: token)
	}

	func clearToken() {
		tokenStore.clear()
	}

	func currentToken() -> String? {
		tokenStore.getToken()
	}

	func request<T: Decodable, B: Encodable>(
		path: String,
		method: HTTPMethod,
		body: B? = nil,
		requiresAuth: Bool = true,
		responseType: T.Type = T.self
	) async throws -> T {
		guard let url = URL(string: APIConfig.baseURL + path) else {
			throw APIError.invalidURL
		}

		var request = URLRequest(url: url)
		request.httpMethod = method.rawValue
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("application/json", forHTTPHeaderField: "Accept")

		if requiresAuth {
			guard let token = tokenStore.getToken() else {
				throw APIError.unauthorized
			}
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}

		if let body {
			request.httpBody = try encoder.encode(AnyEncodable(body))
		}

		let data: Data
		let urlResponse: URLResponse

		do {
			(data, urlResponse) = try await session.data(for: request)
		} catch {
			throw APIError.transport(error)
		}

		guard let httpResponse = urlResponse as? HTTPURLResponse else {
			throw APIError.invalidResponse
		}

		guard (200...299).contains(httpResponse.statusCode) else {
			let serverMessage = (try? decoder.decode(APIErrorResponse.self, from: data))
			let message = serverMessage?.err ?? serverMessage?.message ?? "Request failed with status \(httpResponse.statusCode)"
			if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
				throw APIError.unauthorized
			}
			throw APIError.server(statusCode: httpResponse.statusCode, message: message)
		}

		if T.self == EmptyResponse.self {
			return EmptyResponse() as! T
		}

		do {
			return try decoder.decode(T.self, from: data)
		} catch {
			throw APIError.decoding(error)
		}
	}
}

struct AuthTokenResponse: Decodable {
	let token: String
}

struct UserSigninRequest: Encodable {
	let username: String
	let password: String
}

struct SuperAdminSigninRequest: Encodable {
	let email: String
	let password: String
}

struct OTPMailRequest: Encodable {
	let email: String
}

struct OTPVerifyRequest: Encodable {
	let email: String
	let otp: String
}

struct BasicMessageResponse: Decodable {
	let message: String
}

struct AuthUser: Decodable {
	let id: String?
	let email: String?
	let username: String?
	let role: UserRole
	let name: String?
	let phone: String?
	let address: String?
	let licenceNumber: String?
	let expiryDate: String?
	let classes: [String]?
	let dob: Date?
}

struct UserSigninResponse: Decodable {
	let token: String
	let user: AuthUser
}

struct UserProfileResponse: Decodable {
	let profile: UserProfile
}

struct OTPVerifyResponse: Decodable {
	let value: String

	init(from decoder: Decoder) throws {
		if let container = try? decoder.singleValueContainer(),
			 let singleValue = try? container.decode(String.self) {
			self.value = singleValue
			return
		}

		let keyed = try decoder.container(keyedBy: CodingKeys.self)
		self.value = try keyed.decode(String.self, forKey: .message)
	}

	private enum CodingKeys: String, CodingKey {
		case message
	}
}

final class AuthAPI {
	static let shared = AuthAPI()

	private let client: APIClient

	init(client: APIClient = .shared) {
		self.client = client
	}

	func getCurrentToken() -> String? {
		client.currentToken()
	}

	func superAdminSignin(email: String, password: String) async throws -> AuthTokenResponse {
		let response: AuthTokenResponse = try await client.request(
			path: "/auth/super-admin/signin",
			method: .post,
			body: SuperAdminSigninRequest(email: email, password: password),
			requiresAuth: false
		)
		client.setToken(response.token)
		return response
	}

	func userSignin(username: String, password: String) async throws -> UserSigninResponse {
		let response: UserSigninResponse = try await client.request(
			path: "/auth/signin",
			method: .post,
			body: UserSigninRequest(username: username, password: password),
			requiresAuth: false
		)
		client.setToken(response.token)
		return response
	}

	func sendOTP(email: String) async throws -> BasicMessageResponse {
		try await client.request(
			path: "/auth/otp/send",
			method: .post,
			body: OTPMailRequest(email: email),
			requiresAuth: false
		)
	}

	func verifyOTP(email: String, otp: String) async throws -> OTPVerifyResponse {
		try await client.request(
			path: "/auth/verify-otp",
			method: .post,
			body: OTPVerifyRequest(email: email, otp: otp),
			requiresAuth: false
		)
	}

	func getProfile() async throws -> UserProfileResponse {
		try await client.request(
			path: "/auth/profile",
			method: .get,
			requiresAuth: true
		)
	}

	func logout() {
		client.clearToken()
	}
}
