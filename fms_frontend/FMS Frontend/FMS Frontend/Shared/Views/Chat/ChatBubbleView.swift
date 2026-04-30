
//
//  ChatBubbleView.swift
//  FMS Chat — Chat Module
//
//  ✅ DRAG THIS FILE (inside Chat/ folder) into the main project.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    @State private var translatedText: String?
    @State private var isTranslating = false
    @State private var targetLanguage: String = Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "en") ?? "English"
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isCurrentUser { Spacer(minLength: 60) }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name only for groups and not current user
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
                // Tail effect via masked corners
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
                                translateMessage(forceTranslate: true)
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
                                translatedText = nil
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
    
    private func translateMessage(forceTranslate: Bool = false) {
        if !forceTranslate && translatedText != nil {
            translatedText = nil // Toggle translation off
            return
        }
        
        isTranslating = true
        translatedText = nil
        Task {
            do {
                let result = try await TranslationService.shared.translate(message.content, to: targetLanguage)
                DispatchQueue.main.async {
                    self.translatedText = result
                    self.isTranslating = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.translatedText = "⚠️ Translation unavailable"
                    self.isTranslating = false
                    print("Translation Error: \(error)")
                }
            }
        }
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

// MARK: - Helpers

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerStyle(radius: radius, corners: corners))
    }
}

struct RoundedCornerStyle: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        VStack(spacing: 20) {
            ChatBubbleView(message: ChatMessage(roomId: UUID(), senderId: "1", senderName: "John Doe", senderRole: "driver", content: "Hello! Is the truck ready for pickup?"), isCurrentUser: false)
            ChatBubbleView(message: ChatMessage(roomId: UUID(), senderId: "current_user", senderName: "Dave", senderRole: "maintenance", content: "Almost done. Just finishing the inspection."), isCurrentUser: true)
        }
    }
}
