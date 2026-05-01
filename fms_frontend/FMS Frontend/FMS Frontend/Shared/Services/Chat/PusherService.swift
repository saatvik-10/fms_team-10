//
//  PusherService.swift
//  Created by Kunal Khude
//

import Foundation
import Combine
import PusherSwift

final class PusherService: ObservableObject, PusherDelegate {
    static let shared = PusherService()
    
    // MARK: - Credentials (PLACEHOLDERS)
    //  Fill these from your Pusher Dashboard (App Keys tab)
    private let pusherAppKey = "b73a2a2fb84d3828322a"
    private let pusherCluster = "ap2" 
    
    private var pusher: Pusher?
    private var userChannel: PusherChannel?
    
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
        print("[DEBUG] [DEBUG]  Pusher: Attempting to connect for user \(userId)...")
        pusher?.connect()
    }
    
    func subscribeToRoom(roomId: UUID) {
        let cleanId = roomId.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let channelName = "chat_\(cleanId)"
        
        // Avoid duplicate room subscriptions
        if let existing = pusher?.connection.channels.find(name: channelName), existing.subscribed {
            print("[DEBUG] [DEBUG]  Pusher: Already subscribed to \(channelName)")
            return
        }
        
        print("[DEBUG] [DEBUG]  Pusher: Subscribing to \(channelName)")
        let channel = pusher?.subscribe(channelName)
        
        // Bind to the "new-message" event
        channel?.bind(eventName: "new-message", eventCallback: { [weak self] event in
            guard let self = self,
                  let dataString = event.data,
                  let data = try? JSONSerialization.jsonObject(with: Data(dataString.utf8)) as? [String: Any] else { return }
            
            if let message = self.decodeMessage(from: data) {
                self.messageSubject.send(message)
            }
        })
    }
    
    func subscribeToUser(userId: String) {
        let cleanId = userId.replacingOccurrences(of: "-", with: "").lowercased()
        let channelName = "user_\(cleanId)"
        
        if let current = userChannel, current.name == channelName {
            print("[DEBUG] [DEBUG]  Pusher: Already subscribed to user channel \(channelName)")
            return
        }
        
        // Unsubscribe from previous user channel if any
        if let current = userChannel {
            print("[DEBUG] [DEBUG]  Pusher: Unsubscribing from old user channel \(current.name)")
            pusher?.unsubscribe(current.name)
        }
        
        print("[DEBUG] [DEBUG]  Pusher: Subscribing to user channel \(channelName)")
        userChannel = pusher?.subscribe(channelName)
        
        // Bind to "new-message" on the user channel as well
        userChannel?.bind(eventName: "new-message", eventCallback: { [weak self] event in
            guard let self = self,
                  let dataString = event.data,
                  let data = try? JSONSerialization.jsonObject(with: Data(dataString.utf8)) as? [String: Any] else { return }
            
            if let message = self.decodeMessage(from: data) {
                self.messageSubject.send(message)
            }
        })
    }
    
    func disconnect() {
        print("[DEBUG] [DEBUG]  Pusher: Disconnecting")
        pusher?.disconnect()
        userChannel = nil
    }
    
    // MARK: - Decoding Logic
    
    private func decodeMessage(from data: [String: Any]) -> ChatMessage? {
        // Map backend's snake_case keys to ChatMessage properties
        guard let idString = data["id"] as? String, let id = UUID(uuidString: idString),
              let roomIdString = (data["room_id"] as? String) ?? (data["roomId"] as? String), 
              let roomId = UUID(uuidString: roomIdString),
              let senderId = (data["sender_id"] as? String) ?? (data["senderId"] as? String),
              let senderName = (data["sender_name"] as? String) ?? (data["senderName"] as? String),
              let senderRole = (data["sender_role"] as? String) ?? (data["senderRole"] as? String),
              let content = data["content"] as? String else {
            print("[ERROR] [ERROR]  Pusher: Failed to decode message data: \(data)")
            return nil
        }
        
        let timestamp: Date
        if let tsString = data["timestamp"] as? String {
            timestamp = ISO8601DateFormatter().date(from: tsString) ?? Date()
        } else {
            timestamp = Date()
        }
        
        return ChatMessage(
            id: id,
            roomId: roomId,
            senderId: senderId,
            senderName: senderName,
            senderRole: senderRole,
            content: content,
            timestamp: timestamp
        )
    }
    
    // MARK: - PusherDelegate
    
    func debugLog(message: String) {
        print("[DEBUG] [DEBUG]  Pusher Debug: \(message)")
    }
    
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        print("[DEBUG] [DEBUG]  Pusher: Connection state changed from \(old) to \(new)")
    }
}
