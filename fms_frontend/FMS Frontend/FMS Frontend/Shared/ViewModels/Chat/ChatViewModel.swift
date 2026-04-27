
//
//  ChatViewModel.swift
//  FMS Chat — Chat Module
//
//  ✅ DRAG THIS FILE (inside Chat/ folder) into the main project.
//

import SwiftUI
import Combine
import UserNotifications



class ChatViewModel: ObservableObject {
    // Shared store for the simulation so role switching doesn't wipe data
    private static var sharedRooms: [ChatRoom] = []
    private static var sharedMessages: [UUID: [ChatMessage]] = [:]
    
    @Published var rooms: [ChatRoom] = []
    @Published var messages: [UUID: [ChatMessage]] = [:] // RoomID -> Messages
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Notification state
    @Published var latestNotification: ChatMessage?
    @Published var showNotification = false
    
    // Track current active room to avoid notifying for the room the user is in
    static var activeRoomId: UUID?
    
    private let chatService = ChatService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize from shared store if not empty, otherwise load mocks
        if ChatViewModel.sharedRooms.isEmpty {
            ChatViewModel.sharedRooms = getMockRooms()
        }
        syncWithStore()
    }
    
    private func syncWithStore() {
        self.rooms = ChatViewModel.sharedRooms
        self.messages = ChatViewModel.sharedMessages
    }
    
    private func updateStore() {
        ChatViewModel.sharedRooms = self.rooms
        ChatViewModel.sharedMessages = self.messages
    }
    
    // MARK: - Simulation Actions
    
    func startNewConversation(with name: String, initials: String, role: String, targetId: String, initialMessage: String) {
        let roomId = UUID()
        let currentUserId = "mock_user_id"
        let currentUserName = "Mock User"
        let currentUserRole = "driver"
        
        let newRoom = ChatRoom(
            id: roomId,
            name: name,
            avatarInitials: initials,
            roomType: .direct,
            participants: [currentUserId, targetId],
            participantNames: [
                currentUserId: currentUserName,
                targetId: name
            ]
        )
        
        let firstMsg = ChatMessage(
            roomId: roomId,
            senderId: currentUserId,
            senderName: currentUserName,
            senderRole: currentUserRole,
            content: initialMessage
        )
        
        // Add to store
        ChatViewModel.sharedRooms.insert(newRoom, at: 0)
        ChatViewModel.sharedMessages[roomId] = [firstMsg]
        
        // Update local room with last message
        if let index = ChatViewModel.sharedRooms.firstIndex(where: { $0.id == roomId }) {
            ChatViewModel.sharedRooms[index].lastMessage = firstMsg
        }
        
        syncWithStore()
    }
    
    func deleteRoom(at offsets: IndexSet) {
        offsets.forEach { index in
            let room = self.rooms[index]
            ChatViewModel.sharedRooms.removeAll(where: { $0.id == room.id })
            ChatViewModel.sharedMessages.removeValue(forKey: room.id)
        }
        syncWithStore()
    }
    
    func toggleStar(for messageId: UUID, in roomId: UUID) {
        if let roomMessages = ChatViewModel.sharedMessages[roomId],
           let index = roomMessages.firstIndex(where: { $0.id == messageId }) {
            ChatViewModel.sharedMessages[roomId]?[index].isStarred.toggle()
            syncWithStore()
        }
    }
    
    // MARK: - API Actions
    
    func loadRooms() {
        isLoading = true
        // If we have simulation rooms, we'll keep them
        if ChatViewModel.sharedRooms.isEmpty {
            ChatViewModel.sharedRooms = getMockRooms()
        }
        syncWithStore()
        isLoading = false
    }
    
    func loadMessages(for roomId: UUID) {
        if ChatViewModel.sharedMessages[roomId] == nil {
            ChatViewModel.sharedMessages[roomId] = getMockMessages(for: roomId)
        }
        syncWithStore()
    }
    
    func sendMessage(content: String, in roomId: UUID) {
        let currentUserId = "mock_user_id"
        let currentUserName = "Mock User"
        let currentUserRole = "driver"
        
        let newMessage = ChatMessage(
            roomId: roomId,
            senderId: currentUserId,
            senderName: currentUserName,
            senderRole: currentUserRole,
            content: content
        )
        
        // Update shared store
        ChatViewModel.sharedMessages[roomId]?.append(newMessage)
        
        if let index = ChatViewModel.sharedRooms.firstIndex(where: { $0.id == roomId }) {
            ChatViewModel.sharedRooms[index].lastMessage = newMessage
            ChatViewModel.sharedRooms[index].lastActivity = Date()
            ChatViewModel.sharedRooms.sort(by: { $0.lastActivity > $1.lastActivity })
        }
        
        // Simulation: Use NotificationKit to alert other roles
        NotificationKit.shared.postNotification(
            title: newMessage.senderName,
            subtitle: newMessage.senderRole.capitalized,
            body: newMessage.content,
            userInfo: ["roomId": roomId.uuidString, "senderId": newMessage.senderId]
        )
        
        syncWithStore()
    }
    
    func markAsRead(roomId: UUID) {
        if let index = self.rooms.firstIndex(where: { $0.id == roomId }) {
            self.rooms[index].unreadCount = 0
        }
        
        chatService.markRead(roomId: roomId)
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    // MARK: - Mock Data
    
    private func getMockRooms() -> [ChatRoom] {
        let role = "driver"
        
        var rooms: [ChatRoom] = []
        
        // Common System Broadcast for all
        let systemId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        rooms.append(ChatRoom(
            id: systemId,
            name: "Fleet System Alerts",
            avatarInitials: "!!",
            roomType: .broadcast,
            lastMessage: ChatMessage(roomId: systemId, senderId: "system", senderName: "System", senderRole: "manager", content: "Severe weather warning for Northern Route. Drive safe."),
            unreadCount: 0,
            lastActivity: Date().addingTimeInterval(-3600)
        ))
        
        if role == "driver" {
            let mgrId = UUID()
            rooms.append(ChatRoom(
                id: mgrId,
                name: "Sarah (Fleet Manager)",
                avatarInitials: "SM",
                roomType: .direct,
                participants: ["chad_user", "manager_user"],
                participantNames: ["chad_user": "Chad", "manager_user": "Sarah (Fleet Manager)"],
                lastMessage: ChatMessage(roomId: mgrId, senderId: "manager_user", senderName: "Sarah Manager", senderRole: "manager", content: "Confirming your pickup at Dock 4."),
                unreadCount: 1,
                lastActivity: Date().addingTimeInterval(-600)
            ))
            
            let maintId = UUID()
            rooms.append(ChatRoom(
                id: maintId,
                name: "Main Shop (Support)",
                avatarInitials: "MS",
                roomType: .group,
                participants: ["chad_user", "maint_1"],
                participantNames: ["chad_user": "Chad", "maint_1": "Main Shop (Support)"],
                lastMessage: ChatMessage(roomId: maintId, senderId: "maint_1", senderName: "Mike Mechanic", senderRole: "maintenance", content: "Truck #202 is ready for you."),
                unreadCount: 0,
                lastActivity: Date().addingTimeInterval(-1200)
            ))
        } else if role == "maintenance" {
            let teamId = UUID()
            rooms.append(ChatRoom(
                id: teamId,
                name: "Night Shift Team",
                avatarInitials: "NS",
                roomType: .group,
                participants: ["john_user", "maint_2"],
                participantNames: ["john_user": "John", "maint_2": "Night Shift Team"],
                lastMessage: ChatMessage(roomId: teamId, senderId: "maint_2", senderName: "Pete", senderRole: "maintenance", content: "Inventory updated for the brake pads."),
                unreadCount: 3,
                lastActivity: Date().addingTimeInterval(-300)
            ))
            
            let driverId = UUID()
            rooms.append(ChatRoom(
                id: driverId,
                name: "Dave (Driver #402)",
                avatarInitials: "DD",
                roomType: .direct,
                participants: ["john_user", "driver_1"],
                participantNames: ["john_user": "John", "driver_1": "Dave (Driver #402)"],
                lastMessage: ChatMessage(roomId: driverId, senderId: "driver_1", senderName: "Dave", senderRole: "driver", content: "The steering feels a bit loose today."),
                unreadCount: 0,
                lastActivity: Date().addingTimeInterval(-1800)
            ))
        } else if role == "manager" {
            let opsId = UUID()
            rooms.append(ChatRoom(
                id: opsId,
                name: "Operations Hub",
                avatarInitials: "OH",
                roomType: .group,
                participants: ["manager_user", "ops_1"],
                participantNames: ["manager_user": "Fleet Manager", "ops_1": "Operations Hub"],
                lastMessage: ChatMessage(roomId: opsId, senderId: "ops_1", senderName: "Dispatch", senderRole: "manager", content: "All routes for today have been assigned."),
                unreadCount: 0,
                lastActivity: Date().addingTimeInterval(-150)
            ))
            
            let urgentId = UUID()
            rooms.append(ChatRoom(
                id: urgentId,
                name: "Urgent: Breakdown Support",
                avatarInitials: "!!",
                roomType: .group,
                participants: ["manager_user", "driver_2"],
                participantNames: ["manager_user": "Fleet Manager", "driver_2": "Urgent: Breakdown Support"],
                lastMessage: ChatMessage(roomId: urgentId, senderId: "driver_2", senderName: "Alex", senderRole: "driver", content: "Engine overheating on I-95."),
                unreadCount: 5,
                lastActivity: Date().addingTimeInterval(-60)
            ))
        }
        
        return rooms.sorted(by: { $0.lastActivity > $1.lastActivity })
    }
    
    private func getMockMessages(for roomId: UUID) -> [ChatMessage] {
        let role = "driver"
        let room = rooms.first(where: { $0.id == roomId })
        let name = room?.name ?? ""
        
        if name.contains("Sarah") {
            return [
                ChatMessage(roomId: roomId, senderId: "current_user", senderName: "Driver", senderRole: "driver", content: "Hey Sarah, I'm at the terminal now.", timestamp: Date().addingTimeInterval(-1200)),
                ChatMessage(roomId: roomId, senderId: "manager_id", senderName: "Sarah Manager", senderRole: "manager", content: "Great. Proceed to Dock 4 for the electronics shipment.", timestamp: Date().addingTimeInterval(-1100)),
                ChatMessage(roomId: roomId, senderId: "current_user", senderName: "Driver", senderRole: "driver", content: "Got it. Documents are ready?", timestamp: Date().addingTimeInterval(-1000)),
                ChatMessage(roomId: roomId, senderId: "manager_id", senderName: "Sarah Manager", senderRole: "manager", content: "Yes, they are with the gate officer.", timestamp: Date().addingTimeInterval(-900)),
                ChatMessage(roomId: roomId, senderId: "manager_id", senderName: "Sarah Manager", senderRole: "manager", content: "Confirming your pickup at Dock 4.", timestamp: Date().addingTimeInterval(-600), status: .read)
            ]
        } else if name.contains("Night Shift") {
            return [
                ChatMessage(roomId: roomId, senderId: "maint_1", senderName: "John", senderRole: "maintenance", content: "Did we get the shipment for the air filters?", timestamp: Date().addingTimeInterval(-3600)),
                ChatMessage(roomId: roomId, senderId: "current_user", senderName: "Pete", senderRole: "maintenance", content: "Checking the log now...", timestamp: Date().addingTimeInterval(-3400)),
                ChatMessage(roomId: roomId, senderId: "current_user", senderName: "Pete", senderRole: "maintenance", content: "Yes, arrived at 4 PM. 20 units.", timestamp: Date().addingTimeInterval(-3200)),
                ChatMessage(roomId: roomId, senderId: "maint_2", senderName: "Pete", senderRole: "maintenance", content: "Inventory updated for the brake pads.", timestamp: Date().addingTimeInterval(-300))
            ]
        } else if name.contains("Breakdown") {
            return [
                ChatMessage(roomId: roomId, senderId: "driver_2", senderName: "Alex", senderRole: "driver", content: "Truck #109 is losing power.", timestamp: Date().addingTimeInterval(-600)),
                ChatMessage(roomId: roomId, senderId: "current_user", senderName: "Manager", senderRole: "manager", content: "Copy that Alex. What is your current location?", timestamp: Date().addingTimeInterval(-550)),
                ChatMessage(roomId: roomId, senderId: "driver_2", senderName: "Alex", senderRole: "driver", content: "Just passed Mile Marker 42 on I-95 North.", timestamp: Date().addingTimeInterval(-500)),
                ChatMessage(roomId: roomId, senderId: "current_user", senderName: "Manager", senderRole: "manager", content: "Stay with the vehicle. Dispatching a tow and a relief driver now.", timestamp: Date().addingTimeInterval(-400)),
                ChatMessage(roomId: roomId, senderId: "driver_2", senderName: "Alex", senderRole: "driver", content: "Engine overheating on I-95.", timestamp: Date().addingTimeInterval(-60))
            ]
        }
        
        return []
    }
}
