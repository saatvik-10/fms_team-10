//
//  ChatBubbleView.swift
//  Created by Monica Rokade
//

import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    @ObservedObject var viewModel: ChatViewModel
    
    @State private var targetLanguage: String = Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "en") ?? "English"
    
    private var translatedText: String? {
        viewModel.translations[message.id]
    }
    
    private var isTranslating: Bool {
        viewModel.translatingMessageIds.contains(message.id)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isCurrentUser { Spacer(minLength: 60) }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.leading, 12)
                }
                
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                    Text(message.content)
                        .font(.system(size: 16))
                    
                    if let translated = translatedText {
                        Divider()
                            .background(isCurrentUser ? Color.white.opacity(0.5) : Color.gray.opacity(0.3))
                        Text(translated)
                            .font(.system(size: 15, weight: .regular))
                            .italic()
                    } else if isTranslating {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isCurrentUser ? AppColors.primary : Color(white: 0.92))
                .foregroundColor(isCurrentUser ? .white : .black)
                .cornerRadius(20)
                .background(
                    BubbleTail(isCurrentUser: isCurrentUser)
                        .fill(isCurrentUser ? AppColors.primary : Color(white: 0.92))
                )
                .contextMenu {
                    Button(action: {
                        NotificationCenter.default.post(name: NSNotification.Name("ToggleStar"), object: message)
                    }) {
                        Label(message.isStarred ? "Unstar" : "Star", systemImage: message.isStarred ? "star.slash" : "star")
                    }
                    
                    Menu {
                        let languages = ["English", "Hindi", "Bengali", "Telugu", "Marathi", "Tamil", "Urdu", "Gujarati", "Kannada", "Malayalam", "Punjabi", "Spanish", "French", "German", "Chinese", "Arabic"]
                        ForEach(languages, id: \.self) { lang in
                            Button(action: {
                                targetLanguage = lang
                                viewModel.translateMessage(message, to: lang, force: true)
                            }) {
                                Text(lang)
                                if targetLanguage == lang && translatedText != nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        if translatedText != nil {
                            Divider()
                            Button(role: .destructive, action: {
                                viewModel.translateMessage(message, to: targetLanguage, force: false)
                            }) {
                                Label("Remove Translation", systemImage: "xmark.circle")
                            }
                        }
                    } label: {
                        Label("Translate", systemImage: "globe")
                    }
                }
                
                HStack(spacing: 4) {
                    if message.isStarred {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    
                    if isCurrentUser {
                        Text(message.status.rawValue.capitalized)
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !isCurrentUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 10)
    }
}

struct BubbleTail: Shape {
    let isCurrentUser: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isCurrentUser {
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - 10, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 10))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + 10, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 10))
        }
        return path
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        VStack(spacing: 20) {
            ChatBubbleView(message: ChatMessage(roomId: UUID(), senderId: "1", senderName: "John Doe", senderRole: "driver", content: "Hello! Is the truck ready for pickup?"), isCurrentUser: false, viewModel: ChatViewModel())
            ChatBubbleView(message: ChatMessage(roomId: UUID(), senderId: "current_user", senderName: "Dave", senderRole: "maintenance", content: "Almost done. Just finishing the inspection."), isCurrentUser: true, viewModel: ChatViewModel())
        }
    }
}
