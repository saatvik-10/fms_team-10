//
//  ChatRoomView.swift
//  Created by Gargee Mohairr
//

import SwiftUI
import Speech

struct ChatRoomView: View {
    @ObservedObject var viewModel: ChatViewModel
    let room: ChatRoom
    
    @State private var messageText: String = ""
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var speechService = SpeechService()
    @State private var isTranslatingInput = false

    
    // Dynamically load all supported Apple Speech languages
    var availableLanguages: [(String, String)] {
        SFSpeechRecognizer.supportedLocales()
            .map { locale in
                let name = Locale.current.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
                return (name, locale.identifier)
            }
            .sorted { $0.0 < $1.0 }
    }
    
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
                                    isCurrentUser: message.senderId == (viewModel.currentUserId ?? ""),
                                    viewModel: viewModel
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(AppColors.background)
                // Observe message COUNT (Int)  much more reliably tracked by SwiftUI
                // than observing the whole [ChatMessage]? optional array.
                .onChange(of: viewModel.messages[room.id]?.count ?? 0) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    viewModel.loadMessages(for: room.id)
                    viewModel.markAsRead(roomId: room.id)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        scrollToBottom(proxy: proxy)
                    }
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
                    
                    if speechService.isRecording {
                        Button(action: { speechService.stopRecording() }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                        }
                    } else if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Menu {
                            ForEach(availableLanguages, id: \.1) { lang in
                                Button(action: {
                                    speechService.updateLocale(lang.1)
                                    try? speechService.startRecording()
                                }) {
                                    HStack {
                                        Text(lang.0)
                                        if speechService.selectedLocale.identifier == lang.1 {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.primary)
                        }
                    } else {
                        if isTranslatingInput {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.horizontal, 4)
                        } else {
                            Menu {
                                ForEach(availableLanguages, id: \.1) { lang in
                                    Button(action: {
                                        // Pass the human-readable language name (lang.0) to the LLM instead of locale code
                                        translateInput(to: lang.0)
                                    }) {
                                        Text(lang.0)
                                    }
                                }
                            } label: {
                                Image(systemName: "globe")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        
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
        .navigationTitle(room.displayName(for: viewModel.currentUserId ?? ""))
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
        .onChange(of: speechService.recognizedText) { newText in
            if speechService.isRecording && !newText.isEmpty {
                messageText = newText
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
    
    private func translateInput(to language: String) {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        isTranslatingInput = true
        Task {
            do {
                let result = try await TranslationService.shared.translate(text, to: language)
                DispatchQueue.main.async {
                    self.messageText = result
                    self.isTranslatingInput = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isTranslatingInput = false
                }
            }
        }
    }
}
