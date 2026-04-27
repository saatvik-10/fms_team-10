
//
//  ChatRoom.swift
//  FMS Chat — Chat Module
//
//  ✅ DRAG THIS FILE (inside Chat/ folder) into the main project.
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
    var avatarInitials: String
    let roomType: ChatRoomType
    /// List of participant userIds
    var participants: [String]
    var participantNames: [String: String] = [:] // UserID -> Name
    var lastMessage: ChatMessage?
    var unreadCount: Int
    var lastActivity: Date

    init(
        id: UUID = UUID(),
        name: String,
        avatarInitials: String = "",
        roomType: ChatRoomType = .group,
        participants: [String] = [],
        participantNames: [String: String] = [:],
        lastMessage: ChatMessage? = nil,
        unreadCount: Int = 0,
        lastActivity: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.avatarInitials = avatarInitials.isEmpty
            ? String(name.prefix(2)).uppercased()
            : avatarInitials.uppercased()
        self.roomType = roomType
        self.participants = participants
        self.participantNames = participantNames
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.lastActivity = lastActivity
    }
}

// MARK: - Helpers

extension ChatRoom {
    func displayName(for currentUserId: String) -> String {
        if roomType == .direct {
            // Find the first participant name that ISN'T the current user
            return participantNames.first(where: { $0.key != currentUserId })?.value ?? name
        }
        return name
    }
    
    func displayInitials(for currentUserId: String) -> String {
        if roomType == .direct {
            let name = displayName(for: currentUserId)
            return String(name.prefix(1)).uppercased()
        }
        return avatarInitials
    }

    var lastMessagePreview: String {
        guard let msg = lastMessage else { return "No messages yet" }
        let prefix = msg.senderId == "current_user" ? "You: " : "\(msg.senderName.components(separatedBy: " ").first ?? ""): "
        return prefix + msg.content
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

    /// Room type badge label
    var typeBadge: String {
        switch roomType {
        case .direct:    return "Direct"
        case .group:     return "Group"
        case .broadcast: return "Broadcast"
        }
    }
}
