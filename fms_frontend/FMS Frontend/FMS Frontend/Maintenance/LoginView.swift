//
//  LoginView.swift
//  FMS Frontend
//

import SwiftUI

struct LoginView: View {
    @Binding var userRole: UserRole
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo/Header
                    VStack(spacing: 16) {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.primary)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(AppColors.primary.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(AppColors.primary.opacity(0.15), lineWidth: 1)
                                    )
                            )
                        
                        VStack(spacing: 4) {
                            Text("FMS")
                                .font(.largeTitle.bold())
                                .foregroundColor(.primary)
                            Text("Fleet Management Solution")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                                .tracking(2)
                        }
                    }
                    
                    // Irnput Fields
                    VStack(spacing: 20) {
                        LoginTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                        LoginSecureField(icon: "lock.fill", placeholder: "Password", text: $password)
                        
                        HStack {
                            Spacer()
                            Button("Forgot Password?") { }
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6).opacity(0.3))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    
                    // Login Button
                    Button(action: {
                        isLoggingIn = true
                        // Simulate network delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            isLoggingIn = false
                            if email.lowercased() == "fleet@fms.com" {
                                userRole = .manager
                            } else if email.lowercased().contains("driver") {
                                userRole = .driver
                            } else if email.lowercased().contains("maintenance") {
                                userRole = .maintenance
                            } else {
                                // Default to maintenance if not specified, 
                                // but ideally we'd show an error. Let's just default to driver for now
                                userRole = .driver
                            }
                        }
                    }) {
                        HStack {
                            if isLoggingIn {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.headline.bold())
                                Image(systemName: "arrow.right")
                                    .font(.subheadline.bold())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .disabled(isLoggingIn || email.isEmpty || password.isEmpty)
                    
                    Spacer()
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
                .foregroundColor(.secondary)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
                .autocapitalization(.none)
        }
        .padding()
        .background(AppColors.primary.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.primary.opacity(0.15), lineWidth: 1)
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
                .foregroundColor(.secondary)
                .frame(width: 20)
            SecureField(placeholder, text: $text)
                .foregroundColor(.primary)
        }
        .padding()
        .background(AppColors.primary.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.primary.opacity(0.15), lineWidth: 1)
        )
    }
}
