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
    
    enum UserRole: String, Codable {
        case superAdmin = "SUPER_ADMIN"
        case manager = "MANAGER"
        case maintenance = "MAINTENANCE"
        case driver = "DRIVER"
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
