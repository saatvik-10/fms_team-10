
//
//  api.chat.swift
//  FMS Chat — API Definitions
//
//  ✅ DRAG THIS FILE into the `Api/` folder of your main project.
//  This assumes you have an `APIClient` that uses an `Endpoint` enum.
//

import Foundation

/*
// Suggested addition to your existing Endpoint enum:

extension Endpoint {
    static func chatRooms() -> Endpoint {
        return Endpoint(path: "/chat/rooms", method: .get)
    }
    
    static func chatMessages(roomId: UUID) -> Endpoint {
        return Endpoint(path: "/chat/rooms/\(roomId.uuidString)/messages", method: .get)
    }
    
    static func sendMessage(_ message: ChatMessage) -> Endpoint {
        return Endpoint(path: "/chat/rooms/\(message.roomId.uuidString)/messages", method: .post, body: message)
    }
    
    static func markChatRead(roomId: UUID) -> Endpoint {
        return Endpoint(path: "/chat/rooms/\(roomId.uuidString)/read", method: .put)
    }
}
*/

// MARK: - API Documentation
/**
 Chat API Endpoints:
 
 1. GET /api/chat/rooms
    - Returns: [ChatRoom]
    - Description: Fetches all chat rooms for the authenticated user.
 
 2. GET /api/chat/rooms/{roomId}/messages
    - Returns: [ChatMessage]
    - Description: Fetches message history for a specific room.
 
 3. POST /api/chat/rooms/{roomId}/messages
    - Body: ChatMessage (JSON)
    - Returns: ChatMessage
    - Description: Sends a new message to the room.
 
 4. PUT /api/chat/rooms/{roomId}/read
    - Returns: 204 No Content
    - Description: Marks all messages in the room as read.
*/
