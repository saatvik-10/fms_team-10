//
//  FMS_FrontendApp.swift
//  FMS Frontend
//
//  Created by Anshul Kumaria on 16/04/26.
//

import SwiftUI
import GoogleMaps

@main
struct Frontend: App {
    
    init() {
          GMSServices.provideAPIKey("AIzaSyBB3dlvvPvm-HPrUjHtSondvWgEJ_l3FbM")
      }
    
    var body: some Scene {
        WindowGroup {
           DashboardView()
        }
    }
}
