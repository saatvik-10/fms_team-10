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
    private(set) var managerProfile: ManagerProfileData?
    
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
    
    func logout() {
        authAPI.logout()
        managerProfile = nil
        state = .unauthenticated
    }
}

struct ContentView: View {
    @StateObject private var session = AppSessionStore()
    
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
        Group {
            //            // ── LOGIN BYPASS (comment out to re-enable login) ──────────────
            //            FleetManagerMainView()
            //            // ── END BYPASS ─────────────────────────────────────────────────
            
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
    }
}

#Preview {
    ContentView()
}
