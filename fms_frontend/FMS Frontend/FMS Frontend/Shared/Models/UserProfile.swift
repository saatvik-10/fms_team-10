import Foundation

struct UserProfile: Codable, Identifiable {
    let id: String
    let name: String
    let username: String
    let phone: String
    let address: String
    let email: String
    let role: UserRole
    let createdAt: Date
    let updatedAt: Date

    init(
        id: String,
        name: String,
        username: String,
        phone: String,
        address: String,
        email: String,
        role: UserRole,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.phone = phone
        self.address = address
        self.email = email
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        username = try container.decode(String.self, forKey: .username)
        phone = try container.decode(String.self, forKey: .phone)
        address = try container.decode(String.self, forKey: .address)
        email = try container.decode(String.self, forKey: .email)
        role = try container.decode(UserRole.self, forKey: .role)

        let fallbackDate = Date()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? fallbackDate
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

extension UserProfile {
    static let mockManager = UserProfile(
        id: "clx1234567890",
        name: "Vikram Singh Rathore",
        username: "vikram.manager",
        phone: "+91 98765 43210",
        address: "Sector 44, Gurgaon, Haryana, 122003",
        email: "fleet@fms.com",
        role: .manager,
        createdAt: Date().addingTimeInterval(-86400 * 365), // 1 year ago
        updatedAt: Date()
    )
    
    static let mockMaintenance = UserProfile(
        id: "clx9876543210",
        name: "Suresh Kumar",
        username: "suresh.tech",
        phone: "+91 99887 76655",
        address: "Kothrud, Pune, Maharashtra, 411038",
        email: "maintenance@fms.com",
        role: .maintenance,
        createdAt: Date().addingTimeInterval(-86400 * 180), // 6 months ago
        updatedAt: Date()
    )
    
    static let mockDriver = UserProfile(
        id: "KM-1029",
        name: "Rahul Sharma",
        username: "rahul.expert",
        phone: "+91 98765 43210",
        address: "Sector 21, Noida, Uttar Pradesh, 201301",
        email: "driver@fms.com",
        role: .driver,
        createdAt: Date().addingTimeInterval(-86400 * 90), // 3 months ago
        updatedAt: Date()
    )
}
