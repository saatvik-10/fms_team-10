//
//  ContentView.swift
//  FMS Frontend
//
//  Created by Anshul Kumaria on 16/04/26.
//

import SwiftUI
import Combine

@MainActor
final class AppSessionStore: ObservableObject {
    enum State: Equatable {
        case restoring
        case unauthenticated
        case authenticated(AppUserRole)
    }
    
    @Published var currentRoleValue: AppUserRole = .none
    @Published private(set) var state: State = .restoring
    @Published private(set) var managerProfile: ManagerProfileData?
    @Published private(set) var userProfile: UserProfile?
    
    private let authAPI: AuthAPI
    private var didRestoreSession = false
    
    init(authAPI: AuthAPI = .shared) {
        self.authAPI = authAPI
    }
    
    var currentRole: AppUserRole {
        if case let .authenticated(role) = state {
            return role
        }
        return .none
    }
    
    var currentRoleBinding: Binding<AppUserRole> {
        Binding(
            get: { self.currentRole },
            set: { newRole in
                if newRole == .none {
                    self.logout()
                } else {
                    self.setAuthenticated(role: newRole)
                }
            }
        )
    }
    
    func restoreSessionIfNeeded() async {
        guard !didRestoreSession else { return }
        didRestoreSession = true
        await fetchProfile()
    }
    
    func fetchProfile() async {
        print("🟡 Checking for token...")
        
        guard let token = authAPI.getCurrentToken(), !token.isEmpty else {
            print("🔴 No token found — going to login")
            state = .unauthenticated
            return
        }
        
        print("🟢 Token found:", token)
        
        do {
            let profileResponse = try await authAPI.getProfile()
            let profile = profileResponse.profile
            print("🟢 Profile fetched — role:", profile.role)
            
            if profile.role == .manager || profile.role == .superAdmin {
                managerProfile = ManagerProfileData(
                    id: profile.id,
                    name: profile.name ?? "Manager",
                    email: profile.email,
                    phone: profile.phone,
                    address: profile.address,
                    username: profile.username ?? "",
                    role: profile.role.rawValue
                )
            }
            
            // Store the full profile for any authenticated user
            userProfile = profile
            
            state = .authenticated(AppUserRole(profile.role))
        } catch {
            print("🔴 Session restore failed:", error)
            authAPI.logout()
            state = .unauthenticated
        }
    }
    
    func setAuthenticated(role: AppUserRole) {
        guard role != .none else {
            logout()
            return
        }
        state = .authenticated(role)
    }
    
    func debugLogin(as role: AppUserRole) {
        switch role {
        case .manager:
            userProfile = UserProfile.mockManager
            managerProfile = ManagerProfileData(
                id: UserProfile.mockManager.id,
                name: UserProfile.mockManager.name,
                email: UserProfile.mockManager.email,
                phone: UserProfile.mockManager.phone,
                address: UserProfile.mockManager.address,
                username: UserProfile.mockManager.username,
                role: "MANAGER"
            )
        case .driver:
            userProfile = UserProfile.mockDriver
        case .maintenance:
            userProfile = UserProfile.mockMaintenance
        case .none:
            logout()
            return
        }
        // Set a dummy token to satisfy any token checks
        TokenStore.shared.save(token: "mock_token_\(role)")
        state = .authenticated(role)
    }
    
    func logout() {
        authAPI.logout()
        managerProfile = nil
        userProfile = nil
        state = .unauthenticated
    }
}

struct ContentView: View {
    @StateObject private var session = AppSessionStore()
    
    // --- CHAT INTEGRATION ---
    @StateObject var chatViewModel = ChatViewModel()
    @State private var showNotification = false
    @State private var latestNotificationData: (title: String, body: String)?
    // ------------------------
    
    private var userRoleBinding: Binding<AppUserRole> {
        Binding(
            get: { session.currentRole },
            set: { role in
                if role == .none {
                    session.logout()
                } else {
                    session.setAuthenticated(role: role)
                }
            }
        )
    }
    
    private var maintenanceLoggedInBinding: Binding<Bool> {
        Binding(
            get: { session.currentRole == .maintenance },
            set: { isLoggedIn in
                if !isLoggedIn {
                    session.logout()
                }
            }
        )
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch session.state {
                case .restoring:
                    ProgressView("Restoring session...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .unauthenticated:
                    LoginView(userRole: userRoleBinding, session: session)
                    
                case let .authenticated(role):
                    switch role {
                    case .driver:
                        DashboardView(userRole: userRoleBinding)
                            .environmentObject(session)
                    case .maintenance:
                        MaintenanceTabView(isLoggedIn: maintenanceLoggedInBinding)
                    case .manager:
                        FleetManagerMainView(profile: session.managerProfile)
                            .environmentObject(session)
                    case .none:
                        LoginView(userRole: userRoleBinding, session: session)
                    }
                }
            }
            .task {
                await session.restoreSessionIfNeeded()
            }
            .onChange(of: session.state) { newState in
                if case let .authenticated(role) = newState {
                    configureChat(role: role)
                }
            }
            .onChange(of: session.userProfile?.id) { _ in
                if case let .authenticated(role) = session.state {
                    configureChat(role: role)
                }
            }
            .onChange(of: session.managerProfile?.id) { _ in
                if case let .authenticated(role) = session.state {
                    configureChat(role: role)
                }
            }
            // --- CHAT MODIFIERS ---
            .environmentObject(chatViewModel)
            .onAppear {
                NotificationKit.shared.requestPermissions()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FMS_InternalNotification"))) { note in
                if let userInfo = note.userInfo,
                   let title = userInfo["title"] as? String,
                   let body = userInfo["body"] as? String,
                   let senderId = userInfo["senderId"] as? String {
                    
                    // Optional: Try to avoid self-notifying by checking senderId against current session ID.
                    let currentIdStr = session.userProfile?.id ?? session.managerProfile?.id ?? ""
                    if senderId != currentIdStr {
                        self.latestNotificationData = (title, body)
                        withAnimation { self.showNotification = true }
                        
                        // Auto-hide after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { self.showNotification = false }
                        }
                    }
                }
            }
            // ------------------------
            
            // --- NOTIFICATION BANNER OVERLAY ---
            if showNotification, let data = latestNotificationData {
                NotificationBanner(title: data.title, bodyText: data.body, isPresented: $showNotification)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100) // Ensure it sits on top of all tabs
            }
            // -----------------------------------
        }
    }
    
    private func configureChat(role: AppUserRole) {
        let userId: String
        let name: String
        
        if let profile = session.userProfile {
            userId = profile.id
            name = profile.name
        } else if let manager = session.managerProfile {
            userId = manager.id
            name = manager.name
        } else {
            return // Skip until profile is loaded
        }
        
        chatViewModel.configure(
            userId: userId,
            name: name,
            role: String(describing: role)
        )
    }
}

// MARK: - Notification Banner Component
struct NotificationBanner: View {
    let title: String
    let bodyText: String
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue) // Fallback color, change to AppColors.primary if you have it
                .frame(width: 40, height: 40)
                .overlay(
                    Text(title.prefix(1))
                        .foregroundColor(.white)
                        .bold()
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                Text(bodyText)
                    .font(.system(size: 13))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: { withAnimation { isPresented = false } }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

#Preview {
    ContentView()
}
