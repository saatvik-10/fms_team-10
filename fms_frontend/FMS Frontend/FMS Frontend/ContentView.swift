//
//  ContentView.swift
//  FMS Frontend
//
//  Created by Anshul Kumaria on 16/04/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var session = SessionManager()

    var body: some View {
        Group {
            // MARK: - DEV BYPASS
            // Directly showing FleetManagerMainView to skip login for development.
            FleetManagerMainView()
            
            /*
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
            */
        }
        .task {
            // We still run session restoration in background, but the UI is bypassed
            await session.restoreSessionIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}
