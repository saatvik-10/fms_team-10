import Foundation

struct UserProfile: Codable, Identifiable {
    let id: String
    let name: String
    let username: String
    let phone: String
    var address: String?
    let email: String
    let role: UserRole
    let createdAt: Date
    let updatedAt: Date
    let licenceNumber: String?
    let expiryDate: Date?
    let classes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, username, phone, address, email, role, createdAt, updatedAt
        case licenceNumber, expiryDate, classes
    }
    
init(
        id: String,
        name: String,
        username: String,
        phone: String,
        email: String,
        role: UserRole,
        createdAt: Date,
        updatedAt: Date,
        address: String? = nil,
        licenceNumber: String? = nil,
        expiryDate: Date? = nil,
        classes: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.phone = phone
        self.email = email
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.address = address
        self.licenceNumber = licenceNumber
        self.expiryDate = expiryDate
        self.classes = classes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        username = try container.decode(String.self, forKey: .username)
        phone = try container.decode(String.self, forKey: .phone)
        email = try container.decode(String.self, forKey: .email)
        role = try container.decode(UserRole.self, forKey: .role)

        let fallbackDate = Date()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? fallbackDate
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        address = try container.decodeIfPresent(String.self, forKey: .address)
        licenceNumber = try container.decodeIfPresent(String.self, forKey: .licenceNumber)
        expiryDate = try container.decodeIfPresent(Date.self, forKey: .expiryDate)
        classes = try container.decodeIfPresent([String].self, forKey: .classes)
    }
}

extension UserProfile {
    static let mockManager = UserProfile(
        id: "clx1234567890",
        name: "Vikram Singh Rathore",
        username: "vikram.manager",
        phone: "+91 98765 43210",
        email: "fleet@fms.com",
        role: .manager,
        createdAt: Date().addingTimeInterval(-86400 * 365),
        updatedAt: Date(),
        address: "Sector 44, Gurgaon, Haryana, 122003",
        licenceNumber: nil,
        expiryDate: nil,
        classes: nil
    )
    
    static let mockMaintenance = UserProfile(
        id: "clx9876543210",
        name: "Suresh Kumar",
        username: "suresh.tech",
        phone: "+91 99887 76655",
        email: "maintenance@fms.com",
        role: .maintenance,
        createdAt: Date().addingTimeInterval(-86400 * 180),
        updatedAt: Date(),
        address: "Kothrud, Pune, Maharashtra, 411038",
        licenceNumber: nil,
        expiryDate: nil,
        classes: nil
    )
    
    static let mockDriver = UserProfile(
        id: "KM-1029",
        name: "Rahul Sharma",
        username: "rahul.expert",
        phone: "+91 98765 43210",
        email: "driver@fms.com",
        role: .driver,
        createdAt: Date().addingTimeInterval(-86400 * 90),
        updatedAt: Date(),
        address: nil,
        licenceNumber: "DL-0123456789",
        expiryDate: Date().addingTimeInterval(86400 * 365),
        classes: ["LMV-TR"]
    )
}
