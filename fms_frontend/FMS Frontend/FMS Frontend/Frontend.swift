//
//  FMS_FrontendApp.swift
//  FMS Frontend
//
//  Created by Anshul Kumaria on 16/04/26.
//

import SwiftUI

@main
struct Frontend: App {
    @StateObject private var maintenanceStore = MaintenanceStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(maintenanceStore)
        }
    }
}
