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
            } else {
                MaintenanceUserAuthenticationView(isLoggedIn: $isAuthenticated)
            }
        }
    }
}
