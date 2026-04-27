
import Foundation

// MARK: - Message Status

enum MessageStatus: String, Codable {
    case sent
    case delivered
    case read
}

// MARK: - Chat Message

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let roomId: UUID
    let senderId: String
    let senderName: String
    let senderRole: String
    let content: String
    let timestamp: Date
    var status: MessageStatus
    var isStarred: Bool

    // Media/Voice attachments
    var attachmentType: String?
    var attachmentURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case roomId = "room_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderRole = "sender_role"
        case content
        case timestamp
        case status
        case isStarred = "is_starred"
        case attachmentType = "attachment_type"
        case attachmentURL = "attachment_url"
    }

    init(
        id: UUID = UUID(),
        roomId: UUID,
        senderId: String,
        senderName: String,
        senderRole: String,
        content: String,
        timestamp: Date = Date(),
        status: MessageStatus = .sent,
        isStarred: Bool = false,
        attachmentType: String? = nil,
        attachmentURL: String? = nil
    ) {
        self.id = id
        self.roomId = roomId
        self.senderId = senderId
        self.senderName = senderName
        self.senderRole = senderRole
        self.content = content
        self.timestamp = timestamp
        self.status = status
        self.isStarred = isStarred
        self.attachmentType = attachmentType
        self.attachmentURL = attachmentURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        
        // Handle roomId from both UUID and String formats
        if let roomUUID = try? container.decode(UUID.self, forKey: .roomId) {
            roomId = roomUUID
        } else if let roomString = try? container.decode(String.self, forKey: .roomId),
                  let roomUUID = UUID(uuidString: roomString) {
            roomId = roomUUID
        } else {
            throw DecodingError.dataCorruptedError(forKey: .roomId, in: container, debugDescription: "Invalid roomId format")
        }
        
        senderId = try container.decode(String.self, forKey: .senderId)
        senderName = try container.decode(String.self, forKey: .senderName)
        senderRole = try container.decode(String.self, forKey: .senderRole)
        content = try container.decode(String.self, forKey: .content)
        
        // Handle timestamp string vs Date
        if let dateString = try? container.decode(String.self, forKey: .timestamp),
           let date = ISO8601DateFormatter().date(from: dateString) {
            timestamp = date
        } else if let date = try? container.decode(Date.self, forKey: .timestamp) {
            timestamp = date
        } else {
            timestamp = Date()
        }
        
        status = (try? container.decode(MessageStatus.self, forKey: .status)) ?? .sent
        isStarred = (try? container.decode(Bool.self, forKey: .isStarred)) ?? false
        attachmentType = try container.decodeIfPresent(String.self, forKey: .attachmentType)
        attachmentURL = try container.decodeIfPresent(String.self, forKey: .attachmentURL)
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Formatting Helpers

extension ChatMessage {
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var fullTimestamp: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: timestamp)
    }

    var senderRoleLabel: String {
        switch senderRole.lowercased() {
        case "driver":      return "Driver"
        case "maintenance": return "Mechanic"
        case "manager":     return "Manager"
        default:            return senderRole.capitalized
        }
    }
}
