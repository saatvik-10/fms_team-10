//
//  MaintenanceUserAuthenticationViewModel.swift
//  FMS Frontend
//

import SwiftUI
import Combine

class MaintenanceUserAuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoggingIn = false
    @Published var isAuthenticated = false
    @Published var loginError: String?
    
    func login() {
        guard !email.isEmpty && !password.isEmpty else {
            loginError = "Please enter both email and password."
            return
        }
        
        isLoggingIn = true
        loginError = nil
        
        // Simulate authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoggingIn = false
            // For demo purposes, any non-empty input works
            self.isAuthenticated = true
        }
    }
    
    func resetPassword() {
        print("Password reset requested for: \(email)")
    }
}
