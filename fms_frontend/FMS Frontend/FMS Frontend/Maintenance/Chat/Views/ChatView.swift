//
//  ChatView.swift
//  FMS Frontend
//
//  Created by Antigravity on 16/04/26.
//

import SwiftUI

struct ChatView: View {
    var body: some View {
        ZStack {
            AppColors.screenBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Professional Illustration Placeholder
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.05))
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary)
                        .offset(y: -5)
                }
                
                VStack(spacing: 8) {
                    Text("Fleet Communication")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Secure messaging with drivers and fleet managers is coming soon.")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Button(action: { /* Notify me or Contact Ops */ }) {
                    Text("Contact Fleet Operations")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                }
                
                Spacer()
                Spacer()
            }
        }
        .navigationTitle("Chat")
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChatView()
        }
    }
}
