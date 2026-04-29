
import SwiftUI
import Combine
import UserNotifications

class ChatViewModel: ObservableObject {
    @Published var rooms: [ChatRoom] = []
    @Published var messages: [UUID: [ChatMessage]] = [:] // RoomID -> Messages
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var availableUsers: [ChatService.UserContact] = []
    
    // Notification state
    @Published var latestNotification: ChatMessage?
    @Published var showNotification = false
    
    // Track current user
    @Published var currentUserId: String?
    private var currentUserName: String?
    private var currentUserRole: String?
    
    // Track current active room to avoid notifying for the room the user is in
    static var activeRoomId: UUID?
    
    private let chatService = ChatService()
    private let pusher = PusherService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupPusherSubscription()
    }
    
    func configure(userId: String, name: String, role: String) {
        guard userId != "unknown" else {
            print("⚠️ ChatViewModel: Skipping configuration for 'unknown' user")
            return
        }
        
        self.currentUserId = userId
        self.currentUserName = name
        self.currentUserRole = role
        
        // Clear previous state
        self.rooms = []
        self.messages = [:]
        
        pusher.connect(userId: userId)
        pusher.subscribeToUser(userId: userId)
        loadRooms()
        loadAvailableUsers()
    }
    
    private func setupPusherSubscription() {
        pusher.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleIncomingMessage(message)
            }
            .store(in: &cancellables)
    }
    
    private func handleIncomingMessage(_ message: ChatMessage) {
        // Get the current list for this room
        var roomMessages = messages[message.roomId] ?? []
        
        // Dedup — don't add if already present
        guard !roomMessages.contains(where: { $0.id == message.id }) else { return }
        roomMessages.append(message)
        
        // ⚡ CRITICAL: Reassign the entire dictionary (not just a subscript value).
        // SwiftUI's @Published observation can miss nested dictionary mutations via subscript.
        // A full assignment guarantees objectWillChange fires and the view re-renders.
        objectWillChange.send()
        var updated = messages
        updated[message.roomId] = roomMessages
        messages = updated
        
        print("📩 ChatViewModel: Added live message to room \(message.roomId) — total: \(roomMessages.count)")
        
        // Update room's last message and re-sort
        if let index = rooms.firstIndex(where: { $0.id == message.roomId }) {
            var updatedRooms = rooms
            updatedRooms[index].lastMessage = message
            updatedRooms[index].lastActivity = message.timestamp
            
            // Increment unread count only if not the active room and not sent by us
            if message.roomId != ChatViewModel.activeRoomId && message.senderId != currentUserId {
                updatedRooms[index].unreadCount += 1
            }
            
            rooms = updatedRooms.sorted(by: { $0.lastActivity > $1.lastActivity })
        } else {
            // 💡 NEW: If the room doesn't exist yet (e.g., someone just started a chat with us),
            // reload the entire room list so it appears in the UI.
            print("🆕 ChatViewModel: Received message for unknown room \(message.roomId) — reloading rooms...")
            loadRooms()
        }
        
        // Post notification only if not currently in the room
        if message.roomId != ChatViewModel.activeRoomId && message.senderId != currentUserId {
            NotificationKit.shared.postNotification(
                title: message.senderName,
                subtitle: message.senderRole.capitalized,
                body: message.content,
                userInfo: ["roomId": message.roomId.uuidString, "senderId": message.senderId]
            )
        }
    }
    
    // MARK: - API Actions
    
    func loadRooms() {
        guard let userId = currentUserId, userId != "unknown" else { return }
        
        isLoading = true
        chatService.fetchRooms()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] rooms in
                self?.rooms = rooms.sorted(by: { $0.lastActivity > $1.lastActivity })
                
                // 📡 NEW: Subscribe to ALL rooms for real-time updates (unread counts, previews)
                // even when we are just looking at the room list.
                rooms.forEach { room in
                    self?.pusher.subscribeToRoom(roomId: room.id)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadMessages(for roomId: UUID) {
        isLoading = true
        pusher.subscribeToRoom(roomId: roomId)
        
        chatService.fetchMessages(for: roomId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] messages in
                self?.messages[roomId] = messages
            }
            .store(in: &cancellables)
    }
    
    func sendMessage(content: String, in roomId: UUID) {
        guard let userId = currentUserId, userId != "unknown",
              let userName = currentUserName,
              let userRole = currentUserRole else { return }
        
        let newMessage = ChatMessage(
            roomId: roomId,
            senderId: userId,
            senderName: userName,
            senderRole: userRole,
            content: content
        )
        
        // Optimistic UI update
        if var roomMessages = messages[roomId] {
            roomMessages.append(newMessage)
            messages[roomId] = roomMessages
        }
        
        chatService.sendMessage(newMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to send: \(error.localizedDescription)"
                    // Ideally: remove the optimistic message or show error state
                }
            } receiveValue: { [weak self] sentMessage in
                // Update with server-confirmed message if needed (e.g. real timestamp/ID)
                if let index = self?.messages[roomId]?.firstIndex(where: { $0.id == newMessage.id }) {
                    self?.messages[roomId]?[index] = sentMessage
                }
            }
            .store(in: &cancellables)
    }
    
    func markAsRead(roomId: UUID) {
        if let index = self.rooms.firstIndex(where: { $0.id == roomId }) {
            self.rooms[index].unreadCount = 0
        }
        
        chatService.markRead(roomId: roomId)
            .sink { _ in } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func startNewConversation(with name: String, initials: String, role: String, targetId: String, initialMessage: String) {
        guard let userId = currentUserId, userId != "unknown",
              let userName = currentUserName,
              let userRole = currentUserRole else { return }
              
        isLoading = true
        chatService.createRoom(
            targetId: targetId,
            senderId: userId,
            senderName: userName,
            senderRole: userRole,
            initialMessage: initialMessage
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to start chat: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] newRoom in
                var room = newRoom
                if room.lastMessage == nil {
                    let injectedMessage = ChatMessage(
                        roomId: room.id,
                        senderId: userId,
                        senderName: userName,
                        senderRole: userRole,
                        content: initialMessage
                    )
                    room.lastMessage = injectedMessage
                }
                
                // Add the new room to the top of the list
                self?.rooms.insert(room, at: 0)
                
                // Subscribe and fetch history
                self?.pusher.subscribeToRoom(roomId: room.id)
                self?.loadMessages(for: room.id)
            }
            .store(in: &cancellables)
    }
    
    func deleteRoom(at offsets: IndexSet) {
        // TODO: Implement DELETE /chat/rooms/{id}
        offsets.forEach { index in
            let room = self.rooms[index]
            self.rooms.remove(at: index)
            self.messages.removeValue(forKey: room.id)
        }
    }
    
    func toggleStar(for messageId: UUID, in roomId: UUID) {
        if let index = messages[roomId]?.firstIndex(where: { $0.id == messageId }) {
            messages[roomId]?[index].isStarred.toggle()
            // TODO: API call to sync starred status
        }
    }

    func loadAvailableUsers() {
        chatService.fetchUsers()
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] users in
                self?.availableUsers = users
            }
            .store(in: &cancellables)
    }
}
