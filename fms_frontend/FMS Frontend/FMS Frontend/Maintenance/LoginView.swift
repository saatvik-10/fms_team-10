//
//  LoginView.swift
//  FMS Frontend
//

import SwiftUI

struct LoginView: View {
    @Binding var userRole: AppUserRole
    
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var showPassword = false
    @State private var animateLogo = false
    @State private var navigateTo2FA = false
    @State private var loginError: String?
    @State private var pendingEmail = ""
    @State private var pendingRole: AppUserRole = .none
    @State private var logoWidth: CGFloat = 0
    
    @FocusState private var focusedField: Field?
    enum Field {
        case username, password
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundSection
                
                VStack {
                    Spacer()
                    
                    // Main Content Card
                    VStack(spacing: 0) {
                        logoSection
                        
                        // Internal Spacing
                        Color.clear.frame(height: 40)
                        
                        inputFieldsSection

                        if let loginError {
                            errorSection(loginError)
                        }
                        
                        Color.clear.frame(height: 32)
                        
                        actionButtonSection
                    }
                    .padding(32)
                    .frame(maxWidth: 400) // Fixed max width for consistent card look
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.white.opacity(0.15))
                            .background(
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(Color.black.opacity(0.2))
                                    .blur(radius: 10)
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 40, x: 0, y: 20)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationDestination(isPresented: $navigateTo2FA) {
                TwoFactorView(
                    userRole: $userRole,
                    otpEmail: pendingEmail,
                    roleToSet: pendingRole
                )
            }
            .onTapGesture {
                focusedField = nil
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var backgroundSection: some View {
        ZStack {
            Image("login_bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            LoginGridView()
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var logoSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .leading) {
                Text("FLEETRO")
                    .font(.system(size: 28, weight: .black))
                    .tracking(6)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { logoWidth = geo.size.width }
                                .onChange(of: geo.size.width) { logoWidth = $1 }
                        }
                    )
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: animateLogo ? (logoWidth > 0 ? logoWidth : 200) : 0)
                            Spacer(minLength: 0)
                        }
                    )
                
                Image(systemName: "car.side.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.9))
                    .scaleEffect(x: -1, y: 1)
                    .offset(x: animateLogo ? (logoWidth > 0 ? logoWidth + 5 : 190) : -30)
                    .opacity(animateLogo ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).delay(0.3)) {
                animateLogo = true
            }
        }
    }

    @ViewBuilder
    private var inputFieldsSection: some View {
        VStack(spacing: 24) {
            // Username Field
            VStack(alignment: .leading, spacing: 10) {
                Text("Username")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.leading, 4)
                
                TextField("", text: $username, prompt: Text("Enter your username").foregroundColor(.white.opacity(0.35)))
                    .focused($focusedField, equals: .username)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(18)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(focusedField == .username ? Color.white.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .autocapitalization(.none)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 10) {
                Text("Password")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.leading, 4)
                
                HStack {
                    if showPassword {
                        TextField("", text: $password, prompt: Text("Enter your password").foregroundColor(.white.opacity(0.35)))
                    } else {
                        SecureField("", text: $password, prompt: Text("Enter your password").foregroundColor(.white.opacity(0.35)))
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .focused($focusedField, equals: .password)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(18)
                .background(Color.white.opacity(0.12))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(focusedField == .password ? Color.white.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private func errorSection(_ error: String) -> some View {
        Text(error)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.red.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.top, 12)
    }

    @ViewBuilder
    private var actionButtonSection: some View {
        Button(action: {
            Task {
                await signInAndSendOTP()
            }
        }) {
            ZStack {
                if isLoggingIn {
                    ProgressView().tint(AppColors.primary)
                } else {
                    Text("Sign In")
                        .font(.system(size: 17, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Color.white)
            .foregroundColor(AppColors.primary)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
        }
        .disabled(isLoggingIn || username.isEmpty || password.isEmpty)
        .opacity(isLoggingIn || username.isEmpty || password.isEmpty ? 0.7 : 1.0)
    }

    @MainActor
    private func signInAndSendOTP() async {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty, !trimmedPassword.isEmpty else {
            loginError = "Please enter both username and password."
            return
        }

        isLoggingIn = true
        loginError = nil

        defer {
            isLoggingIn = false
        }

        do {
            let response = try await AuthAPI.shared.userSignin(username: trimmedUsername, password: trimmedPassword)
            guard let email = response.user.email, !email.isEmpty else {
                loginError = "No email found for this account."
                return
            }

            let mappedRole = mapBackendRole(response.user.role.rawValue)
            guard mappedRole != .none else {
                loginError = "Unsupported user role."
                return
            }

            pendingEmail = email
            pendingRole = mappedRole
            navigateTo2FA = true
        } catch {
            loginError = error.localizedDescription
        }
    }

    private func mapBackendRole(_ role: String) -> AppUserRole {
        switch role {
        case "MANAGER":
            return .manager
        case "DRIVER":
            return .driver
        case "MAINTENANCE":
            return .maintenance
        default:
            return .none
        }
    }
}

#Preview {
    LoginView(userRole: .constant(.none))
}
