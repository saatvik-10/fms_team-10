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
    @State private var showPassword = false
    @State private var animateLogo = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Grid
                LoginGridView()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo Section with Premium Left-to-Right Reveal Animation
                    VStack(spacing: 12) {
                        ZStack(alignment: .leading) {
                            // The revealed text
                            Text("FLEETRO")
                                .font(.system(size: 32, weight: .black))
                                .tracking(8)
                                .foregroundColor(.black)
                                .mask(
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .frame(width: animateLogo ? 250 : 0)
                                        Spacer()
                                    }
                                )
                            
                            // The driving truck icon (Independent Component)
                            Image(systemName: "car.side.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                                .scaleEffect(x: -1, y: 1) // Faces Right
                                .offset(x: animateLogo ? 215 : -15) // Starts at F, ends at O
                                .opacity(animateLogo ? 1 : 0)
                        }
                        .frame(width: 250, alignment: .leading)
                        .padding(.leading, 60) // Center adjustment
                        
                        Text("MANAGEMENT SUITE")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(4)
                            .foregroundColor(.gray)
                            .opacity(animateLogo ? 1 : 0)
                            .offset(y: animateLogo ? 0 : 5)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 3.5).delay(0.2)) {
                            animateLogo = true
                        }
                    }
                    
                    Spacer().frame(height: 80)
                    
                    // Input Fields
                    VStack(spacing: 16) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 0) {
                            TextField("Username", text: $email)
                                .font(.system(size: 16, weight: .medium))
                                .padding(20)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                )
                                .autocapitalization(.none)
                        }
                        
                        // Password Field
                        HStack {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .font(.system(size: 16))
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .padding(20)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer().frame(height: 30)
                    
                    // Sign In Button
                    Button(action: {
                        isLoggingIn = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            isLoggingIn = false
                            let lowerEmail = email.lowercased()
                            if lowerEmail == "fleet@fms.com" {
                                userRole = .manager
                            } else if lowerEmail.contains("driver") {
                                userRole = .driver
                            } else if lowerEmail.contains("maintenance") {
                                userRole = .maintenance
                            } else {
                                userRole = .driver
                            }
                        }
                    }) {
                        ZStack {
                            if isLoggingIn {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .disabled(isLoggingIn || email.isEmpty || password.isEmpty)
                    
                    Button("Forgot password?") { }
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Footer
                    HStack {
                        Rectangle().frame(height: 0.5).foregroundColor(.gray.opacity(0.2))
                        Text("FLEETRO SYSTEMS")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(3)
                            .foregroundColor(.gray.opacity(0.4))
                            .padding(.horizontal, 15)
                        Rectangle().frame(height: 0.5).foregroundColor(.gray.opacity(0.2))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

struct LoginGridView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let spacing: CGFloat = 40
                
                // Vertical lines
                for x in stride(from: 0, through: geo.size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                
                // Horizontal lines
                for y in stride(from: 0, through: geo.size.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.black.opacity(0.03), lineWidth: 1)
        }
    }
}
