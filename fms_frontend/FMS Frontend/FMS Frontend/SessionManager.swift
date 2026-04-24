import SwiftUI
import Combine

enum AppUserRole: Equatable {
    case none
    case driver
    case maintenance
    case manager
}

final class SessionManager: ObservableObject {
    @Published private(set) var userRole: AppUserRole = .none
    @Published private(set) var isRestoringSession = true

    private let authAPI: AuthAPI
    private var didRestoreSession = false

    init(authAPI: AuthAPI = .shared) {
        self.authAPI = authAPI
    }

    @MainActor
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

extension AppUserRole {
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
