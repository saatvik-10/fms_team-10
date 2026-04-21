//
//  ContentView.swift
//  FMS Frontend
//
//  Created by Anshul Kumaria on 16/04/26.
//

import SwiftUI

enum UserRole {
    case none
    case driver
    case maintenance
    case manager
}

struct ContentView: View {
    @State private var userRole: UserRole = .none

    var body: some View {
        if userRole == .none {
            LoginView(userRole: $userRole)
        } else if userRole == .driver {
            DashboardView(userRole: $userRole)
        } else if userRole == .maintenance {
            MaintenanceTabView(isLoggedIn: Binding(
                get: { userRole == .maintenance },
                set: { if !$0 { userRole = .none } }
            ))
        } else if userRole == .manager {
            FleetManagerMainView()
        }
    }
}

#Preview {
    ContentView()
}
