
import Foundation
import Combine

final class ChatService {
    private let client = APIClient.shared
    // Local Node.js chat server.
    // 127.0.0.1 only works on Simulator. For a real device use your Mac's LAN IP.
    // Run `ipconfig getifaddr en0` in Terminal to get the current IP if it changes.
    private let chatBaseURL = "http://10.105.191.51:3000/api"

    // MARK: - Fetch Rooms

    /// GET /chat/rooms
    func fetchRooms() -> AnyPublisher<[ChatRoom], Error> {
        return Future { [weak self] promise in
            Task {
                do {
                    let rooms: [ChatRoom] = try await self?.client.request(
                        path: "/chat/rooms",
                        method: .get,
                        requiresAuth: false, // 👈 Disabled for local testing
                        baseURL: self?.chatBaseURL
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
                do {
                    let messages: [ChatMessage] = try await self?.client.request(
                        path: "/chat/rooms/\(roomId.uuidString)/messages",
                        method: .get,
                        requiresAuth: false, // 👈 Disabled for local testing
                        baseURL: self?.chatBaseURL
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
                do {
                    let sentMessage: ChatMessage = try await self?.client.request(
                        path: "/chat/rooms/\(message.roomId.uuidString)/messages",
                        method: .post,
                        body: message,
                        requiresAuth: false, // 👈 Disabled for local testing
                        baseURL: self?.chatBaseURL
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
                do {
                    let _: EmptyResponse = try await self?.client.request(
                        path: "/chat/rooms/\(roomId.uuidString)/read",
                        method: .put,
                        requiresAuth: false, // 👈 Disabled for local testing
                        baseURL: self?.chatBaseURL
                    ) ?? EmptyResponse()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
