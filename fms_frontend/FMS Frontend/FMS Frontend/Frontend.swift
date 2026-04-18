//
//  FMS_FrontendApp.swift
//  FMS Frontend
//
//  Created by Anshul Kumaria on 16/04/26.
//

import SwiftUI

@main
struct Frontend: App {
    @State private var isAuthenticated = false
    
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                MaintenanceTabView(isLoggedIn: $isAuthenticated)
                    .environmentObject(MaintenanceStore())
            } else {
                LoginView(isLoggedIn: $isAuthenticated)
            }
        }
    }
}

// Simple preference key to communicate auth status back to root
struct AuthKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}
