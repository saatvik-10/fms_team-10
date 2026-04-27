
//
//  ChatMessage.swift
//  FMS Chat — Chat Module
//
//  ✅ DRAG THIS FILE (inside Chat/ folder) into the main project.
//

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
    var isStarred: Bool = false
    
    // Media/Voice attachments
    var attachmentType: String? = nil // "image", "file", "voice"
    var attachmentURL: String? = nil

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

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Formatting Helpers

extension ChatMessage {
    /// Short relative time string ("2m ago", "Yesterday", etc.)
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Full formatted timestamp for room header
    var fullTimestamp: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: timestamp)
    }

    /// Role display name
    var senderRoleLabel: String {
        switch senderRole.lowercased() {
        case "driver":      return "Driver"
        case "maintenance": return "Mechanic"
        case "manager":     return "Manager"
        default:            return senderRole.capitalized
        }
    }
}
