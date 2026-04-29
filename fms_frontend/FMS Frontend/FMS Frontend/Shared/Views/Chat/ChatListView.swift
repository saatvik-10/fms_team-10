
//
//  ChatListView.swift
//  FMS Chat — Chat Module
//
//  ✅ DRAG THIS FILE (inside Chat/ folder) into the main project.
//

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var searchText = ""
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.rooms.isEmpty {
                ProgressView()
            } else {
                List {
                    ForEach(filteredRooms) { room in
                        NavigationLink(destination: ChatRoomView(viewModel: viewModel, room: room)) {
                            ChatRoomRow(room: room)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete(perform: viewModel.deleteRoom)
                }
                .listStyle(.plain)
                .refreshable {
                    viewModel.loadRooms()
                }
            }
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
        .onAppear {
            viewModel.loadRooms()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isShowingNewChat = true }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $isShowingNewChat) {
            NewChatView(viewModel: viewModel)
        }
    }
    
    @State private var isShowingNewChat = false
    
    private var filteredRooms: [ChatRoom] {
        if searchText.isEmpty {
            return viewModel.rooms
        } else {
            return viewModel.rooms.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct NewChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedContactId: String = ""
    @State private var message: String = ""
    
    private var availableContacts: [ChatService.UserContact] {
        viewModel.availableUsers.filter { $0.id != (viewModel.currentUserId ?? "") }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("To:") {
                    Picker("Contact", selection: $selectedContactId) {
                        if availableContacts.isEmpty {
                            Text("Loading users...").tag("")
                        }
                        ForEach(availableContacts, id: \.id) { contact in
                            Text("\(contact.name) (\(contact.role.capitalized))").tag(contact.id)
                        }
                    }
                }
                .onAppear {
                    if selectedContactId.isEmpty, let first = availableContacts.first {
                        selectedContactId = first.id
                    }
                }
                .onChange(of: availableContacts.count) { _ in
                    if selectedContactId.isEmpty, let first = availableContacts.first {
                        selectedContactId = first.id
                    }
                }
                
                Section("Message") {
                    TextField("Enter message...", text: $message, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        if let contact = availableContacts.first(where: { $0.id == selectedContactId }) {
                            viewModel.startNewConversation(
                                with: contact.name,
                                initials: contact.initials,
                                role: contact.role,
                                targetId: contact.id,
                                initialMessage: message
                            )
                        }
                        dismiss()
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedContactId.isEmpty)
                }
            }
        }
    }
}

struct ChatRoomRow: View {
    @EnvironmentObject var viewModel: ChatViewModel
    let room: ChatRoom
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Initials Circle
            ZStack {
                Circle()
                    .fill(AppColors.secondaryBackground)
                Text(room.displayInitials(for: viewModel.currentUserId ?? ""))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
            }
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(room.displayName(for: viewModel.currentUserId ?? ""))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(room.lastActivityFormatted)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(room.lastMessagePreview(for: viewModel.currentUserId))
                        .font(.system(size: 14))
                        .foregroundColor(room.unreadCount > 0 ? .primary : .gray)
                        .lineLimit(1)
                    Spacer()
                    if room.unreadCount > 0 {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        ChatListView()
    }
}
