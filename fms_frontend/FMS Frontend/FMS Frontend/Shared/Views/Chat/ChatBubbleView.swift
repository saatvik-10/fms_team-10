
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
                
                Text(message.content)
                    .font(.system(size: 16))
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
                    .onLongPressGesture {
                        // We'll need access to the ViewModel here, 
                        // or better, handle it in ChatRoomView via a callback or environment
                        NotificationCenter.default.post(name: NSNotification.Name("ToggleStar"), object: message)
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
