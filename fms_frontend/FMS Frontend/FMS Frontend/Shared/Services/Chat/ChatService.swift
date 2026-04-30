import Foundation
import Combine

final class ChatService {
    private let client = APIClient.shared
    private let chatBaseURL = APIConfig.baseURL

    // MARK: - Fetch Rooms

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

    func fetchMessages(for roomId: UUID) -> AnyPublisher<[ChatMessage], Error> {
        return Future { [weak self] promise in
            Task {
                guard let self = self else { return }
                do {
                    // ✅ lowercased() to match Prisma's stored UUID format
                    let messages: [ChatMessage] = try await self.client.request(
                        path: "/chat/rooms/\(roomId.uuidString.lowercased())/messages",
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

    func sendMessage(_ message: ChatMessage) -> AnyPublisher<ChatMessage, Error> {
        return Future { [weak self] promise in
            Task {
                guard let self = self else { return }
                do {
                    // ✅ lowercased() to match Prisma's stored UUID format
                    let sentMessage: ChatMessage = try await self.client.request(
                        path: "/chat/rooms/\(message.roomId.uuidString.lowercased())/messages",
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

    func markRead(roomId: UUID) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            Task {
                guard let self = self else { return }
                do {
                    // ✅ lowercased() to match Prisma's stored UUID format
                    let _: EmptyResponse = try await self.client.request(
                        path: "/chat/rooms/\(roomId.uuidString.lowercased())/read",
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

    // MARK: - Fetch Users

    struct UserContact: Codable {
        let id: String
        let name: String
        let role: String
        let initials: String
    }

    func fetchUsers() -> AnyPublisher<[UserContact], Error> {
        return Future { [weak self] promise in
            Task {
                guard let self = self else { return }
                do {
                    let users: [UserContact] = try await self.client.request(
                        path: "/chat/users",
                        method: .get,
                        requiresAuth: true,
                        baseURL: self.chatBaseURL
                    ) ?? []
                    promise(.success(users))
                } catch {
                    print("❌ ChatService Error (Users): \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}