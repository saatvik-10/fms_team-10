//
//  LoginView.swift
//  FMS Frontend
//

import SwiftUI

struct LoginView: View {
    @Binding var userRole: UserRole
    
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var showPassword = false
    @State private var animateLogo = false
    @State private var navigateTo2FA = false
    
    @FocusState private var focusedField: Field?
    enum Field {
        case username, password
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Image - Full visibility
                Image("login_bg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                
                // Very light overshadow for readability
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                
                LoginGridView()
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Main Content Card
                    VStack(spacing: 0) {
                        // Logo Section
                        VStack(spacing: 12) {
                            ZStack(alignment: .leading) {
                                Text("FLEETRO")
                                    .font(.system(size: 36, weight: .black))
                                    .tracking(8)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                                    .mask(
                                        HStack(spacing: 0) {
                                            Rectangle()
                                                .frame(width: animateLogo ? 250 : 0)
                                            Spacer()
                                        }
                                    )
                                
                                Image(systemName: "car.side.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.white.opacity(0.8))
                                    .scaleEffect(x: -1, y: 1)
                                    .offset(x: animateLogo ? 235 : -15)
                                    .opacity(animateLogo ? 1 : 0)
                            }
                        }
                        .padding(.top, 20)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 3.5).delay(0.2)) {
                                animateLogo = true
                            }
                        }
                        
                        Spacer().frame(height: 50)
                        
                        // Input Fields
                        VStack(spacing: 20) {
                            // Username Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                
                                TextField("", text: $username, prompt: Text("Enter your username").foregroundColor(.white.opacity(0.4)))
                                    .focused($focusedField, equals: .username)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(18)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == .username ? Color.white.opacity(0.6) : Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .autocapitalization(.none)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                
                                HStack {
                                    if showPassword {
                                        TextField("", text: $password, prompt: Text("Enter your password").foregroundColor(.white.opacity(0.4)))
                                    } else {
                                        SecureField("", text: $password, prompt: Text("Enter your password").foregroundColor(.white.opacity(0.4)))
                                    }
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .focused($focusedField, equals: .password)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(18)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .password ? Color.white.opacity(0.6) : Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        
                        Spacer().frame(height: 35)
                        
                        // Sign In Button
                        Button(action: {
                            isLoggingIn = true
                            saveCredentials()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                isLoggingIn = false
                                let lowerUser = username.lowercased()
                                if lowerUser == "fleet@fms.com" || lowerUser == "admin" {
                                    userRole = .manager
                                } else if lowerUser.contains("driver") {
                                    userRole = .driver
                                } else if lowerUser.contains("maintenance") {
                                    userRole = .maintenance
                                } else {
                                    userRole = .driver
                                }
                                navigateTo2FA = true
                            }
                        }) {
                            ZStack {
                                if isLoggingIn {
                                    ProgressView().tint(AppColors.primary)
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.white)
                            .foregroundColor(AppColors.primary)
                            .cornerRadius(12)
                            .shadow(color: Color.white.opacity(0.2), radius: 10, y: 5)
                        }
                        .disabled(isLoggingIn || username.isEmpty || password.isEmpty)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 30)
                    .frame(maxWidth: 500) // Constraint for iPad
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.white.opacity(0.2))
                    )
                    .cornerRadius(32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 15)
                    .padding(.horizontal, 30) // Screen padding
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $navigateTo2FA) {
                TwoFactorView(userRole: $userRole)
            }
            .onTapGesture {
                focusedField = nil
            }
        }
    }
    
    private func saveCredentials() {
        let data = "Username: \(username)\nPassword: \(password)\nTimestamp: \(Date())\n\n"
        let filename = getDocumentsDirectory().appendingPathComponent("login_data.txt")
        try? data.write(to: filename, atomically: true, encoding: .utf8)
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

#Preview {
    LoginView(userRole: .constant(.none))
}
