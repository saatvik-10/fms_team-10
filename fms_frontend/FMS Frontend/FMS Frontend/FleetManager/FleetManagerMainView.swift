import SwiftUI

struct FleetManagerMainView: View {
    @StateObject private var dataManager = FleetDataManager()
    @State private var selectedTab: Int = 0
    
    init() {
        // Custom styling for the TabBar to match premium look
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        
        // Remove standard separator
        appearance.shadowColor = .clear
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                FleetManagerDashboardView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            .tag(0)
            
            NavigationView {
                FleetManagerVehiclesListView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Vehicles", systemImage: "truck.box.fill")
            }
            .tag(1)
            
            NavigationView {
                FleetManagerDriversListView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Drivers", systemImage: "person.2.fill")
            }
            .tag(2)
            
        }
        .accentColor(AppColors.primary)
        .environmentObject(dataManager)
    }
}

struct FleetManagerMainView_Previews: PreviewProvider {
    static var previews: some View {
        FleetManagerMainView()
            .previewInterfaceOrientation(.landscapeLeft) // Optimized for iPad
    }
}
