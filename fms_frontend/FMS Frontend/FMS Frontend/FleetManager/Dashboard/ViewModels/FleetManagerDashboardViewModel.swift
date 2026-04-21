import Foundation
import Combine

class FleetManagerDashboardViewModel: ObservableObject {
    @Published var stats: FleetManagerDashboardStats = MockDataProvider.dashboardStats
    @Published var shipments: [ShipmentActivity] = MockDataProvider.shipments
    @Published var fleetStatus: FleetVehicleStatus = MockDataProvider.fleetStatus
    @Published var assessments: [SmartFleetAssessment] = MockDataProvider.assessments
    @Published var maintenanceAlerts: [FleetMaintenanceAlert] = MockDataProvider.maintenanceAlerts
    @Published var emissionData: [EmissionData] = MockDataProvider.emissionData
    
    @Published var selectedTimeframe: String = "Dec 2022"
    @Published var selectedFilter: String = "All Shipments"
    
    let timeframes = ["Dec 2022", "Nov 2022", "Oct 2022"]
    let filters = ["All Shipments", "Delivered", "In Transit", "Pending", "Processing"]
    
    func refreshData() {
        // In a real app, this would fetch from an API or file
        // For now, it re-loads from MockDataProvider
        self.stats = MockDataProvider.dashboardStats
        self.shipments = MockDataProvider.shipments
        self.fleetStatus = MockDataProvider.fleetStatus
        self.assessments = MockDataProvider.assessments
        self.maintenanceAlerts = MockDataProvider.maintenanceAlerts
        self.emissionData = MockDataProvider.emissionData
    }
}
