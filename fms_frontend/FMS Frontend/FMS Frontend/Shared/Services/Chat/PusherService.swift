
import Foundation
import Combine
import PusherSwift

final class PusherService: ObservableObject, PusherDelegate {
    static let shared = PusherService()
    
    // MARK: - Credentials (PLACEHOLDERS)
    // 💡 Fill these from your Pusher Dashboard (App Keys tab)
    private let pusherAppKey = "b73a2a2fb84d3828322a"
    private let pusherCluster = "ap2" 
    
    private var pusher: Pusher?
    private var currentChannel: PusherChannel?
    
    private let messageSubject = PassthroughSubject<ChatMessage, Never>()
    var messagePublisher: AnyPublisher<ChatMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    private init() {
        setupPusher()
    }
    
    private func setupPusher() {
        let options = PusherClientOptions(
            host: .cluster(pusherCluster)
        )
        
        pusher = Pusher(key: pusherAppKey, options: options)
        pusher?.delegate = self
    }
    
    func connect(userId: String) {
        print("📡 Pusher: Attempting to connect for user \(userId)...")
        pusher?.connect()
    }
    
    func subscribeToRoom(roomId: UUID) {
        let cleanId = roomId.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let channelName = "chat_\(cleanId)"
        print("📡 Pusher: Subscribing to \(channelName)")
        
        currentChannel = pusher?.subscribe(channelName)
        
        // Bind to the "new-message" event
        currentChannel?.bind(eventName: "new-message", eventCallback: { [weak self] event in
            guard let self = self,
                  let dataString = event.data,
                  let data = try? JSONSerialization.jsonObject(with: Data(dataString.utf8)) as? [String: Any] else { return }
            
            if let message = self.decodeMessage(from: data) {
                self.messageSubject.send(message)
            }
        })
    }
    
    func disconnect() {
        print("📡 Pusher: Disconnecting")
        pusher?.disconnect()
    }
    
    // MARK: - Decoding Logic
    
    private func decodeMessage(from data: [String: Any]) -> ChatMessage? {
        // This helper maps the JSON from Pusher to your ChatMessage model
        guard let idString = data["id"] as? String, let id = UUID(uuidString: idString),
              let roomIdString = data["roomId"] as? String, let roomId = UUID(uuidString: roomIdString),
              let senderId = data["senderId"] as? String,
              let senderName = data["senderName"] as? String,
              let senderRole = data["senderRole"] as? String,
              let content = data["content"] as? String else {
            return nil
        }
        
        return ChatMessage(
            id: id,
            roomId: roomId,
            senderId: senderId,
            senderName: senderName,
            senderRole: senderRole,
            content: content,
            timestamp: Date() // Or decode from data["timestamp"] if provided
        )
    }
    
    // MARK: - PusherDelegate
    
    func debugLog(message: String) {
        print("🛠️ Pusher Debug: \(message)")
    }
    
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        print("📡 Pusher: Connection state changed from \(old) to \(new)")
    }
}
