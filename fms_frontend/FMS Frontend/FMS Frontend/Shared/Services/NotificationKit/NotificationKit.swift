
//
//  NotificationKit.swift
//  FMS Chat — Notification Framework
//
//  ✅ DRAG THIS FILE into your main project's NotificationKit module if needed.
//

import Foundation
import UserNotifications
import SwiftUI

public final class NotificationKit {
    public static let shared = NotificationKit()
    
    private init() {}
    
    /// Request permissions for local notifications
    public func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("NotificationKit: Permissions granted")
            } else if let error = error {
                print("NotificationKit: Error - \(error.localizedDescription)")
            }
        }
    }
    
    /// Post a local notification (Simulation for real-world push)
    public func postNotification(title: String, subtitle: String, body: String, userInfo: [AnyHashable: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        // Trigger immediately (simulation)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("NotificationKit: Failed to add notification - \(error.localizedDescription)")
            }
        }
        
        // Also post internal notification for the in-app banner
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("FMS_InternalNotification"), object: nil, userInfo: [
                "title": title,
                "body": body,
                "senderName": title,
                "content": body
            ])
        }
    }
}
