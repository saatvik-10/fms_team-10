
//
//  ChatService.swift
//  FMS Chat — Chat Module
//
//  ✅ DRAG THIS FILE (inside Chat/ folder) into the main project.
//
//  Integration note:
//  Replace the placeholder URLSession stubs with your existing APIClient calls.
//  See Api/api.chat.swift for the endpoint definitions.
//

import Foundation
import Combine

final class ChatService {

    // MARK: - Fetch Rooms

    /// GET /api/chat/rooms
    func fetchRooms() -> AnyPublisher<[ChatRoom], Error> {
        // TODO: Replace with APIClient.shared.request(.chatRooms)
        return Just([ChatRoom]())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch Messages

    /// GET /api/chat/rooms/{roomId}/messages
    func fetchMessages(for roomId: UUID) -> AnyPublisher<[ChatMessage], Error> {
        // TODO: Replace with APIClient.shared.request(.chatMessages(roomId: roomId))
        return Just([ChatMessage]())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Send Message

    /// POST /api/chat/rooms/{roomId}/messages
    func sendMessage(_ message: ChatMessage) -> AnyPublisher<ChatMessage, Error> {
        // TODO: Replace with APIClient.shared.request(.sendMessage(message))
        return Just(message)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Mark Read

    /// PUT /api/chat/rooms/{roomId}/read
    func markRead(roomId: UUID) -> AnyPublisher<Void, Error> {
        // TODO: Replace with APIClient.shared.request(.markChatRead(roomId: roomId))
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
