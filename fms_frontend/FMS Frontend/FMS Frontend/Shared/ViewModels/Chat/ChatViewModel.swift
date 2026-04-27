
import SwiftUI
import Combine
import UserNotifications

class ChatViewModel: ObservableObject {
    @Published var rooms: [ChatRoom] = []
    @Published var messages: [UUID: [ChatMessage]] = [:] // RoomID -> Messages
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
        self.currentUserId = userId
        self.currentUserName = name
        self.currentUserRole = role
        
        pusher.connect(userId: userId)
        loadRooms()
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
        // 1. Update messages list
        var roomMessages = messages[message.roomId] ?? []
        if !roomMessages.contains(where: { $0.id == message.id }) {
            roomMessages.append(message)
            messages[message.roomId] = roomMessages
            print("📩 ChatViewModel: Added live message to room \(message.roomId)")
        }
        
        // 2. Update room's last message and activity
        if let index = rooms.firstIndex(where: { $0.id == message.roomId }) {
            rooms[index].lastMessage = message
            rooms[index].lastActivity = message.timestamp
            
            // Increment unread count if not active room
            if message.roomId != ChatViewModel.activeRoomId && message.senderId != currentUserId {
                rooms[index].unreadCount += 1
            }
            
            // Re-sort rooms
            rooms.sort(by: { $0.lastActivity > $1.lastActivity })
        }
        
        // 3. Post internal notification if not in the room
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
        guard currentUserId != nil else { return }
        
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
        guard let userId = currentUserId,
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
        // In a "proper" setup, this would be a POST to /chat/rooms/create
        // For now, we'll stick to the existing rooms or handle creation if the API supports it.
        print("Creating new conversation with \(name)...")
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
}
