//
//  ContentView.swift
//  FMS Frontend
//
//  Created by Anshul Kumaria on 16/04/26.
//

import SwiftUI

enum AppUserRole {
    case none
    case driver
    case maintenance
    case manager
}

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var userRole: AppUserRole = .none
    @Published private(set) var isRestoringSession = true

    private let authAPI: AuthAPI
    private var didRestoreSession = false

    init(authAPI: AuthAPI = .shared) {
        self.authAPI = authAPI
    }

    func restoreSessionIfNeeded() async {
        guard !didRestoreSession else { return }
        didRestoreSession = true

        defer {
            isRestoringSession = false
        }

        guard APIClient.shared.currentToken() != nil else {
            userRole = .none
            return
        }

        do {
            let profile = try await authAPI.getProfile().profile
            userRole = AppUserRole(profile.role)
        } catch {
            authAPI.logout()
            userRole = .none
        }
    }

    func setAuthenticated(role: AppUserRole) {
        userRole = role
    }

    func logout() {
        authAPI.logout()
        userRole = .none
    }
}

private extension AppUserRole {
    init(_ role: UserRole) {
        switch role {
        case .driver:
            self = .driver
        case .maintenance:
            self = .maintenance
        case .manager, .superAdmin:
            self = .manager
        }
    }
}

struct ContentView: View {
    @StateObject private var session = SessionManager()

    var body: some View {
        Group {
            if session.isRestoringSession {
                ProgressView("Restoring session...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if session.userRole == .none {
                LoginView(userRole: Binding(
                    get: { session.userRole },
                    set: { newRole in
                        if newRole == .none {
                            session.logout()
                        } else {
                            session.setAuthenticated(role: newRole)
                        }
                    }
                ))
            } else if session.userRole == .driver {
                DashboardView(userRole: Binding(
                    get: { session.userRole },
                    set: { newRole in
                        if newRole == .none {
                            session.logout()
                        } else {
                            session.setAuthenticated(role: newRole)
                        }
                    }
                ))
            } else if session.userRole == .maintenance {
                MaintenanceTabView(isLoggedIn: Binding(
                    get: { session.userRole == .maintenance },
                    set: { isLoggedIn in
                        if !isLoggedIn {
                            session.logout()
                        }
                    }
                ))
            } else if session.userRole == .manager {
                FleetManagerMainView()
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
