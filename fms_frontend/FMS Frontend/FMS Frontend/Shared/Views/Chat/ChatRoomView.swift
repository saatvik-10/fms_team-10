
//
//  ChatRoomView.swift
//  FMS Chat — Chat Module
//
//  ✅ DRAG THIS FILE (inside Chat/ folder) into the main project.
//

import SwiftUI

struct ChatRoomView: View {
    @ObservedObject var viewModel: ChatViewModel
    let room: ChatRoom
    
    @State private var messageText: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let messages = viewModel.messages[room.id] {
                            ForEach(messages) { message in
                                ChatBubbleView(
                                    message: message,
                                    isCurrentUser: message.senderId == "mock_user_id"
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(AppColors.background)
                .onChange(of: viewModel.messages[room.id]) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    viewModel.loadMessages(for: room.id)
                    viewModel.markAsRead(roomId: room.id)
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // Input Area
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    Button(action: { /* Media selection */ }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1...5)
                    
                    if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(action: { /* Voice record */ }) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.primary)
                        }
                    } else {
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(AppColors.primary)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
        .background(Color.white)
        .navigationTitle(room.displayName(for: "mock_user_id"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            ChatViewModel.activeRoomId = room.id
        }
        .onDisappear {
            ChatViewModel.activeRoomId = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleStar"))) { note in
            if let msg = note.object as? ChatMessage {
                viewModel.toggleStar(for: msg.id, in: room.id)
            }
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        viewModel.sendMessage(content: text, in: room.id)
        messageText = ""
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let messages = viewModel.messages[room.id], let last = messages.last else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}
