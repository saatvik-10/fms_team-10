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
    
    func restoreSessionIfNeeded() async {
        guard !didRestoreSession else { return }
        didRestoreSession = true
        
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
            if let existingToken = authAPI.getCurrentToken(), !existingToken.isEmpty {
                state = .authenticated(.manager)
            } else {
                authAPI.logout()
                state = .unauthenticated
            }
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
                LoginView(userRole: userRoleBinding)
                
            case let .authenticated(role):
                switch role {
                case .driver:
                    DashboardView(userRole: userRoleBinding)
                case .maintenance:
                    MaintenanceTabView(isLoggedIn: maintenanceLoggedInBinding)
                case .manager:
                    FleetManagerMainView(profile: session.managerProfile)
                case .none:
                    LoginView(userRole: userRoleBinding)
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
