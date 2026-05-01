//
//  ChatRoom.swift
//  Created by Kunal Khude
//

import Foundation

// MARK: - Room Type

enum ChatRoomType: String, Codable {
    case direct     // 1-on-1 conversation
    case group      // Multi-participant group
    case broadcast  // Manager broadcast; non-managers are read-only
}

// MARK: - Chat Room

struct ChatRoom: Identifiable, Codable {
    let id: UUID
    var name: String
    var avatarInitials: String?
    var roomType: ChatRoomType
    /// List of participant userIds
    var participants: [String]
    var participantNames: [String: String]
    var lastMessage: ChatMessage?
    var unreadCount: Int
    var lastActivity: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatarInitials = "avatar_initials"
        case roomType = "room_type"
        case participants
        case participantNames = "participant_names"
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case lastActivity = "last_activity"
    }

    init(
        id: UUID = UUID(),
        name: String,
        avatarInitials: String? = nil,
        roomType: ChatRoomType = .group,
        participants: [String] = [],
        participantNames: [String: String] = [:],
        lastMessage: ChatMessage? = nil,
        unreadCount: Int = 0,
        lastActivity: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.avatarInitials = avatarInitials
        self.roomType = roomType
        self.participants = participants
        self.participantNames = participantNames
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.lastActivity = lastActivity
    }

    // Manual decoding to handle missing keys from simplified backend
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        avatarInitials = try container.decodeIfPresent(String.self, forKey: .avatarInitials)
        roomType = (try? container.decode(ChatRoomType.self, forKey: .roomType)) ?? .group
        participants = (try? container.decode([String].self, forKey: .participants)) ?? []
        participantNames = (try? container.decode([String: String].self, forKey: .participantNames)) ?? [:]
        lastMessage = try container.decodeIfPresent(ChatMessage.self, forKey: .lastMessage)
        unreadCount = (try? container.decode(Int.self, forKey: .unreadCount)) ?? 0
        
        // Handle both ISO8601 and potentially other date formats
        if let dateString = try? container.decode(String.self, forKey: .lastActivity),
           let date = ISO8601DateFormatter().date(from: dateString) {
            lastActivity = date
        } else {
            lastActivity = (try? container.decode(Date.self, forKey: .lastActivity)) ?? Date()
        }
    }
}

// MARK: - Helpers

extension ChatRoom {
    func displayName(for currentUserId: String) -> String {
        if roomType == .direct {
            return participantNames.first(where: { $0.key != currentUserId })?.value ?? name
        }
        return name
    }
    
    func displayInitials(for currentUserId: String) -> String {
        if roomType == .direct {
            let name = displayName(for: currentUserId)
            return String(name.prefix(1)).uppercased()
        }
        return avatarInitials ?? String(name.prefix(1)).uppercased()
    }

    func lastMessagePreview(for currentUserId: String?) -> String {
        guard let msg = lastMessage else { return "No messages yet" }
        
        if msg.senderId == currentUserId {
            return "You: \(msg.content)"
        }
        
        if roomType == .direct {
            // No need to prefix with name in a 1-on-1 chat
            return msg.content
        }
        
        // In group chats, prefix with the sender's first name
        let firstName = msg.senderName.components(separatedBy: " ").first ?? "User"
        return "\(firstName): \(msg.content)"
    }

    var lastActivityFormatted: String {
        let cal = Calendar.current
        if cal.isDateInToday(lastActivity) {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f.string(from: lastActivity)
        } else if cal.isDateInYesterday(lastActivity) {
            return "Yesterday"
        } else {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f.string(from: lastActivity)
        }
    }

    var typeBadge: String {
        switch roomType {
        case .direct: return "Direct"
        case .group: return "Group"
        case .broadcast: return "Broadcast"
        }
    }
}
