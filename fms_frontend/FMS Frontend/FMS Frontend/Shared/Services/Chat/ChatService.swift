
import Foundation
import Combine

final class ChatService {
    private let client = APIClient.shared
    
    /// The base URL for chat services.
    private let chatBaseURL = APIConfig.baseURL

    // MARK: - Fetch Rooms

    /// GET /chat/rooms
    func fetchRooms() -> AnyPublisher<[ChatRoom], Error> {
        return Future { [weak self] promise in
            Task {
                guard let self = self else { return }
                do {
                    let rooms: [ChatRoom] = try await self.client.request(
                        path: "/chat/rooms",
                        method: .get,
                        requiresAuth: true,
                        baseURL: self.chatBaseURL
                    ) ?? []
                    promise(.success(rooms))
                } catch {
                    print("❌ ChatService Error (Rooms): \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Fetch Messages

    /// GET /chat/rooms/{roomId}/messages
    func fetchMessages(for roomId: UUID) -> AnyPublisher<[ChatMessage], Error> {
        return Future { [weak self] promise in
            Task {
                guard let self = self else { return }
                do {
                    let messages: [ChatMessage] = try await self.client.request(
                        path: "/chat/rooms/\(roomId.uuidString)/messages",
                        method: .get,
                        requiresAuth: true,
                        baseURL: self.chatBaseURL
                    ) ?? []
                    promise(.success(messages))
                } catch {
                    print("❌ ChatService Error (Messages): \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Send Message

    /// POST /chat/rooms/{roomId}/messages
    func sendMessage(_ message: ChatMessage) -> AnyPublisher<ChatMessage, Error> {
        return Future { [weak self] promise in
            Task {
                guard let self = self else { return }
                do {
                    let sentMessage: ChatMessage = try await self.client.request(
                        path: "/chat/rooms/\(message.roomId.uuidString)/messages",
                        method: .post,
                        body: message,
                        requiresAuth: true,
                        baseURL: self.chatBaseURL
                    ) ?? message
                    promise(.success(sentMessage))
                } catch {
                    print("❌ ChatService Error (Send): \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Mark Read

    /// PUT /chat/rooms/{roomId}/read
    func markRead(roomId: UUID) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            Task {
                guard let self = self else { return }
                do {
                    let _: EmptyResponse = try await self.client.request(
                        path: "/chat/rooms/\(roomId.uuidString)/read",
                        method: .put,
                        requiresAuth: true,
                        baseURL: self.chatBaseURL
                    ) ?? EmptyResponse()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Create Room

    /// POST /chat/rooms
    func createRoom(targetId: String, senderId: String, senderName: String, senderRole: String, initialMessage: String) -> AnyPublisher<ChatRoom, Error> {
        return Future { [weak self] promise in
            Task {
                guard let self = self else { return }
                do {
                    let body: [String: String] = [
                        "targetId": targetId,
                        "senderId": senderId,
                        "senderName": senderName,
                        "senderRole": senderRole,
                        "message": initialMessage
                    ]
                    
                    let room: ChatRoom = try await self.client.request(
                        path: "/chat/rooms",
                        method: .post,
                        body: body,
                        requiresAuth: true,
                        baseURL: self.chatBaseURL
                    )
                    promise(.success(room))
                } catch {
                    print("❌ ChatService Error (CreateRoom): \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
