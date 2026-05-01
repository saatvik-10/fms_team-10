//
//  DriverEmailStore.swift
//  Created by Monica Rokade
//

import Foundation

/// Temporary storage for driver emails until backend integration
class DriverEmailStore {
    static let shared = DriverEmailStore()
    
    private var emails: [String: String] = [:] // DriverID: Email
    
    private init() {}
    
    func saveEmail(_ email: String, forDriverID id: String) {
        emails[id] = email
        print("[DEBUG] [DEBUG] DEBUG: Saved email \(email) for driver \(id)")
    }
    
    func getEmail(forDriverID id: String) -> String? {
        return emails[id]
    }
}
