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
          GMSServices.provideAPIKey("AIzaSyDlMQm7FBZik7fIYAI6RdY21HmCpMjn5yM")
      }
    
    var body: some Scene {
        WindowGroup {
           DashboardView()
        }
    }
}
