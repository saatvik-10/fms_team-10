import Foundation

struct MockDataProvider {
    // ... previous dashboard stats ...
    static let dashboardStats = FleetManagerDashboardStats(
        totalShipments: 172,
        totalShipmentsTrend: "+1,92%",
        pendingPackages: 42,
        pendingPackagesTrend: "+1,89%",
        deliveryShipments: 16,
        deliveryShipmentsTrend: "-0,98%"
    )
    
    static let shipments: [ShipmentActivity] = [
        ShipmentActivity(orderID: "#172899-72-727bjk", category: "Electronic", company: "Exetron Co.", arrivalTime: "24 Dec 2023", route: "London - Prague", price: "$5,872.90", status: .delivered),
        ShipmentActivity(orderID: "#172899-72-727bjk", category: "Electronic", company: "Exetron Co.", arrivalTime: "24 Dec 2023", route: "London - Prague", price: "$5,872.90", status: .inTransit),
        ShipmentActivity(orderID: "#172899-72-727bjk", category: "Electronic", company: "Exetron Co.", arrivalTime: "24 Dec 2023", route: "London - Prague", price: "$5,872.90", status: .pending),
        ShipmentActivity(orderID: "#172899-72-727bjk", category: "Electronic", company: "Exetron Co.", arrivalTime: "24 Dec 2023", route: "London - Prague", price: "$5,872.90", status: .processing)
    ]
    
    static let fleetStatus = FleetVehicleStatus(
        active: 142,
        activeTrend: "+4%",
        maintenance: 14,
        idle: 08,
        critical: 02
    )
    
    static let assessments: [SmartFleetAssessment] = [
        SmartFleetAssessment(truckName: "Freightliner Cascadia", truckID: "ID: FL-2023-88", routeFrom: "Seattle", routeTo: "Portland", etaTime: "14:30", etaDay: "Today", status: .inTransit, imageName: "truck_cascadia"),
        SmartFleetAssessment(truckName: "Volvo VNL 860", truckID: "ID: VL-2022-12", routeFrom: "LA", routeTo: "Phoenix", etaTime: "Delayed", etaDay: "", status: .alertReceived, imageName: "truck_volvo"),
        SmartFleetAssessment(truckName: "Kenworth T680", truckID: "ID: KW-2023-45", routeFrom: "Dallas", routeTo: "Austin", etaTime: "16:45", etaDay: "Today", status: .restStop, imageName: "truck_kenworth"),
        SmartFleetAssessment(truckName: "Peterbilt 579", truckID: "ID: PB-2024-03", routeFrom: "Chicago", routeTo: "Detroit", etaTime: "09:00", etaDay: "Tomorrow", status: .scheduled, imageName: "truck_peterbilt")
    ]
    
    static let maintenanceAlerts: [MaintenanceAlert] = [
        MaintenanceAlert(title: "Insurance Renewal", detail: "Overdue • Policy #XX-990 • Action Required", iconName: "exclamationmark.triangle.fill", status: "Urgent"),
        MaintenanceAlert(title: "Compliance Audit", detail: "Due in 4 days • Regional Hub Compliance Unit", iconName: "doc.text.fill", status: "Scheduled")
    ]
    
    static let emissionData: [EmissionData] = [
        EmissionData(day: "MON", value: 10.5, isCurrent: false),
        EmissionData(day: "TUE", value: 12.0, isCurrent: false),
        EmissionData(day: "WED", value: 15.0, isCurrent: false),
        EmissionData(day: "THU", value: 18.2, isCurrent: true),
        EmissionData(day: "FRI", value: 14.5, isCurrent: false),
        EmissionData(day: "SAT", value: 8.0, isCurrent: false),
        EmissionData(day: "SUN", value: 9.5, isCurrent: false)
    ]

    // MARK: - Drivers Dataset (from Image 1 & 3)
    static let drivers: [Driver] = [
        Driver(id: "KM-1029", name: "Marcus Thorne", title: "Class A CDL Expert", licenseNum: "DL-99203381", licenseExp: "Oct 2026", status: .active, rating: 4.92, efficiency: "98.4%", totalTrips: 1240, totalHours: 8420, activityLog: mockActivityLog),
        Driver(id: "KM-1044", name: "Elena Rodriguez", title: "Heavy Haul Specialist", licenseNum: "DL-44810293", licenseExp: "Mar 2025", status: .onTrip, rating: 4.88, efficiency: "95.2%", totalTrips: 890, totalHours: 6200, activityLog: []),
        Driver(id: "KM-1011", name: "Julian Vane", title: "Regional Dispatcher", licenseNum: "DL-88293310", licenseExp: "Jan 2027", status: .offDuty, rating: 4.95, efficiency: "99.1%", totalTrips: 1560, totalHours: 9800, activityLog: []),
        Driver(id: "KM-1052", name: "Sarah Jenkins", title: "Long Haul Driver", licenseNum: "DL-11029384", licenseExp: "Aug 2025", status: .active, rating: 4.76, efficiency: "94.8%", totalTrips: 720, totalHours: 5100, activityLog: []),
        Driver(id: "KM-1008", name: "Tobias Kraft", title: "Safety Protocol Lead", licenseNum: "DL-77382291", licenseExp: "Dec 2024", status: .onTrip, rating: 4.99, efficiency: "99.9%", totalTrips: 2100, totalHours: 12400, activityLog: [])
    ]
    
    static let mockActivityLog: [ActivityEvent] = [
        ActivityEvent(title: "Cargo Delivery Completed", detail: "Drop-off: Warehouse B-12", time: "2h ago", type: "completed", value: "+$240.00"),
        ActivityEvent(title: "Refueling Stopped", detail: "Shell Express #429", time: "5h ago", type: "refueling", value: "14.2 gal"),
        ActivityEvent(title: "Shift Started", detail: "Main Depot", time: "8h ago", type: "started", value: "SYSTEM"),
        ActivityEvent(title: "Hard Braking Incident", detail: "Route A-1", time: "Yesterday", type: "incident", value: "FLAGGED")
    ]

    // MARK: - Vehicles Dataset (from Image 2)
    static let vehicles: [Vehicle] = [
        Vehicle(id: "VX-7702", make: "Mercedes Actros", model: "Heavy Hauler", type: "Truck", status: .inTransit, imageName: "truck_actros"),
        Vehicle(id: "VN-4209", make: "Ford Transit", model: "Last Mile", type: "Van", status: .idle, imageName: "van_ford"),
        Vehicle(id: "EV-9910", make: "Rivian EDV", model: "Electric Unit", type: "EV", status: .maintenance, imageName: "van_rivian"),
        Vehicle(id: "VX-8812", make: "Volvo FH16", model: "Refrigerated", type: "Truck", status: .inTransit, imageName: "truck_volvo_fh"),
        Vehicle(id: "VX-1104", make: "Kenworth T680", model: "Flatbed", type: "Truck", status: .inTransit, imageName: "truck_kenworth_t680"),
        Vehicle(id: "VN-2200", make: "Mercedes Sprinter", model: "Sprinter", type: "Van", status: .idle, imageName: "van_sprinter")
    ]
}
