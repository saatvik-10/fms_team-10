//
//  LoginView.swift
//  FMS Frontend
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1A1C1E"), Color(hex: "0F1012")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo/Header
                    VStack(spacing: 16) {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        
                        VStack(spacing: 4) {
                            Text("FMS")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Fleet Management Solution")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                        }
                    }
                    
                    // Irnput Fields
                    VStack(spacing: 16) {
                        LoginTextField(icon: "envelope.fill", placeholder: "Enterprise Email", text: $email)
                        LoginSecureField(icon: "lock.fill", placeholder: "Password", text: $password)
                        
                        HStack {
                            Spacer()
                            Button("Forgot Password?") { }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Login Button
                    Button(action: {
                        isLoggingIn = true
                        // Simulate network delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            isLoggingIn = false
                            isLoggedIn = true
                        }
                    }) {
                        HStack {
                            if isLoggingIn {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 16, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .disabled(isLoggingIn || email.isEmpty || password.isEmpty)
                    
                    Spacer()
                    
                    // Footer
                    Text("© 2026 Antigravity Systems. All Rights Reserved.")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.bottom, 20)
                }
            }
        }
    }
}

struct LoginTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct LoginSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 20)
            SecureField(placeholder, text: $text)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
